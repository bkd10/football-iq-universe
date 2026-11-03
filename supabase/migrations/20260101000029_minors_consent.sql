-- Mineurs et conditions d'utilisation, vérifiés à l'inscription.
--
-- Règles (décision par défaut du 03/11/2026, modifiables dans
-- `app_config.legal`) :
--   - moins de 13 ans : inscription refusée ;
--   - 13 à 17 ans : le joueur atteste que ses parents (ou son tuteur légal)
--     l'autorisent et donne l'e-mail d'un parent ;
--   - comptes recruteur et marque : 18 ans minimum ;
--   - tout le monde accepte les CGU et la politique de confidentialité.
--
-- L'appli vérifie déjà tout ça avant d'envoyer le formulaire ; le serveur
-- refuse de toute façon un compte qui ne respecte pas les règles (un appel
-- direct à l'API ne passe pas). La preuve (date, version des CGU,
-- attestation, e-mail du parent) est gardée dans `account_consents`,
-- lisible par le seul titulaire du compte.

create schema if not exists private;

insert into app_config (key, value)
values ('legal', '{"min_age": 13, "parental_consent_under": 18, "pro_min_age": 18, "terms_version": "2026-11"}'::jsonb)
on conflict (key) do update set value = excluded.value || app_config.value;

create table if not exists account_consents (
  user_id uuid primary key references auth.users (id) on delete cascade,
  terms_version text not null,
  terms_accepted_at timestamptz not null default now(),
  is_minor boolean not null,
  parental_attestation boolean not null default false,
  guardian_email text,
  attested_at timestamptz,
  guardian_notified_at timestamptz
);

alter table account_consents enable row level security;

drop policy if exists "Users read their own consent" on account_consents;
create policy "Users read their own consent"
on account_consents for select
using (auth.uid() = user_id);

revoke all on account_consents from anon, authenticated;
grant select on account_consents to authenticated;

create or replace function private.legal_setting(p_key text, p_default integer)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select (value ->> p_key)::integer from app_config where key = 'legal'), p_default);
$$;

create or replace function private.terms_version()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select value ->> 'terms_version' from app_config where key = 'legal'), '2026-11');
$$;

-- Vérifie l'âge et l'accord parental ; lève une erreur lisible sinon.
-- Renvoie `true` si le titulaire est mineur.
create or replace function private.check_age_rules(
  p_birth_date date,
  p_role text,
  p_parental_attestation boolean,
  p_guardian_email text,
  p_own_email text
)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_age integer;
begin
  if p_birth_date is null then
    raise exception 'Date de naissance requise.' using errcode = 'P0001';
  end if;
  if p_birth_date > current_date then
    raise exception 'Date de naissance invalide.' using errcode = 'P0001';
  end if;
  v_age := extract(year from age(current_date, p_birth_date))::integer;
  if v_age > 120 then
    raise exception 'Date de naissance invalide.' using errcode = 'P0001';
  end if;
  if v_age < private.legal_setting('min_age', 13) then
    raise exception 'Il faut avoir au moins 13 ans pour s''inscrire.' using errcode = 'P0001';
  end if;
  if p_role in ('scout', 'brand') and v_age < private.legal_setting('pro_min_age', 18) then
    raise exception 'Les comptes recruteur et marque sont réservés aux majeurs.' using errcode = 'P0001';
  end if;
  if v_age < private.legal_setting('parental_consent_under', 18) then
    if not coalesce(p_parental_attestation, false)
       or p_guardian_email is null
       or p_guardian_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'
       or lower(p_guardian_email) = lower(coalesce(p_own_email, '')) then
      raise exception 'Accord parental requis : coche l''attestation et donne l''e-mail d''un parent.' using errcode = 'P0001';
    end if;
    return true;
  end if;
  return false;
end;
$$;

revoke execute on function private.legal_setting(text, integer) from public, anon, authenticated;
revoke execute on function private.terms_version() from public, anon, authenticated;
revoke execute on function private.check_age_rules(date, text, boolean, text, text) from public, anon, authenticated;

create or replace function handle_new_user()
returns trigger as $$
declare
  v_meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_role text := coalesce(v_meta ->> 'role', 'player');
  v_already_confirmed boolean := new.email_confirmed_at is not null;
  v_birth date := nullif(v_meta ->> 'birth_date', '')::date;
  v_guardian text := nullif(trim(v_meta ->> 'guardian_email'), '');
  v_attested boolean := coalesce((v_meta ->> 'parental_attestation')::boolean, false);
  v_is_minor boolean;
  v_initial_coins integer;
