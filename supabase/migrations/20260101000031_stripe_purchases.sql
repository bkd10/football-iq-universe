-- Achats de Ballons avec Stripe.
--
-- Le prix et le nombre de Ballons de chaque pack sont fixés ICI, côté
-- serveur : l'appli ne peut pas choisir son prix. Parcours :
--   1. l'appli appelle la fonction Edge `create-checkout` ;
--   2. celle-ci appelle `prepare_purchase` (contrôles : âge, accord
--      parental, plafond des mineurs) puis ouvre une page de paiement
--      Stripe ;
--   3. Stripe prévient la fonction Edge `stripe-webhook` (signature
--      vérifiée), qui appelle `complete_purchase` : les Ballons sont
--      crédités une seule fois, comptés comme « achetés » (jamais
--      misables, voir `20260101000030_no_gambling.sql`).

create schema if not exists private;

create table if not exists coin_packs (
  id text primary key,
  coins integer not null check (coins > 0),
  price_cents integer not null check (price_cents > 0),
  currency text not null default 'eur',
  bonus_label text,
  sort_order integer not null default 0,
  active boolean not null default true
);

insert into coin_packs (id, coins, price_cents, bonus_label, sort_order) values
  ('pack_100', 100, 99, null, 1),
  ('pack_550', 550, 499, '+10%', 2),
  ('pack_1200', 1200, 999, '+20%', 3),
  ('pack_2500', 2500, 1999, '+25%', 4)
on conflict (id) do nothing;

alter table coin_packs enable row level security;
drop policy if exists "Packs visibles" on coin_packs;
create policy "Packs visibles" on coin_packs for select using (active);
revoke all on coin_packs from anon, authenticated;
grant select on coin_packs to anon, authenticated;

create table if not exists purchases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles (id) on delete set null,
  pack_id text not null references coin_packs (id),
  coins integer not null,
  amount_cents integer not null,
  currency text not null,
  status text not null default 'pending'
    check (status in ('pending', 'paid', 'refunded', 'expired')),
  stripe_session_id text unique,
  stripe_payment_intent text,
  created_at timestamptz not null default now(),
  paid_at timestamptz,
  refunded_at timestamptz
);

create index if not exists idx_purchases_user_created on purchases (user_id, created_at desc);

alter table purchases enable row level security;
drop policy if exists "Users read their own purchases" on purchases;
create policy "Users read their own purchases" on purchases for select using (auth.uid() = user_id);
revoke all on purchases from anon, authenticated;
grant select on purchases to authenticated;

-- Plafond d'achat d'un mineur sur 30 jours glissants (en centimes).
update app_config
set value = value || '{"minor_monthly_limit_cents": 5000}'::jsonb
where key = 'legal' and not (value ? 'minor_monthly_limit_cents');

