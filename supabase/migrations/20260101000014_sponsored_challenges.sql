-- Défis Sponsorisés en libre-service pour les comptes marque (role='brand')
-- — voir PARTIE 8.3. Jusqu'ici seuls Battle/Challenge/King étaient créables
-- par un joueur ; Sponsorisé restait un type théorique jamais atteignable
-- (aucune UI, aucun compte marque, la RPC `create_challenge` le rejetait
-- explicitement).
--
-- Le prix d'un défi sponsorisé n'est PAS une cagnotte de Ballons émise par
-- la plateforme (contrairement à Battle/Challenge/King, voir
-- `20260101000012_challenge_prize_pool.sql`) : c'est un prix réel décrit en
-- texte libre ([prize_description]) que la marque fournit et remet
-- elle-même au vainqueur, hors de l'app — aucune dépendance à un moyen de
-- paiement in-app.

alter table challenges add column prize_description text;

-- =========================================================================
-- handle_new_user — ajoute 'brand' à l'allowlist des rôles auto-attribuables
-- à l'inscription (déjà 'player'/'scout' depuis
-- `20260101000013_scouting_messaging.sql`).
-- =========================================================================
create or replace function handle_new_user()
returns trigger as $$
declare
  v_role text := coalesce(new.raw_user_meta_data ->> 'role', 'player');
begin
  if v_role not in ('player', 'scout', 'brand') then
    v_role := 'player';
  end if;

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
    coalesce(new.raw_user_meta_data ->> 'username', 'player_' || substr(new.id::text, 1, 8)),
    new.raw_user_meta_data ->> 'display_name',
    new.raw_user_meta_data ->> 'country',
    new.raw_user_meta_data ->> 'position',
    coalesce(new.raw_user_meta_data ->> 'preferred_foot', 'droit'),
    nullif(new.raw_user_meta_data ->> 'birth_date', '')::date,
    v_role,
    case when v_role = 'player' then 500 else 0 end
  );

  if v_role = 'player' then
    insert into public.transactions (user_id, type, amount, currency, balance_after, reason)
    values (new.id, 'earn', 500, 'coins', 500, 'welcome_bonus');
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

-- =========================================================================
-- create_challenge — accepte désormais 'sponsored' pour un compte marque
-- vérifié (`profiles.is_verified`, activé manuellement par un admin — même
-- principe que `organizations.is_verified`, aucun flux de vérification
-- automatique n'existe encore). Un défi sponsorisé :
--   - ne coûte rien à créer (la marque apporte de la valeur réelle, pas de
--     Ballons à débiter) ;
--   - est gratuit à rejoindre (`entry_cost = 0`) ;
--   - exige une description de prix réelle (`prize_description`) ;
--   - ne débite jamais de Ballons au joueur, ni n'en distribue au gagnant
--     (`prize_currency = 'real'`, jamais traité par
--     `resolve_expired_challenges` qui ne paie qu'en `'coins'`).
-- =========================================================================
create or replace function create_challenge(
  p_title text,
  p_description text,
  p_type text,
  p_end_date timestamptz,
  p_category text default null,
  p_prize_pool integer default 0,
  p_max_participants integer default null,
  p_record_unit text default null,
  p_prize_description text default null
)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_is_verified boolean;
  v_economy jsonb;
  v_create_cost integer;
  v_entry_cost integer;
  v_new_balance integer;
  v_challenge_id uuid;
  v_sponsor_name text;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  if p_end_date <= now() then
    raise exception 'La date de fin doit être dans le futur.' using errcode = 'P0001';
  end if;

  select role, is_verified, coalesce(display_name, username)
    into v_role, v_is_verified, v_sponsor_name
  from profiles where id = v_user_id;

  if p_type = 'sponsored' then
    if v_role != 'brand' then
      raise exception 'Seul un compte marque peut créer un défi sponsorisé.'
        using errcode = 'P0001';
    end if;
    if not coalesce(v_is_verified, false) then
      raise exception
        'Ton compte marque doit être vérifié avant de pouvoir publier un défi sponsorisé.'
        using errcode = 'P0001';
    end if;
    if p_prize_description is null or trim(p_prize_description) = '' then
      raise exception 'La description du prix est requise pour un défi sponsorisé.'
        using errcode = 'P0001';
    end if;

    insert into challenges (
      creator_id, title, description, type, category, entry_cost, prize_pool,
      prize_currency, prize_description, sponsor_id, sponsor_name,
      max_participants, end_date, status
    ) values (
      v_user_id, p_title, p_description, 'sponsored', p_category, 0, 0,
      'real', p_prize_description, v_user_id, v_sponsor_name,
      p_max_participants, p_end_date, 'active'
    )
    returning id into v_challenge_id;

    return jsonb_build_object('challenge_id', v_challenge_id);
  end if;

  -- World (hebdomadaire officiel) reste hors de portée des joueurs comme
  -- des marques — piloté par un admin, hors RPC `create_challenge`.
  if p_type not in ('battle', 'challenge', 'king') then
    raise exception
      'Seuls les défis Battle, Challenge et King peuvent être créés par les joueurs.'
      using errcode = 'P0001';
  end if;

  select value into v_economy from app_config where key = 'economy';
  v_create_cost := coalesce((v_economy ->> 'create_challenge_cost')::integer, 200);
  v_entry_cost := case p_type
    when 'battle' then coalesce((v_economy ->> 'join_battle_min_cost')::integer, 50)
    else coalesce((v_economy ->> 'join_challenge_cost')::integer, 20)
  end;

  update profiles set coins = coins - v_create_cost
  where id = v_user_id and coins >= v_create_cost
  returning coins into v_new_balance;

  if v_new_balance is null then
    raise exception 'Solde de Ballons insuffisant.' using errcode = 'P0001';
  end if;

  insert into challenges (
    creator_id, title, description, type, category, entry_cost, prize_pool,
    max_participants, record_unit, end_date, status
  ) values (
    v_user_id, p_title, p_description, p_type, p_category, v_entry_cost, p_prize_pool,
    p_max_participants, p_record_unit, p_end_date, 'active'
  )
  returning id into v_challenge_id;

  insert into transactions (
    user_id, type, amount, currency, balance_after, reason, reference_type, reference_id
  ) values (
    v_user_id, 'spend', -v_create_cost, 'coins', v_new_balance, 'create_challenge',
    'challenge', v_challenge_id
  );

  return jsonb_build_object('challenge_id', v_challenge_id);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function create_challenge(
  text, text, text, timestamptz, text, integer, integer, text, text
) to authenticated;

-- L'ancienne signature (8 paramètres, sans `p_prize_description`) doit être
-- retirée : Postgres autoriserait sinon les deux signatures en parallèle, et
-- le client pourrait continuer d'appeler l'ancienne (sans jamais passer de
-- description de prix) sans erreur.
drop function if exists create_challenge(
  text, text, text, timestamptz, text, integer, integer, text
);
