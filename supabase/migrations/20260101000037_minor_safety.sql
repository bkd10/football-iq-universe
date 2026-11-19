-- Protection des mineurs (utilisateurs de 15 à 22 ans, dont beaucoup ont
-- moins de 18 ans). Mesures mises en place, À FAIRE VALIDER PAR UN AVOCAT
-- BRITANNIQUE : ce fichier n'est pas un avis juridique.
--
-- Inspiré de ce que font TikTok, Instagram et Twitch pour les ados, et du
-- Children's Code de l'ICO (haute confidentialité par défaut, pas de
-- techniques d'incitation, localisation désactivée) :
--   1. Âge : règles lues dans `app_config.legal` (âge minimum, âge de la
--      majorité, accord parental, règles par pays), jamais figées en dur.
--   2. Réglages de sécurité par défaut pour les moins de 18 ans
--      (`user_safety_settings`) : profil limité, messages privés seulement
--      entre abonnés mutuels, pas de Battle aléatoire sans accord, ville
--      masquée, séries sans perte, rappel de pause.
--   3. Bloquer (`user_blocks`) et signaler (vidéo, commentaire, profil,
--      message) ; file de modération avec statut et date de traitement ;
--      une vidéo signalée par plusieurs personnes est masquée en attendant
--      la décision.
--   4. Achats de Ballons désactivés par défaut pour les mineurs, ou soumis
--      à l'accord d'un parent (lien à usage unique), selon le réglage.
--   5. Séries quotidiennes : pas de remise à zéro punitive pour les mineurs.
--   6. Une marque ne peut jamais écrire en privé à un mineur.
--   7. Droit à l'image : confirmation à la publication d'une vidéo.
--
-- Compatible avec l'ancienne version de l'appli encore en ligne : les
-- contrôles qui demandent la nouvelle appli (date de naissance et CGU
-- obligatoires pour toutes les inscriptions, case « droit à l'image »)
-- s'activent avec `app_config.legal.strict_mode = true`, à mettre au
-- moment de la publication (fichier `mise_a_jour_mineurs_2_publication.sql`).

create schema if not exists private;

-- =========================================================================
-- 0. Réglages (modifiables sans redéployer : Table Editor > app_config)
-- =========================================================================
insert into app_config (key, value)
values ('legal', '{}'::jsonb)
on conflict (key) do nothing;

-- Les valeurs déjà présentes sont gardées ; seules les clés manquantes sont
-- ajoutées.
update app_config
set value = jsonb_build_object(
      'min_age', 13,
      'adult_age', 18,
      'parental_consent_under', 18,
      'pro_min_age', 18,
      'terms_version', '2026-11',
      -- Règles par pays (nom ou code, en minuscules) qui remplacent les
      -- valeurs ci-dessus, ex. {"fr": {"min_age": 15}, "france": {"min_age": 15}}.
      'country_rules', '{}'::jsonb,
      -- 'disabled' : aucun achat avant la majorité ;
      -- 'parental_consent' : achat possible après l'accord d'un parent.
      'minor_purchases', 'disabled',
      'minor_monthly_limit_cents', 5000,
      'parent_link_valid_days', 7,
      -- Nombre de personnes différentes qui signalent une vidéo avant
      -- qu'elle soit masquée en attendant la décision d'un modérateur.
      'report_auto_hide_threshold', 3,
      'strict_mode', true,
      'minor_defaults', jsonb_build_object(
        'profile_visibility', 'limited',
        'dm_from', 'mutual',
        'allow_random_battles', false,
        'show_location', false,
        'gentle_streaks', true,
        'show_streaks', false,
        'show_countdowns', false,
        'break_reminder_minutes', 45
      ),
      'adult_defaults', jsonb_build_object(
        'profile_visibility', 'public',
        'dm_from', 'everyone',
        'allow_random_battles', true,
        'show_location', true,
        'gentle_streaks', false,
        'show_streaks', true,
        'show_countdowns', true,
        'break_reminder_minutes', 0
      )
    ) || value
where key = 'legal';

-- Lecture d'un réglage texte/booléen/json de `app_config.legal`.
create or replace function private.legal_value(p_key text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select value -> p_key from app_config where key = 'legal';
$$;

revoke execute on function private.legal_value(text) from public, anon, authenticated;

-- Règles d'âge applicables (avec la règle du pays si elle existe).
create or replace function private.age_rules(p_country text default null)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
           'min_age', coalesce((l.value ->> 'min_age')::int, 13),
           'adult_age', coalesce((l.value ->> 'adult_age')::int, 18),
           'parental_consent_under', coalesce((l.value ->> 'parental_consent_under')::int, 18),
           'pro_min_age', coalesce((l.value ->> 'pro_min_age')::int, 18)
         )
         || coalesce(l.value -> 'country_rules' -> lower(trim(coalesce(p_country, ''))), '{}'::jsonb)
  from (select coalesce((select value from app_config where key = 'legal'), '{}'::jsonb) as value) l;
$$;

revoke execute on function private.age_rules(text) from public, anon, authenticated;

-- Pour l'appli (écran d'inscription) : les mêmes règles que le serveur.
create or replace function get_age_rules(p_country text default null)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select private.age_rules(p_country)
         || jsonb_build_object(
              'country_rules', coalesce(private.legal_value('country_rules'), '{}'::jsonb),
              'minor_purchases', coalesce(private.legal_value('minor_purchases') #>> '{}', 'disabled')
            );
$$;

revoke execute on function get_age_rules(text) from public;
grant execute on function get_age_rules(text) to anon, authenticated;

-- Âge en années révolues ; null si la date de naissance est inconnue.
create or replace function private.user_age(p_user_id uuid)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select extract(year from age(current_date, birth_date))::integer
  from profiles where id = p_user_id and birth_date is not null;
$$;

-- Mineur ? Date de naissance inconnue = traité comme mineur, par prudence.
create or replace function private.is_minor(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    private.user_age(p_user_id) < coalesce((private.age_rules((select country from profiles where id = p_user_id)) ->> 'adult_age')::int, 18),
    true
  );
$$;

revoke execute on function private.user_age(uuid) from public, anon, authenticated;
revoke execute on function private.is_minor(uuid) from public, anon, authenticated;

-- =========================================================================
-- 1. Âge à l'inscription
-- =========================================================================
create or replace function private.check_age_rules(
  p_birth_date date,
  p_role text,
  p_parental_attestation boolean,
  p_guardian_email text,
  p_own_email text,
  p_country text
)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_rules jsonb := private.age_rules(p_country);
  v_age integer;
  v_min integer := (v_rules ->> 'min_age')::int;
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
  if v_age < v_min then
    raise exception 'Il faut avoir au moins % ans pour s''inscrire.', v_min using errcode = 'P0001';
  end if;
  if p_role in ('scout', 'brand') and v_age < (v_rules ->> 'pro_min_age')::int then
    raise exception 'Les comptes recruteur et marque sont réservés aux majeurs.' using errcode = 'P0001';
  end if;
  if v_age < (v_rules ->> 'parental_consent_under')::int then
    if not coalesce(p_parental_attestation, false)
       or p_guardian_email is null
       or p_guardian_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'
       or lower(p_guardian_email) = lower(coalesce(p_own_email, '')) then
      raise exception 'Accord parental requis : coche l''attestation et donne l''e-mail d''un parent.' using errcode = 'P0001';
    end if;
  end if;
  return v_age < (v_rules ->> 'adult_age')::int;
end;
$$;

-- L'ancienne signature (sans pays) suit les mêmes règles.
create or replace function private.check_age_rules(
  p_birth_date date,
  p_role text,
  p_parental_attestation boolean,
  p_guardian_email text,
  p_own_email text
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select private.check_age_rules(p_birth_date, p_role, p_parental_attestation, p_guardian_email, p_own_email, null);
$$;

revoke execute on function private.check_age_rules(date, text, boolean, text, text, text) from public, anon, authenticated;
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
  v_strict boolean := coalesce((private.legal_value('strict_mode') #>> '{}')::boolean, true);
  v_is_minor boolean;
  v_initial_coins integer;
begin
  if v_role not in ('player', 'scout', 'brand') then
    v_role := 'player';
  end if;

  -- Inscription depuis l'appli (elle envoie toujours un pseudo) : date de
  -- naissance, âge minimum, accord parental et CGU obligatoires. Tant que
  -- `strict_mode` est désactivé (ancienne appli encore en ligne, qui
  -- n'envoie pas ces champs), seules les inscriptions de la nouvelle appli
  -- (qui envoient `terms_accepted`) sont contrôlées. Un compte créé à la
  -- main dans le tableau de bord Supabase n'a pas de pseudo : sa date de
  -- naissance reste inconnue et il est traité comme mineur.
  if v_meta ? 'username' and (v_strict or v_meta ? 'terms_accepted') then
    if coalesce((v_meta ->> 'terms_accepted')::boolean, false) is not true then
      raise exception 'Il faut accepter les conditions d''utilisation.' using errcode = 'P0001';
    end if;
    v_is_minor := private.check_age_rules(
      v_birth, v_role, v_attested, v_guardian, new.email, v_meta ->> 'country'
    );
  end if;

  v_initial_coins := case
    when v_role = 'player' and v_already_confirmed then private.welcome_bonus()
    else 0
  end;

  insert into public.profiles (
    id, username, display_name, country, position, preferred_foot, birth_date, role, coins
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
    if v_is_minor and v_guardian is not null then
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

-- declare_birth_date (comptes sans date) : mêmes règles, pays compris.
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
  v_country text;
  v_current date;
  v_email text;
  v_is_minor boolean;
  v_guardian text := nullif(trim(p_guardian_email), '');
begin
  if v_uid is null then
    raise exception 'Connexion requise.' using errcode = '42501';
  end if;
  select role, birth_date, country into v_role, v_current, v_country from profiles where id = v_uid;
  if v_current is not null then
    raise exception 'Date de naissance déjà renseignée.' using errcode = 'P0001';
  end if;
  select email into v_email from auth.users where id = v_uid;
  v_is_minor := private.check_age_rules(p_birth_date, v_role, p_parental_attestation, v_guardian, v_email, v_country);

  update profiles set birth_date = p_birth_date where id = v_uid;

  insert into account_consents (user_id, terms_version, is_minor, parental_attestation, guardian_email, attested_at)
  values (v_uid, private.terms_version(), v_is_minor, v_is_minor and p_parental_attestation,
          case when v_is_minor then v_guardian end, case when v_is_minor then now() end)
  on conflict (user_id) do update set
    is_minor = excluded.is_minor,
    parental_attestation = excluded.parental_attestation,
    guardian_email = excluded.guardian_email,
    attested_at = excluded.attested_at;

  if v_is_minor and v_guardian is not null then
    insert into guardian_contacts (player_id, guardian_email)
    values (v_uid, v_guardian)
    on conflict (player_id) do update set guardian_email = excluded.guardian_email;
  end if;
end;
$$;

revoke execute on function declare_birth_date(date, text, boolean) from public, anon;
grant execute on function declare_birth_date(date, text, boolean) to authenticated;

-- Le drapeau « mineur » de la base (`account_consents.is_minor`) suit
-- l'âge réel : remis à jour chaque nuit (un joueur devient majeur).
create or replace function private.refresh_minor_flags()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  update account_consents c
  set is_minor = private.is_minor(c.user_id)
  where c.is_minor is distinct from private.is_minor(c.user_id);
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke execute on function private.refresh_minor_flags() from public, anon, authenticated;

create extension if not exists pg_cron;
select cron.unschedule('refresh-minor-flags')
where exists (select 1 from cron.job where jobname = 'refresh-minor-flags');
select cron.schedule('refresh-minor-flags', '23 2 * * *', 'select private.refresh_minor_flags()');

-- =========================================================================
-- 2. Réglages de sécurité et de confidentialité, par joueur
-- =========================================================================
create table if not exists user_safety_settings (
  user_id uuid primary key references profiles (id) on delete cascade,
  profile_visibility text not null default 'limited'
    check (profile_visibility in ('public', 'limited')),
  dm_from text not null default 'mutual'
    check (dm_from in ('everyone', 'mutual', 'nobody')),
  allow_random_battles boolean not null default false,
  show_location boolean not null default false,
  gentle_streaks boolean not null default true,
  show_streaks boolean not null default false,
  show_countdowns boolean not null default false,
  break_reminder_minutes integer not null default 45
    check (break_reminder_minutes between 0 and 240),
  customized boolean not null default false,
  updated_at timestamptz not null default now()
);

alter table user_safety_settings enable row level security;

drop policy if exists "Users read their own safety settings" on user_safety_settings;
create policy "Users read their own safety settings"
on user_safety_settings for select
using (auth.uid() = user_id);

revoke all on user_safety_settings from anon, authenticated;
grant select on user_safety_settings to authenticated;

-- Valeurs par défaut selon l'âge (mineur ou âge inconnu : protecteur).
create or replace function private.apply_default_safety_settings(p_user_id uuid, p_force boolean default false)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_d jsonb := coalesce(
    private.legal_value(case when private.is_minor(p_user_id) then 'minor_defaults' else 'adult_defaults' end),
    '{}'::jsonb
  );
begin
  insert into user_safety_settings (
    user_id, profile_visibility, dm_from, allow_random_battles, show_location,
    gentle_streaks, show_streaks, show_countdowns, break_reminder_minutes
  )
  values (
    p_user_id,
    coalesce(v_d ->> 'profile_visibility', 'limited'),
    coalesce(v_d ->> 'dm_from', 'mutual'),
    coalesce((v_d ->> 'allow_random_battles')::boolean, false),
    coalesce((v_d ->> 'show_location')::boolean, false),
    coalesce((v_d ->> 'gentle_streaks')::boolean, true),
    coalesce((v_d ->> 'show_streaks')::boolean, false),
    coalesce((v_d ->> 'show_countdowns')::boolean, false),
    coalesce((v_d ->> 'break_reminder_minutes')::int, 45)
  )
  on conflict (user_id) do update set
    profile_visibility = excluded.profile_visibility,
    dm_from = excluded.dm_from,
    allow_random_battles = excluded.allow_random_battles,
    show_location = excluded.show_location,
    gentle_streaks = excluded.gentle_streaks,
    show_streaks = excluded.show_streaks,
    show_countdowns = excluded.show_countdowns,
    break_reminder_minutes = excluded.break_reminder_minutes,
    updated_at = now()
  where p_force or not user_safety_settings.customized;
end;
$$;

revoke execute on function private.apply_default_safety_settings(uuid, boolean) from public, anon, authenticated;

create or replace function private.on_profile_safety_defaults()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    perform private.apply_default_safety_settings(new.id, false);
  elsif new.birth_date is distinct from old.birth_date then
    -- Date de naissance déclarée plus tard : réglages par défaut de son âge,
    -- sauf si le joueur les a déjà choisis lui-même.
    perform private.apply_default_safety_settings(new.id, false);
  end if;
  return new;
end;
$$;

revoke execute on function private.on_profile_safety_defaults() from public, anon, authenticated;

drop trigger if exists trigger_profile_safety_defaults on profiles;
create trigger trigger_profile_safety_defaults
after insert or update of birth_date on profiles
for each row execute function private.on_profile_safety_defaults();

-- Comptes existants : réglages par défaut selon leur âge.
insert into user_safety_settings (user_id)
select p.id from profiles p
where not exists (select 1 from user_safety_settings s where s.user_id = p.id);
select private.apply_default_safety_settings(s.user_id, false)
from user_safety_settings s where not s.customized;

create or replace function private.safety(p_user_id uuid)
returns user_safety_settings
language sql
stable
security definer
set search_path = public
as $$
  select s from user_safety_settings s where s.user_id = p_user_id;
$$;

revoke execute on function private.safety(uuid) from public, anon, authenticated;

-- Un mineur ne peut pas ouvrir ses messages privés à tout le monde
-- (comme TikTok : au mieux « amis » / abonnés mutuels).
create or replace function update_my_safety_settings(p_settings jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_s user_safety_settings;
  v_minor boolean;
begin
  if v_uid is null then
    raise exception 'Connexion requise.' using errcode = '42501';
  end if;
  v_minor := private.is_minor(v_uid);
  perform private.apply_default_safety_settings(v_uid, false);
  select * into v_s from user_safety_settings where user_id = v_uid for update;

  v_s.profile_visibility := coalesce(p_settings ->> 'profile_visibility', v_s.profile_visibility);
  v_s.dm_from := coalesce(p_settings ->> 'dm_from', v_s.dm_from);
  v_s.allow_random_battles := coalesce((p_settings ->> 'allow_random_battles')::boolean, v_s.allow_random_battles);
  v_s.show_location := coalesce((p_settings ->> 'show_location')::boolean, v_s.show_location);
  v_s.gentle_streaks := coalesce((p_settings ->> 'gentle_streaks')::boolean, v_s.gentle_streaks);
  v_s.show_streaks := coalesce((p_settings ->> 'show_streaks')::boolean, v_s.show_streaks);
  v_s.show_countdowns := coalesce((p_settings ->> 'show_countdowns')::boolean, v_s.show_countdowns);
  v_s.break_reminder_minutes := coalesce((p_settings ->> 'break_reminder_minutes')::int, v_s.break_reminder_minutes);

  if v_minor and v_s.dm_from = 'everyone' then
    raise exception 'Moins de 18 ans : messages privés seulement avec tes abonnés mutuels.' using errcode = 'P0001';
  end if;

  update user_safety_settings set
    profile_visibility = v_s.profile_visibility,
    dm_from = v_s.dm_from,
    allow_random_battles = v_s.allow_random_battles,
    show_location = v_s.show_location,
    gentle_streaks = v_s.gentle_streaks,
    show_streaks = v_s.show_streaks,
    show_countdowns = v_s.show_countdowns,
    break_reminder_minutes = v_s.break_reminder_minutes,
    customized = true,
    updated_at = now()
  where user_id = v_uid;

  return get_my_safety();
end;
$$;

-- =========================================================================
-- 3. Bloquer
-- =========================================================================
create table if not exists user_blocks (
  blocker_id uuid not null references profiles (id) on delete cascade,
  blocked_id uuid not null references profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create index if not exists idx_user_blocks_blocked on user_blocks (blocked_id, blocker_id);

alter table user_blocks enable row level security;

drop policy if exists "Users see who they blocked" on user_blocks;
create policy "Users see who they blocked"
on user_blocks for select
using (auth.uid() = blocker_id);

revoke all on user_blocks from anon, authenticated;
grant select on user_blocks to authenticated;

-- Vrai si l'un des deux a bloqué l'autre.
create or replace function private.is_blocked_pair(p_a uuid, p_b uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select p_a is not null and p_b is not null and p_a <> p_b and exists (
    select 1 from user_blocks
    where (blocker_id = p_a and blocked_id = p_b)
       or (blocker_id = p_b and blocked_id = p_a)
  );
$$;

create or replace function private.is_mutual_follow(p_a uuid, p_b uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from follows where follower_id = p_a and following_id = p_b)
     and exists (select 1 from follows where follower_id = p_b and following_id = p_a);
$$;

revoke execute on function private.is_blocked_pair(uuid, uuid) from public, anon, authenticated;
revoke execute on function private.is_mutual_follow(uuid, uuid) from public, anon, authenticated;
-- Utilisées dans les règles RLS : appelables (mais le schéma private
-- n'est pas exposé par l'API).
grant usage on schema private to anon, authenticated;
grant execute on function private.is_blocked_pair(uuid, uuid) to anon, authenticated;

create or replace function block_user(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Connexion requise.' using errcode = '42501';
  end if;
  if p_user_id is null or p_user_id = v_uid or not exists (select 1 from profiles where id = p_user_id) then
    raise exception 'Joueur introuvable.' using errcode = 'P0001';
  end if;
  insert into user_blocks (blocker_id, blocked_id) values (v_uid, p_user_id)
  on conflict do nothing;
  -- Plus d'abonnement dans un sens ni dans l'autre.
  delete from follows
  where (follower_id = v_uid and following_id = p_user_id)
     or (follower_id = p_user_id and following_id = v_uid);
  return jsonb_build_object('blocked', true);
end;
$$;

create or replace function unblock_user(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Connexion requise.' using errcode = '42501';
  end if;
  delete from user_blocks where blocker_id = auth.uid() and blocked_id = p_user_id;
  return jsonb_build_object('blocked', false);
end;
$$;

create or replace function list_my_blocks()
returns table (user_id uuid, username text, avatar_url text, blocked_at timestamptz)
language sql
stable
security definer
set search_path = public
as $$
  select p.id, p.username, p.avatar_url, b.created_at
  from user_blocks b join profiles p on p.id = b.blocked_id
  where b.blocker_id = auth.uid()
  order by b.created_at desc;
$$;

revoke execute on function block_user(uuid) from public, anon;
revoke execute on function unblock_user(uuid) from public, anon;
revoke execute on function list_my_blocks() from public, anon;
grant execute on function block_user(uuid) to authenticated;
grant execute on function unblock_user(uuid) to authenticated;
grant execute on function list_my_blocks() to authenticated;

-- Un joueur bloqué ne voit plus les vidéos ni les commentaires de celui qui
-- l'a bloqué (et inversement).
drop policy if exists "Active videos viewable by everyone" on videos;
create policy "Active videos viewable by everyone"
on videos for select
using (
  (status = 'active' or user_id = auth.uid())
  and not private.is_blocked_pair(auth.uid(), user_id)
);

drop policy if exists "Active comments are viewable by everyone" on comments;
create policy "Active comments are viewable by everyone"
on comments for select
using (
  status = 'active'
  and not private.is_blocked_pair(auth.uid(), user_id)
);

-- Ni commentaire, ni abonnement entre deux joueurs qui se sont bloqués.
create or replace function private.refuse_blocked_comment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if private.is_blocked_pair(new.user_id, (select user_id from videos where id = new.video_id)) then
    raise exception 'Action impossible : ce joueur t''a bloqué ou tu l''as bloqué.' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists trigger_refuse_blocked_comment on comments;
create trigger trigger_refuse_blocked_comment
before insert on comments
for each row execute function private.refuse_blocked_comment();

create or replace function private.refuse_blocked_follow()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if private.is_blocked_pair(new.follower_id, new.following_id) then
    raise exception 'Action impossible : ce joueur t''a bloqué ou tu l''as bloqué.' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists trigger_refuse_blocked_follow on follows;
create trigger trigger_refuse_blocked_follow
before insert on follows
for each row execute function private.refuse_blocked_follow();

revoke execute on function private.refuse_blocked_comment() from public, anon, authenticated;
revoke execute on function private.refuse_blocked_follow() from public, anon, authenticated;

-- Profil limité : les abonnements d'un profil limité ne sont visibles que
-- par les deux personnes concernées.
create or replace function private.is_limited_profile(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select profile_visibility = 'limited' from user_safety_settings where user_id = p_user_id), true);
$$;

revoke execute on function private.is_limited_profile(uuid) from public;
grant execute on function private.is_limited_profile(uuid) to anon, authenticated;

drop policy if exists "Follows are viewable by everyone" on follows;
create policy "Follows are viewable by everyone"
on follows for select
using (
  auth.uid() = follower_id
  or auth.uid() = following_id
  or not (private.is_limited_profile(follower_id) or private.is_limited_profile(following_id))
);

-- =========================================================================
-- 4. Profil vu par un autre joueur (profil limité, ville masquée, blocage)
-- =========================================================================
create or replace function get_public_profile(p_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_viewer uuid := auth.uid();
  v_p profiles;
  v_s user_safety_settings;
  v_mutual boolean;
  v_trusted boolean;
  v_limited boolean;
begin
  select * into v_p from profiles where id = p_user_id;
  if v_p.id is null or coalesce(v_p.is_banned, false) then
    return null;
  end if;
  if private.is_blocked_pair(v_viewer, p_user_id) then
    return jsonb_build_object(
      'id', v_p.id, 'username', v_p.username, 'unavailable', true,
      'i_blocked', exists (select 1 from user_blocks where blocker_id = v_viewer and blocked_id = p_user_id)
    );
  end if;
  v_s := private.safety(p_user_id);
  v_mutual := v_viewer is not null and private.is_mutual_follow(v_viewer, p_user_id);
  -- « Personne de confiance » : soi-même, ou quelqu'un que le joueur suit.
  v_trusted := v_viewer = p_user_id
    or exists (select 1 from follows where follower_id = p_user_id and following_id = v_viewer)
    or exists (select 1 from profiles where id = v_viewer and role = 'admin');
  v_limited := coalesce(v_s.profile_visibility, 'limited') = 'limited' and not v_trusted;

  return jsonb_build_object(
    'id', v_p.id,
    'username', v_p.username,
    'display_name', v_p.display_name,
    'avatar_url', v_p.avatar_url,
    'role', v_p.role,
    'level', v_p.level,
    'is_verified', v_p.is_verified,
    'verification_type', v_p.verification_type,
    'position', v_p.position,
    'preferred_foot', v_p.preferred_foot,
    'country', v_p.country,
    'city', case when coalesce(v_s.show_location, false) or v_trusted then v_p.city end,
    'bio', case when v_limited then '' else coalesce(v_p.bio, '') end,
    'height_cm', case when v_limited then null else v_p.height_cm end,
    'weight_kg', case when v_limited then null else v_p.weight_kg end,
    'stars', v_p.stars,
    'iq_technique', v_p.iq_technique,
    'iq_creativity', v_p.iq_creativity,
    'iq_popularity', v_p.iq_popularity,
    'iq_consistency', v_p.iq_consistency,
    'iq_tactical', v_p.iq_tactical,
    'followers_count', case when v_limited then 0 else v_p.followers_count end,
    'following_count', case when v_limited then 0 else v_p.following_count end,
    'videos_count', v_p.videos_count,
    'moves_created_count', v_p.moves_created_count,
    'likes_received_count', v_p.likes_received_count,
    'challenges_won_count', v_p.challenges_won_count,
    'form_score', v_p.form_score,
    'created_at', v_p.created_at,
    'updated_at', v_p.updated_at,
    'limited', v_limited,
    'is_mutual', v_mutual,
    'can_message', v_viewer is not null and private.can_private_message(v_viewer, p_user_id) is null
  );
end;
$$;

-- =========================================================================
-- 5. Messages privés
-- =========================================================================
-- Renvoie null si l'envoi est permis, sinon la raison (texte affiché).
create or replace function private.can_private_message(p_sender uuid, p_recipient uuid)
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_sender_role text;
  v_dm text;
  v_recipient_minor boolean := private.is_minor(p_recipient);
  v_mutual boolean := private.is_mutual_follow(p_sender, p_recipient);
begin
  if private.is_blocked_pair(p_sender, p_recipient) then
    return 'Action impossible : ce joueur t''a bloqué ou tu l''as bloqué.';
  end if;
  select role into v_sender_role from profiles where id = p_sender;
  if v_recipient_minor and v_sender_role = 'brand' then
    return 'Une marque ne peut pas écrire en privé à un joueur mineur.';
  end if;
  v_dm := coalesce((private.safety(p_recipient)).dm_from, 'mutual');
  if v_dm = 'nobody' then
    return 'Ce joueur ne reçoit pas de messages privés.';
  end if;
  -- Mineur (destinataire ou expéditeur) : seulement entre abonnés mutuels.
  if (v_recipient_minor or private.is_minor(p_sender) or v_dm = 'mutual') and not v_mutual then
    return 'Messages privés seulement entre abonnés mutuels.';
  end if;
  return null;
end;
$$;

revoke execute on function private.can_private_message(uuid, uuid) from public, anon, authenticated;

revoke execute on function get_public_profile(uuid) from public;
grant execute on function get_public_profile(uuid) to anon, authenticated;

create or replace function request_scout_contact(p_player_id uuid)
returns jsonb as $$
declare
  v_scout_id uuid := auth.uid();
  v_scout_role text;
  v_has_active_sub boolean;
  v_guardian_email text;
  v_is_minor boolean;
  v_conversation_id uuid;
  v_status text;
  v_refusal text;
begin
  if v_scout_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;
  if v_scout_id = p_player_id then
    raise exception 'Action invalide.' using errcode = 'P0001';
  end if;

  select role into v_scout_role from profiles where id = v_scout_id;
  if v_scout_role is distinct from 'scout' then
    raise exception 'Seul un compte recruteur peut contacter un joueur.' using errcode = 'P0001';
  end if;

  select exists (
    select 1 from scout_subscriptions
    where scout_id = v_scout_id and status = 'active'
      and (expires_at is null or expires_at > now())
  ) into v_has_active_sub;
  if not v_has_active_sub then
    raise exception 'Un abonnement actif est requis pour contacter un joueur.' using errcode = 'P0001';
  end if;

  if not exists (select 1 from profiles where id = p_player_id and role = 'player') then
    raise exception 'Joueur introuvable.' using errcode = 'P0001';
  end if;

  v_refusal := private.can_private_message(v_scout_id, p_player_id);
  if v_refusal is not null then
    raise exception '%', v_refusal using errcode = 'P0001';
  end if;

  v_is_minor := private.is_minor(p_player_id);
  if v_is_minor then
    select guardian_email into v_guardian_email from guardian_contacts where player_id = p_player_id;
    if v_guardian_email is null or v_guardian_email = '' then
      raise exception
        'Ce joueur est mineur et n''a pas encore renseigné le contact d''un tuteur : impossible de le contacter pour le moment.'
        using errcode = 'P0001';
    end if;
    v_status := 'pending_guardian_approval';
  else
    v_status := 'active';
  end if;

  insert into conversations (player_id, scout_id, status, approved_at)
  values (p_player_id, v_scout_id, v_status, case when v_status = 'active' then now() end)
  returning id into v_conversation_id;

  insert into notifications (user_id, type, title, body, actor_id, reference_type, reference_id)
  values (
    p_player_id, 'scout_interest', 'Un recruteur veut te contacter',
    case
      when v_is_minor then 'L''approbation d''un tuteur est nécessaire avant de pouvoir échanger.'
      else 'Tu peux désormais lui répondre.'
    end,
    v_scout_id, 'conversation', v_conversation_id
  );

  return jsonb_build_object('conversation_id', v_conversation_id, 'status', v_status);
exception
  when unique_violation then
    raise exception 'Tu as déjà contacté ce joueur.' using errcode = 'P0001';
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function request_scout_contact(uuid) to authenticated;

create or replace function send_message(p_conversation_id uuid, p_body text)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_conversation conversations%rowtype;
  v_recipient uuid;
  v_refusal text;
  v_message_id uuid;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;
  if p_body is null or trim(p_body) = '' then
    raise exception 'Le message ne peut pas être vide.' using errcode = 'P0001';
  end if;

  select * into v_conversation from conversations where id = p_conversation_id;
  if v_conversation.id is null then
    raise exception 'Conversation introuvable.' using errcode = 'P0001';
  end if;
  if v_user_id != v_conversation.player_id and v_user_id != v_conversation.scout_id then
    raise exception 'Tu ne fais pas partie de cette conversation.' using errcode = 'P0001';
  end if;
  if v_conversation.status != 'active' then
    raise exception 'Cette conversation n''est pas encore active.' using errcode = 'P0001';
  end if;

  v_recipient := case when v_user_id = v_conversation.player_id
                      then v_conversation.scout_id else v_conversation.player_id end;
  v_refusal := private.can_private_message(v_user_id, v_recipient);
  if v_refusal is not null then
    raise exception '%', v_refusal using errcode = 'P0001';
  end if;

  insert into messages (conversation_id, sender_id, body)
  values (p_conversation_id, v_user_id, trim(p_body))
  returning id into v_message_id;

  update conversations set last_message_at = now() where id = p_conversation_id;

  return jsonb_build_object('message_id', v_message_id);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function send_message(uuid, text) to authenticated;

-- =========================================================================
-- 6. Signalements : messages aussi, masquage automatique, file d'attente
-- =========================================================================
alter table content_reports drop constraint if exists content_reports_target_type_check;
alter table content_reports
  add constraint content_reports_target_type_check
  check (target_type in ('video', 'comment', 'profile', 'message'));

alter table content_reports add column if not exists details text;
alter table content_reports drop constraint if exists content_reports_details_length;
alter table content_reports
  add constraint content_reports_details_length check (char_length(details) <= 1000);

-- Le contenu signalé doit exister ; un message ne peut être signalé que
-- par un participant de la conversation.
create or replace function private.check_report()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.target_type = 'video' and not exists (select 1 from videos where id = new.target_id)
     or new.target_type = 'comment' and not exists (select 1 from comments where id = new.target_id)
     or new.target_type = 'profile' and not exists (select 1 from profiles where id = new.target_id) then
    raise exception 'Contenu introuvable.' using errcode = 'P0001';
  end if;
  if new.target_type = 'message' and not exists (
    select 1 from messages m join conversations c on c.id = m.conversation_id
    where m.id = new.target_id and new.reporter_id in (c.player_id, c.scout_id)
  ) then
    raise exception 'Contenu introuvable.' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists trigger_check_report on content_reports;
create trigger trigger_check_report
before insert on content_reports
for each row execute function private.check_report();

-- Suppression rapide : une vidéo signalée par N personnes différentes
-- (réglage `report_auto_hide_threshold`) est masquée tout de suite
-- (statut 'flagged') en attendant la décision d'un modérateur.
create or replace function private.auto_hide_reported()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_threshold integer := coalesce((private.legal_value('report_auto_hide_threshold') #>> '{}')::int, 3);
begin
  if new.target_type = 'video' and v_threshold > 0 and (
    select count(distinct reporter_id) from content_reports
    where target_type = 'video' and target_id = new.target_id and status = 'pending'
  ) >= v_threshold then
    update videos set status = 'flagged' where id = new.target_id and status = 'active';
  end if;
  return new;
end;
$$;

drop trigger if exists trigger_auto_hide_reported on content_reports;
create trigger trigger_auto_hide_reported
after insert on content_reports
for each row execute function private.auto_hide_reported();

revoke execute on function private.check_report() from public, anon, authenticated;
revoke execute on function private.auto_hide_reported() from public, anon, authenticated;

grant insert (target_type, target_id, reporter_id, reason, details) on content_reports to authenticated;

create or replace function report_content(
  p_target_type text,
  p_target_id uuid,
  p_reason text,
  p_details text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Connecte-toi pour signaler un contenu.' using errcode = '42501';
  end if;
  if p_reason is null or char_length(trim(p_reason)) = 0 or char_length(p_reason) > 500 then
    raise exception 'Choisis un motif.' using errcode = 'P0001';
  end if;
  insert into content_reports (target_type, target_id, reporter_id, reason, details)
  values (p_target_type, p_target_id, auth.uid(), trim(p_reason), nullif(trim(coalesce(p_details, '')), ''))
  returning id into v_id;
  return jsonb_build_object('report_id', v_id, 'status', 'pending');
end;
$$;

revoke execute on function report_content(text, uuid, text, text) from public, anon;
grant execute on function report_content(text, uuid, text, text) to authenticated;

-- File de modération : en attente ou traités, avec statut, date de
-- traitement et « mineur concerné » (auteur ou signaleur).
create or replace function admin_moderation_queue(p_status text default 'pending', p_limit integer default 100)
returns table (
  report_id uuid,
  target_type text,
  target_id uuid,
  reason text,
  reasons text[],
  details text,
  reports_count integer,
  reporter_username text,
  created_at timestamptz,
  author_id uuid,
  author_username text,
  preview_text text,
  video_url text,
  thumbnail_url text,
  target_status text,
  status text,
  resolved_at timestamptz,
  resolved_by_username text,
  resolution_note text,
  minor_involved boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform private.require_admin();

  return query
  with base as (
    select r.*
    from content_reports r
    where (p_status = 'pending' and r.status = 'pending')
       or (p_status <> 'pending' and r.status <> 'pending')
  ),
  grouped as (
    select b.target_type as g_type, b.target_id as g_id, count(*) as cnt,
           array_agg(distinct b.reason) as all_reasons,
           bool_or(b.reporter_id is not null and private.is_minor(b.reporter_id)) as minor_reporter
    from base b
    group by b.target_type, b.target_id
  ),
  firsts as (
    select distinct on (b.target_type, b.target_id) b.*, g.cnt, g.all_reasons, g.minor_reporter
    from base b
    join grouped g on g.g_type = b.target_type and g.g_id = b.target_id
    order by b.target_type, b.target_id, b.created_at
  )
  select
    f.id, f.target_type, f.target_id, f.reason, f.all_reasons, f.details, f.cnt::integer,
    rp.username, f.created_at,
    coalesce(v.user_id, c.user_id, m.sender_id, tp.id),
    coalesce(va.username, ca.username, ma.username, tp.username),
    case f.target_type
      when 'video' then v.caption
      when 'comment' then c.content
      when 'message' then m.body
      else tp.bio
    end,
    v.video_url, v.thumbnail_url,
    case f.target_type
      when 'video' then coalesce(v.status, 'deleted')
      when 'comment' then coalesce(c.status, 'deleted')
      when 'message' then case when m.id is null then 'deleted' else 'active' end
      else case when tp.id is null then 'deleted' when tp.is_banned then 'banned' else 'active' end
    end,
    f.status, f.resolved_at, rb.username, f.resolution_note,
    coalesce(f.minor_reporter, false)
      or (coalesce(v.user_id, c.user_id, m.sender_id, tp.id) is not null
          and private.is_minor(coalesce(v.user_id, c.user_id, m.sender_id, tp.id)))
  from firsts f
  left join profiles rp on rp.id = f.reporter_id
  left join profiles rb on rb.id = f.resolved_by
  left join videos v on f.target_type = 'video' and v.id = f.target_id
  left join profiles va on va.id = v.user_id
  left join comments c on f.target_type = 'comment' and c.id = f.target_id
  left join profiles ca on ca.id = c.user_id
  left join messages m on f.target_type = 'message' and m.id = f.target_id
  left join profiles ma on ma.id = m.sender_id
  left join profiles tp on f.target_type = 'profile' and tp.id = f.target_id
  order by
    case when p_status = 'pending' then 0 else 1 end,
    -- En attente : mineurs concernés et contenus les plus signalés d'abord.
    case when p_status = 'pending' then (coalesce(f.minor_reporter, false)
      or (coalesce(v.user_id, c.user_id, m.sender_id, tp.id) is not null
          and private.is_minor(coalesce(v.user_id, c.user_id, m.sender_id, tp.id))))::int end desc nulls last,
    case when p_status = 'pending' then f.cnt end desc nulls last,
    case when p_status = 'pending' then f.created_at end asc,
    f.resolved_at desc nulls last
  limit greatest(1, least(coalesce(p_limit, 100), 500));
end;
$$;

revoke execute on function admin_moderation_queue(text, integer) from public, anon;
grant execute on function admin_moderation_queue(text, integer) to authenticated;

-- Résolution d'un signalement (remplace la version de la migration 0022) :
-- gère aussi les messages privés (le message retiré est effacé, l'auteur
-- n'est pas banni automatiquement).
create or replace function admin_resolve_report(
  p_report_id uuid,
  p_status text,
  p_author_message text default null,
  p_reporter_message text default null,
  p_note text default null
)
returns jsonb as $$
declare
  v_admin_id uuid := private.require_admin();
  v_report content_reports%rowtype;
  v_author_id uuid;
  v_closed integer;
begin
  if p_status not in ('actioned', 'dismissed') then
    raise exception 'Statut invalide.' using errcode = 'P0001';
  end if;
  if char_length(coalesce(p_author_message, '')) > 500
     or char_length(coalesce(p_reporter_message, '')) > 500 then
    raise exception 'Message trop long (500 caractères max).' using errcode = 'P0001';
  end if;

  select * into v_report from content_reports where id = p_report_id for update;
  if v_report.id is null then
    raise exception 'Signalement introuvable.' using errcode = 'P0001';
  end if;

  if v_report.target_type = 'video' then
    select user_id into v_author_id from videos where id = v_report.target_id;
  elsif v_report.target_type = 'comment' then
    select user_id into v_author_id from comments where id = v_report.target_id;
  elsif v_report.target_type = 'message' then
    select sender_id into v_author_id from messages where id = v_report.target_id;
  else
    select id into v_author_id from profiles where id = v_report.target_id;
  end if;

  if p_status = 'actioned' then
    if v_report.target_type = 'video' then
      update videos set status = 'removed' where id = v_report.target_id;
    elsif v_report.target_type = 'comment' then
      update comments set status = 'removed' where id = v_report.target_id;
    elsif v_report.target_type = 'message' then
      delete from messages where id = v_report.target_id;
    elsif v_author_id is not null then
      perform private.apply_ban(
        v_author_id, true,
        coalesce(nullif(trim(p_author_message), ''), v_report.reason),
        v_admin_id
      );
    end if;
  elsif v_report.target_type = 'video' then
    -- Gardée : une vidéo masquée automatiquement redevient visible.
    update videos set status = 'active' where id = v_report.target_id and status = 'flagged';
  end if;

  if nullif(trim(p_reporter_message), '') is not null then
    insert into notifications (user_id, type, title, body, reference_type, reference_id)
    select distinct r.reporter_id, 'moderation', 'Ton signalement a été traité',
           trim(p_reporter_message), null::text, null::uuid
    from content_reports r
    where r.target_type = v_report.target_type
      and r.target_id = v_report.target_id
      and r.status = 'pending'
      and r.reporter_id is not null
      and r.reporter_id is distinct from v_author_id;
  end if;

  if v_author_id is not null
     and nullif(trim(p_author_message), '') is not null
     and not (p_status = 'actioned' and v_report.target_type = 'profile') then
    insert into notifications (user_id, type, title, body, reference_type, reference_id)
    values (
      v_author_id, 'moderation', 'Message de la modération', trim(p_author_message),
      case when p_status = 'dismissed' and v_report.target_type = 'video' then 'video' end,
      case when p_status = 'dismissed' and v_report.target_type = 'video' then v_report.target_id end
    );
  end if;

  update content_reports
  set status = p_status,
      resolved_by = v_admin_id,
      resolution_note = left(coalesce(p_note, p_author_message), 1000),
      resolved_at = now()
  where target_type = v_report.target_type
    and target_id = v_report.target_id
    and status = 'pending';
  get diagnostics v_closed = row_count;

  return jsonb_build_object('resolved', true, 'reports_closed', v_closed);
end;
$$ language plpgsql security definer set search_path = public;

revoke execute on function admin_resolve_report(uuid, text, text, text, text) from public, anon;
grant execute on function admin_resolve_report(uuid, text, text, text, text) to authenticated;

-- =========================================================================
-- 7. Battles : adversaire aléatoire seulement si le joueur l'accepte, et
--    jamais entre deux joueurs qui se sont bloqués.
-- =========================================================================
create or replace function create_battle(
  p_title text,
  p_rules text,
  p_stake integer,
  p_video_id uuid,
  p_end_date timestamptz,
  p_opponent_username text default null,
  p_random_opponent boolean default false
)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_economy jsonb;
  v_min_stake integer;
  v_max_stake integer;
  v_opponent_id uuid;
  v_new_balance integer;
  v_challenge_id uuid;
  v_creator_name text;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  if p_title is null or char_length(trim(p_title)) < 3 or char_length(p_title) > 80 then
    raise exception 'Le titre doit faire entre 3 et 80 caractères.' using errcode = 'P0001';
  end if;

  if char_length(coalesce(p_rules, '')) > 1000 then
    raise exception 'Les règles sont trop longues (1000 caractères max).' using errcode = 'P0001';
  end if;

  select value into v_economy from app_config where key = 'economy';
  v_min_stake := coalesce((v_economy ->> 'battle_min_stake')::integer, 10);
  v_max_stake := coalesce((v_economy ->> 'battle_max_stake')::integer, 10000);

  if p_stake is null or p_stake < v_min_stake or p_stake > v_max_stake then
    raise exception 'La mise doit être entre % et % Ballons.', v_min_stake, v_max_stake
      using errcode = 'P0001';
  end if;

  if p_end_date < now() + interval '1 hour' or p_end_date > now() + interval '14 days' then
    raise exception 'Une Battle dure entre 1 heure et 14 jours.' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from videos
    where id = p_video_id and user_id = v_user_id and status = 'active'
  ) then
    raise exception 'Choisis une de tes propres vidéos.' using errcode = 'P0001';
  end if;

  if p_random_opponent then
    -- Adversaire aléatoire : un joueur (non banni, avec une vidéo) qui a
    -- accepté les Battles aléatoires (désactivé par défaut pour les
    -- mineurs), et aucun blocage entre les deux.
    select p.id into v_opponent_id
    from profiles p
    join user_safety_settings s on s.user_id = p.id
    where p.id != v_user_id
      and p.role = 'player'
      and not p.is_banned
      and s.allow_random_battles
      and not private.is_blocked_pair(v_user_id, p.id)
      and exists (select 1 from videos v where v.user_id = p.id and v.status = 'active')
    order by random()
    limit 1;

    if v_opponent_id is null then
      raise exception 'Aucun adversaire disponible pour le moment.' using errcode = 'P0001';
    end if;
  elsif p_opponent_username is not null and trim(p_opponent_username) != '' then
    select id into v_opponent_id
    from profiles
    where lower(username) = lower(trim(both '@ ' from p_opponent_username))
      and not is_banned;

    if v_opponent_id is null or private.is_blocked_pair(v_user_id, v_opponent_id) then
      raise exception 'Joueur introuvable : %', p_opponent_username using errcode = 'P0001';
    end if;
    if v_opponent_id = v_user_id then
      raise exception 'Tu ne peux pas te défier toi-même.' using errcode = 'P0001';
    end if;
  end if;

  update profiles set coins = coins - p_stake
  where id = v_user_id and coins >= p_stake
  returning coins, coalesce(display_name, username) into v_new_balance, v_creator_name;

  if v_new_balance is null then
    raise exception 'Solde de Ballons insuffisant.' using errcode = 'P0001';
  end if;

  insert into challenges (
    creator_id, title, description, type, entry_cost, prize_pool,
    opponent_id, max_participants, participants_count, start_date, end_date, status
  ) values (
    v_user_id, trim(p_title), coalesce(p_rules, ''), 'battle', p_stake, p_stake,
    v_opponent_id, 2, 1, now(), p_end_date, 'active'
  )
  returning id into v_challenge_id;

  insert into challenge_participations (challenge_id, user_id, video_id)
  values (v_challenge_id, v_user_id, p_video_id);

  insert into transactions (
    user_id, type, amount, currency, balance_after, reason, reference_type, reference_id
  ) values (
    v_user_id, 'spend', -p_stake, 'coins', v_new_balance, 'join_battle',
    'challenge', v_challenge_id
  );

  if v_opponent_id is not null then
    insert into notifications (user_id, type, title, body, reference_type, reference_id)
    values (
      v_opponent_id, 'battle_invite', 'On te défie ! ⚔️',
      v_creator_name || ' te lance une Battle : « ' || trim(p_title) || ' » (mise : '
        || p_stake || ' Ballons).',
      'challenge', v_challenge_id
    );
  end if;

  return jsonb_build_object('challenge_id', v_challenge_id);
end;
$$ language plpgsql security definer set search_path = public;

revoke execute on function create_battle(text, text, integer, uuid, timestamptz, text, boolean) from public, anon;
grant execute on function create_battle(text, text, integer, uuid, timestamptz, text, boolean) to authenticated;

-- Suggestions d'adversaires : sans les joueurs bloqués.
create or replace function battle_opponent_suggestions(p_query text default null)
returns table (
  id uuid,
  username text,
  display_name text,
  avatar_url text,
  i_follow boolean,
  follows_me boolean
) as $$
declare
  v_user_id uuid := auth.uid();
  v_query text := nullif(lower(trim(both '@ ' from coalesce(p_query, ''))), '');
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  return query
  with related as (
    select f.following_id as pid, true as i_follow, false as follows_me
    from follows f where f.follower_id = v_user_id
    union all
    select f.follower_id, false, true
    from follows f where f.following_id = v_user_id
  ), merged as (
    select pid, bool_or(r.i_follow) as i_follow, bool_or(r.follows_me) as follows_me
    from related r group by pid
  )
  select p.id, p.username, p.display_name, p.avatar_url, m.i_follow, m.follows_me
  from merged m
  join profiles p on p.id = m.pid
  where p.id != v_user_id
    and not p.is_banned
    and not private.is_blocked_pair(v_user_id, p.id)
    and (
      v_query is null
      or lower(p.username) like '%' || v_query || '%'
      or lower(coalesce(p.display_name, '')) like '%' || v_query || '%'
    )
  order by (m.i_follow and m.follows_me) desc, p.username
  limit 50;
end;
$$ language plpgsql stable security definer set search_path = public;

revoke execute on function battle_opponent_suggestions(text) from public, anon;
grant execute on function battle_opponent_suggestions(text) to authenticated;

-- =========================================================================
-- 8. Classements : la ville d'un joueur qui la masque n'apparaît pas, et il
--    n'est pas listé dans le classement de sa ville.
-- =========================================================================
create or replace function get_rankings(
  p_category text,
  p_country text default null,
  p_city text default null,
  p_limit integer default 50
)
returns table (
  id uuid, username text, display_name text, avatar_url text, level text,
  country text, city text, score numeric
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_column text := case p_category
    when 'stars' then 'stars'
    when 'likes' then 'likes_received_count'
    when 'moves' then 'moves_created_count'
    when 'challenges' then 'challenges_won_count'
    when 'iq' then 'iq_technique'
    else null end;
begin
  -- Seules les colonnes prévues sont triables (pas d'injection possible).
  if v_column is null then
    if p_category in ('stars', 'likes_received_count', 'moves_created_count',
                      'challenges_won_count', 'iq_technique', 'iq_creativity',
                      'iq_popularity', 'iq_consistency', 'iq_tactical',
                      'followers_count', 'videos_count', 'form_score') then
      v_column := p_category;
    else
      v_column := 'stars';
    end if;
  end if;

  return query execute format(
    'select p.id, p.username, p.display_name, p.avatar_url, p.level, p.country,
            case when coalesce(s.show_location, false) then p.city end,
            p.%1$I::numeric
     from profiles p
     left join user_safety_settings s on s.user_id = p.id
     where p.role = ''player''
       and not coalesce(p.is_banned, false)
       and not private.is_blocked_pair($4, p.id)
       and ($1::text is null or p.country = $1)
       and ($2::text is null or (p.city = $2 and coalesce(s.show_location, false)))
     order by p.%1$I desc nulls last
     limit $3', v_column)
  using p_country, p_city, greatest(1, least(coalesce(p_limit, 50), 200)), auth.uid();
end;
$$;

revoke execute on function get_rankings(text, text, text, integer) from public;
grant execute on function get_rankings(text, text, text, integer) to anon, authenticated;

-- =========================================================================
-- 9. Achats de Ballons par un mineur
-- =========================================================================
alter table account_consents add column if not exists purchase_consent_at timestamptz;

create table if not exists private.parent_consent_links (
  token uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles (id) on delete cascade,
  kind text not null check (kind in ('purchases')),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  used_at timestamptz,
  decision text check (decision in ('approved', 'declined'))
);

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
        not private.is_minor(p.id)
        or (
          coalesce(private.legal_value('minor_purchases') #>> '{}', 'disabled') = 'parental_consent'
          and c.purchase_consent_at is not null
        )
      )
  );
$$;

revoke execute on function private.can_purchase(uuid) from public, anon, authenticated;

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
    if coalesce(private.legal_value('minor_purchases') #>> '{}', 'disabled') = 'parental_consent' then
      raise exception 'Achat impossible sans l''accord de tes parents.' using errcode = 'P0001';
    end if;
    raise exception 'Les achats de Ballons sont désactivés pour les moins de 18 ans.' using errcode = 'P0001';
  end if;
  if private.is_minor(v_uid) then
    v_limit := private.legal_setting('minor_monthly_limit_cents', 5000);
    select coalesce(sum(pu.amount_cents), 0) into v_spent
    from purchases pu
    where pu.user_id = v_uid and pu.status = 'paid' and pu.paid_at > now() - interval '30 days';
    if v_spent + v_pack.price_cents > v_limit then
      raise exception 'Limite d''achat des mineurs atteinte (% € sur 30 jours).', v_limit / 100
        using errcode = 'P0001';
    end if;
  end if;

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

-- Le mineur crée un lien à usage unique qu'il transmet à son parent.
create or replace function request_parent_purchase_consent()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_token uuid;
begin
  if v_uid is null then
    raise exception 'Connexion requise.' using errcode = '42501';
  end if;
  if coalesce(private.legal_value('minor_purchases') #>> '{}', 'disabled') <> 'parental_consent' then
    raise exception 'Les achats de Ballons sont désactivés pour les moins de 18 ans.' using errcode = 'P0001';
  end if;
  if not private.is_minor(v_uid) then
    raise exception 'Action invalide.' using errcode = 'P0001';
  end if;
  delete from private.parent_consent_links where user_id = v_uid and used_at is null;
  insert into private.parent_consent_links (user_id, kind, expires_at)
  values (v_uid, 'purchases',
          now() + make_interval(days => coalesce((private.legal_value('parent_link_valid_days') #>> '{}')::int, 7)))
  returning token into v_token;
  return jsonb_build_object('token', v_token);
end;
$$;

-- Page ouverte par le parent (sans compte) : ce qu'on lui demande.
create or replace function get_parent_consent_request(p_token uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'kind', l.kind,
    'username', p.username,
    'monthly_limit_cents', private.legal_setting('minor_monthly_limit_cents', 5000),
    'valid', l.used_at is null and l.expires_at > now()
  )
  from private.parent_consent_links l join profiles p on p.id = l.user_id
  where l.token = p_token;
$$;

create or replace function answer_parent_consent(p_token uuid, p_approve boolean)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_link private.parent_consent_links;
begin
  select * into v_link from private.parent_consent_links
  where token = p_token and used_at is null and expires_at > now()
  for update;
  if v_link.token is null then
    raise exception 'Lien invalide ou déjà utilisé.' using errcode = 'P0001';
  end if;
  update private.parent_consent_links
  set used_at = now(), decision = case when p_approve then 'approved' else 'declined' end
  where token = p_token;
  if p_approve then
    insert into account_consents (user_id, terms_version, is_minor, purchase_consent_at)
    values (v_link.user_id, private.terms_version(), true, now())
    on conflict (user_id) do update set purchase_consent_at = now();
  else
    update account_consents set purchase_consent_at = null where user_id = v_link.user_id;
  end if;
  insert into notifications (user_id, type, title, body)
  values (
    v_link.user_id, 'moderation',
    case when p_approve then 'Achats autorisés par ton parent' else 'Achats refusés par ton parent' end,
    case when p_approve then 'Ton parent a autorisé les achats de Ballons.'
         else 'Ton parent n''a pas autorisé les achats de Ballons.' end
  );
  return jsonb_build_object('approved', p_approve);
end;
$$;

revoke execute on function request_parent_purchase_consent() from public, anon;
grant execute on function request_parent_purchase_consent() to authenticated;
revoke execute on function get_parent_consent_request(uuid) from public;
grant execute on function get_parent_consent_request(uuid) to anon, authenticated;
revoke execute on function answer_parent_consent(uuid, boolean) from public;
grant execute on function answer_parent_consent(uuid, boolean) to anon, authenticated;

-- =========================================================================
-- 10. Séries quotidiennes sans perte punitive
-- =========================================================================
-- Avec « séries douces » (par défaut pour les mineurs), un jour manqué ne
-- remet pas la série à zéro : elle compte les jours joués et reprend où
-- elle en était. Aucun Ballon n'est jamais lié à la série.
create or replace function private.gentle_streak()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.last_login_date is distinct from old.last_login_date
     and new.streak_days = 1
     and coalesce(old.streak_days, 0) >= 1
     and coalesce((private.safety(new.id)).gentle_streaks, true) then
    new.streak_days := old.streak_days + 1;
    if new.streak_days in (7, 30) then
      insert into user_badges (user_id, badge_id)
      select new.id, b.id from badges b
      where b.code = case new.streak_days when 7 then 'assidu_7' else 'assidu_30' end
      on conflict (user_id, badge_id) do nothing;
    end if;
  end if;
  return new;
end;
$$;

revoke execute on function private.gentle_streak() from public, anon, authenticated;

drop trigger if exists trigger_gentle_streak on profiles;
create trigger trigger_gentle_streak
before update of streak_days on profiles
for each row execute function private.gentle_streak();

-- =========================================================================
-- 11. Droit à l'image à la publication d'une vidéo
-- =========================================================================
alter table videos add column if not exists rights_confirmed_at timestamptz;
grant insert (rights_confirmed_at) on videos to authenticated;

create or replace function private.check_video_rights()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.rights_confirmed_at is not null then
    new.rights_confirmed_at := now();
  elsif coalesce((private.legal_value('strict_mode') #>> '{}')::boolean, true) then
    raise exception 'Confirme que tu as le droit de publier cette vidéo.' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

revoke execute on function private.check_video_rights() from public, anon, authenticated;

drop trigger if exists trigger_check_video_rights on videos;
create trigger trigger_check_video_rights
before insert on videos
for each row execute function private.check_video_rights();

-- =========================================================================
-- 12. Ce que l'appli sait de l'utilisateur connecté (réglages, âge, achats)
-- =========================================================================
create or replace function get_my_safety()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_s user_safety_settings;
  v_p profiles;
begin
  if v_uid is null then
    raise exception 'Connexion requise.' using errcode = '42501';
  end if;
  select * into v_p from profiles where id = v_uid;
  v_s := private.safety(v_uid);
  return jsonb_build_object(
    'is_minor', private.is_minor(v_uid),
    'age_known', v_p.birth_date is not null,
    'role', v_p.role,
    'profile_visibility', coalesce(v_s.profile_visibility, 'limited'),
    'dm_from', coalesce(v_s.dm_from, 'mutual'),
    'allow_random_battles', coalesce(v_s.allow_random_battles, false),
    'show_location', coalesce(v_s.show_location, false),
    'gentle_streaks', coalesce(v_s.gentle_streaks, true),
    'show_streaks', coalesce(v_s.show_streaks, false),
    'show_countdowns', coalesce(v_s.show_countdowns, false),
    'break_reminder_minutes', coalesce(v_s.break_reminder_minutes, 45),
    'minor_purchases', coalesce(private.legal_value('minor_purchases') #>> '{}', 'disabled'),
    'can_purchase', private.can_purchase(v_uid),
    'purchase_consent_at', (select purchase_consent_at from account_consents where user_id = v_uid),
    'minor_monthly_limit_cents', private.legal_setting('minor_monthly_limit_cents', 5000)
  );
end;
$$;

revoke execute on function get_my_safety() from public, anon;
grant execute on function get_my_safety() to authenticated;
revoke execute on function update_my_safety_settings(jsonb) from public, anon;
grant execute on function update_my_safety_settings(jsonb) to authenticated;

-- -------------------------------------------------------------------------
-- 13. Recherche des recruteurs : la ville d'un joueur n'apparaît que s'il
--     a choisi « Montrer ma ville » (désactivé par défaut pour les moins de
--     18 ans) ; les joueurs bloqués n'apparaissent pas. Âge du mineur par
--     les règles configurables (`private.is_minor`).
-- -------------------------------------------------------------------------
create or replace function scout_search_players(
  p_query text default null,
  p_position text default null,
  p_country text default null
)
returns table (
  id uuid,
  username text,
  display_name text,
  avatar_url text,
  country text,
  city text,
  "position" text,
  is_minor boolean,
  stars integer,
  level text,
  followers_count integer
) as $$
begin
  if auth.uid() is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  if not exists (select 1 from profiles where profiles.id = auth.uid() and role = 'scout') then
    raise exception 'Réservé aux comptes recruteurs.' using errcode = 'P0001';
  end if;

  return query
  select
    p.id, p.username, p.display_name, p.avatar_url, p.country,
    case when coalesce((private.safety(p.id)).show_location, false) then p.city end,
    p.position,
    private.is_minor(p.id),
    p.stars, p.level, p.followers_count
  from profiles p
  where p.role = 'player'
    and not private.is_blocked_pair(auth.uid(), p.id)
    and (p_query is null or p_query = '' or p.username ilike '%' || p_query || '%')
    and (p_position is null or p.position = p_position)
    and (p_country is null or p.country = p_country)
  order by p.stars desc
  limit 30;
end;
$$ language plpgsql stable security definer set search_path = public;

grant execute on function scout_search_players(text, text, text) to authenticated;