-- Contrôles avant paiement + création de l'achat « en attente ».
create or replace function prepare_purchase(p_pack_id text)
returns table (purchase_id uuid, coins integer, amount_cents integer, currency text, email text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_pack coin_packs;
  v_birth date;
  v_banned boolean;
  v_spent integer;
  v_limit integer;
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'Connexion requise.' using errcode = '42501';
  end if;
  select * into v_pack from coin_packs where id = p_pack_id and active;
  if v_pack.id is null then
    raise exception 'Pack introuvable.' using errcode = 'P0001';
  end if;
  select p.birth_date, coalesce(p.is_banned, false) into v_birth, v_banned
  from profiles p where p.id = v_uid;
  if v_banned then
    raise exception 'Compte suspendu.' using errcode = 'P0001';
  end if;
  if v_birth is null then
    raise exception 'Indique ta date de naissance avant d''acheter des Ballons.' using errcode = 'P0001';
  end if;
  if not private.can_purchase(v_uid) then
    raise exception 'Achat impossible sans l''accord de tes parents.' using errcode = 'P0001';
  end if;
  if v_birth > (current_date - interval '18 years') then
    v_limit := private.legal_setting('minor_monthly_limit_cents', 5000);
    select coalesce(sum(pu.amount_cents), 0) into v_spent
    from purchases pu
    where pu.user_id = v_uid and pu.status = 'paid' and pu.paid_at > now() - interval '30 days';
    if v_spent + v_pack.price_cents > v_limit then
      raise exception 'Limite d''achat des mineurs atteinte (% € sur 30 jours).', v_limit / 100
        using errcode = 'P0001';
    end if;
  end if;

  -- Un seul achat en attente à la fois par pack (double clic).
  delete from purchases
  where user_id = v_uid and status = 'pending' and stripe_session_id is null;

  insert into purchases (user_id, pack_id, coins, amount_cents, currency)
  values (v_uid, v_pack.id, v_pack.coins, v_pack.price_cents, v_pack.currency)
  returning id into v_id;

  return query
  select v_id, v_pack.coins, v_pack.price_cents, v_pack.currency,
         (select u.email::text from auth.users u where u.id = v_uid);
end;
$$;

revoke execute on function prepare_purchase(text) from public, anon;
grant execute on function prepare_purchase(text) to authenticated;

-- Réservé à la fonction Edge (clé serveur) : relie l'achat à la page Stripe.
create or replace function attach_checkout_session(p_purchase_id uuid, p_session_id text)
returns void
language sql
security definer
set search_path = public
as $$
  update purchases set stripe_session_id = p_session_id
  where id = p_purchase_id and status = 'pending' and stripe_session_id is null;
$$;

-- Réservé au webhook Stripe : crédite les Ballons une seule fois.
create or replace function complete_purchase(
  p_session_id text,
  p_amount_total integer,
  p_currency text,
  p_payment_intent text default null
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_p purchases;
  v_balance integer;
begin
  select * into v_p from purchases where stripe_session_id = p_session_id for update;
  if v_p.id is null then
    return 'unknown_session';
  end if;
  if v_p.status = 'paid' then
    return 'already_paid';
  end if;
  if v_p.status <> 'pending' then
    return 'not_pending';
  end if;
  if p_amount_total is distinct from v_p.amount_cents or lower(p_currency) is distinct from v_p.currency then
    raise exception 'Montant payé différent du prix du pack.' using errcode = 'P0001';
  end if;
  if v_p.user_id is null then
    update purchases set status = 'paid', paid_at = now(), stripe_payment_intent = p_payment_intent
    where id = v_p.id;
    return 'account_deleted';
  end if;

  update purchases set status = 'paid', paid_at = now(), stripe_payment_intent = p_payment_intent
  where id = v_p.id;

  update profiles set coins = coins + v_p.coins where id = v_p.user_id
  returning coins into v_balance;

  insert into transactions (user_id, type, amount, currency, balance_after, reason, reference_type, reference_id)
  values (v_p.user_id, 'purchase', v_p.coins, 'coins', v_balance, 'purchase_pack', 'purchase', v_p.id);

  return 'credited';
end;
$$;

-- Réservé au webhook : page de paiement abandonnée.
create or replace function expire_purchase(p_session_id text)
returns void
language sql
security definer
set search_path = public
as $$
  update purchases set status = 'expired'
  where stripe_session_id = p_session_id and status = 'pending';
$$;

-- Réservé au webhook : achat remboursé, les Ballons achetés sont retirés
-- (sans jamais passer le solde sous zéro).
create or replace function refund_purchase(p_payment_intent text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_p purchases;
  v_take integer;
  v_balance integer;
begin
  select * into v_p from purchases where stripe_payment_intent = p_payment_intent for update;
  if v_p.id is null or v_p.status <> 'paid' then
    return 'ignored';
  end if;
  update purchases set status = 'refunded', refunded_at = now() where id = v_p.id;
  if v_p.user_id is null then
    return 'account_deleted';
  end if;
  select least(v_p.coins, greatest(coins, 0)) into v_take from profiles where id = v_p.user_id for update;
  if v_take > 0 then
    update profiles set coins = coins - v_take where id = v_p.user_id returning coins into v_balance;
    insert into transactions (user_id, type, amount, currency, balance_after, reason, reference_type, reference_id)
    values (v_p.user_id, 'spend', -v_take, 'coins', v_balance, 'purchase_refunded', 'purchase', v_p.id);
  end if;
  return 'refunded';
end;
$$;

revoke execute on function attach_checkout_session(uuid, text) from public, anon, authenticated;
revoke execute on function complete_purchase(text, integer, text, text) from public, anon, authenticated;
revoke execute on function expire_purchase(text) from public, anon, authenticated;
revoke execute on function refund_purchase(text) from public, anon, authenticated;
grant execute on function attach_checkout_session(uuid, text) to service_role;
grant execute on function complete_purchase(text, integer, text, text) to service_role;
grant execute on function expire_purchase(text) to service_role;
grant execute on function refund_purchase(text) to service_role;