begin
  if v_role not in ('player', 'scout', 'brand') then
    v_role := 'player';
  end if;

  -- Inscription depuis l'appli (elle envoie toujours un pseudo) : âge,
  -- accord parental et CGU obligatoires. Un compte créé à la main par
  -- l'administrateur dans le tableau de bord Supabase n'a pas de pseudo :
  -- sa date de naissance reste inconnue, il est traité comme mineur
  -- (recruteurs, achats) jusqu'à ce qu'il la déclare.
  if v_meta ? 'username' then
    if coalesce((v_meta ->> 'terms_accepted')::boolean, false) is not true then
      raise exception 'Il faut accepter les conditions d''utilisation.' using errcode = 'P0001';
    end if;
    v_is_minor := private.check_age_rules(v_birth, v_role, v_attested, v_guardian, new.email);
  end if;

  v_initial_coins := case
    when v_role = 'player' and v_already_confirmed then private.welcome_bonus()
    else 0
  end;

  insert into public.profiles (
    id,
    username,
    display_name,
    country,
    position,
    preferred_foot,
    birth_date,
    role,
    coins
  )
  values (
    new.id,
    coalesce(v_meta ->> 'username', 'player_' || substr(new.id::text, 1, 8)),
    v_meta ->> 'display_name',
    v_meta ->> 'country',
    v_meta ->> 'position',
    coalesce(v_meta ->> 'preferred_foot', 'droit'),
    v_birth,
    v_role,
    v_initial_coins
  );

  if v_is_minor is not null then
    insert into public.account_consents (
      user_id, terms_version, is_minor, parental_attestation, guardian_email, attested_at
    )
    values (
      new.id,
      private.terms_version(),
      v_is_minor,
      v_is_minor and v_attested,
      case when v_is_minor then v_guardian end,
      case when v_is_minor then now() end
    );
    if v_is_minor then
      insert into public.guardian_contacts (player_id, guardian_email)
      values (new.id, v_guardian)
      on conflict (player_id) do update set guardian_email = excluded.guardian_email;
    end if;
  end if;

  if v_initial_coins > 0 then
    insert into public.transactions (user_id, type, amount, currency, balance_after, reason)
    values (new.id, 'earn', v_initial_coins, 'coins', v_initial_coins, 'welcome_bonus');
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

revoke execute on function handle_new_user() from public, anon, authenticated;

-- La date de naissance ne se modifie plus librement (sinon un mineur
-- pourrait se vieillir pour contourner l'accord parental). Un compte qui
-- n'en a pas encore la déclare une seule fois avec `declare_birth_date`.
revoke update (birth_date) on profiles from authenticated;

create or replace function declare_birth_date(
  p_birth_date date,
  p_guardian_email text default null,
  p_parental_attestation boolean default false
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text;
  v_current date;
  v_email text;
  v_is_minor boolean;
  v_guardian text := nullif(trim(p_guardian_email), '');
begin
  if v_uid is null then
    raise exception 'Connexion requise.' using errcode = '42501';
  end if;
  select role, birth_date into v_role, v_current from profiles where id = v_uid;
  if v_current is not null then
    raise exception 'Date de naissance déjà renseignée.' using errcode = 'P0001';
  end if;
  select email into v_email from auth.users where id = v_uid;
  v_is_minor := private.check_age_rules(p_birth_date, v_role, p_parental_attestation, v_guardian, v_email);

  update profiles set birth_date = p_birth_date where id = v_uid;

  insert into account_consents (user_id, terms_version, is_minor, parental_attestation, guardian_email, attested_at)
  values (v_uid, private.terms_version(), v_is_minor, v_is_minor and p_parental_attestation,
          case when v_is_minor then v_guardian end, case when v_is_minor then now() end)
  on conflict (user_id) do update set
    is_minor = excluded.is_minor,
    parental_attestation = excluded.parental_attestation,
    guardian_email = excluded.guardian_email,
    attested_at = excluded.attested_at;

  if v_is_minor then
    insert into guardian_contacts (player_id, guardian_email)
    values (v_uid, v_guardian)
    on conflict (player_id) do update set guardian_email = excluded.guardian_email;
  end if;
end;
$$;

revoke execute on function declare_birth_date(date, text, boolean) from public, anon;
grant execute on function declare_birth_date(date, text, boolean) to authenticated;

-- Achats d'argent réel autorisés ? Majeur, ou mineur avec accord parental
-- attesté. Date de naissance inconnue : non. Utilisé par le paiement.
create or replace function private.can_purchase(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from profiles p
    left join account_consents c on c.user_id = p.id
    where p.id = p_user_id
      and p.birth_date is not null
      and (
        p.birth_date <= (current_date - interval '18 years')
        or coalesce(c.parental_attestation, false)
      )
  );
$$;

revoke execute on function private.can_purchase(uuid) from public, anon, authenticated;
