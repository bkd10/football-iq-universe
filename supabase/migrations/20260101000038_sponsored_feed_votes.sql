-- Défi sponsorisé dans le fil + bouton Voter sur chaque vidéo de défi
-- (demande de Tom, 19/11/2026). Mesures mises en place, à faire valider par
-- un avocat britannique : ce fichier n'est pas un avis juridique.
--
--   1. Réglage du fil : une carte « Sponsorisé » toutes les N vidéos
--      (app_config.sponsored_feed, modifiable dans le panneau admin).
--   2. Défis sponsorisés montrés dans le fil : la même liste pour tout le
--      monde, sans aucune donnée du joueur (âge, pays, ville...) : aucun
--      ciblage. Le sponsor n'a ni compte ni accès aux données des joueurs.
--   3. Brouillons de défis sponsorisés (table à part, invisible des
--      joueurs) : le défi Passe D est préparé ici, jamais activé tout seul.
--      L'activation refuse tant qu'il manque un champ ou que le sponsor
--      n'est pas confirmé.
--   4. Votes, côté serveur : un vote par joueur et par défi, pas pour soi,
--      seulement entre le début et la fin, compte banni ou non connecté
--      refusé, participant sans vidéo refusé, limite de débit.
--   5. Détection simple d'abus (même appareil / même réseau pour plusieurs
--      comptes, compte tout récent, rafale de votes) : signalée dans le
--      panneau admin, qui peut annuler le vote.
--   6. Infos de vote par vidéo (pour le bouton Voter partout dans l'appli).
--
-- Compatible avec l'appli déjà en ligne : vote_for_participant garde ses
-- deux paramètres (le troisième, l'appareil, est facultatif).

create schema if not exists private;

-- -------------------------------------------------------------------------
-- 1. Réglages
-- -------------------------------------------------------------------------
insert into app_config (key, value, description) values
  ('sponsored_feed',
   '{"enabled": true, "every_n": 6}'::jsonb,
   'Défi sponsorisé dans le fil : une carte toutes les every_n vidéos (Pour toi et Tendances).'),
  ('vote_rules',
   '{"per_minute": 10, "per_day": 100, "new_account_minutes": 30, "same_device_accounts": 3, "same_network_accounts": 5, "burst_votes": 15, "burst_minutes": 10}'::jsonb,
   'Votes : limites par compte et seuils de détection d''abus (signalés dans le panneau admin).')
on conflict (key) do nothing;

create or replace function private.config_int(p_key text, p_field text, p_default integer)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select case when jsonb_typeof(value -> p_field) = 'number' then (value ->> p_field)::integer end
     from app_config where key = p_key),
    p_default
  );
$$;

revoke all on function private.config_int(text, text, integer) from public, anon, authenticated;

-- -------------------------------------------------------------------------
-- 2. Champs des défis sponsorisés
-- -------------------------------------------------------------------------
-- Récompense en Stars du gagnant (au lieu des 100 habituelles ; null = 100).
alter table challenges add column if not exists reward_stars integer
  check (reward_stars is null or reward_stars between 0 and 100000);
-- Le défi peut apparaître dans le fil (défis sponsorisés seulement).
alter table challenges add column if not exists show_in_feed boolean not null default false;

-- Le gagnant reçoit 100 Stars dans resolve_expired_challenges ; si le défi
-- promet plus, on verse la différence au moment où il se termine.
create or replace function private.award_reward_stars()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_extra integer;
  v_stars integer;
begin
  if new.status = 'completed' and old.status is distinct from 'completed'
     and new.winner_id is not null and coalesce(new.reward_stars, 100) > 100 then
    v_extra := new.reward_stars - 100;
    update profiles set stars = stars + v_extra where id = new.winner_id
    returning stars into v_stars;
    if v_stars is not null then
      insert into transactions (
        user_id, type, amount, currency, balance_after, reason, reference_type, reference_id
      ) values (
        new.winner_id, 'earn', v_extra, 'stars', v_stars, 'win_challenge', 'challenge', new.id
      );
    end if;
  end if;
  return null;
end;
$$;

revoke all on function private.award_reward_stars() from public, anon, authenticated;

drop trigger if exists trigger_award_reward_stars on challenges;
create trigger trigger_award_reward_stars
after update of status on challenges
for each row execute function private.award_reward_stars();

-- -------------------------------------------------------------------------
-- 3. Défis sponsorisés affichés dans le fil
-- -------------------------------------------------------------------------
-- Aucune donnée du joueur n'est lue pour choisir les défis (pas de ciblage) ;
-- seul « déjà inscrit ? » est calculé pour le bouton.
create or replace function get_feed_sponsored_challenges()
returns table (
  id uuid,
  title text,
  description text,
  sponsor_name text,
  sponsor_logo_url text,
  start_date timestamptz,
  end_date timestamptz,
  participants_count integer,
  entry_cost integer,
  reward_stars integer,
  prize_description text,
  has_joined boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select c.id, c.title, c.description, c.sponsor_name, c.sponsor_logo_url,
         c.start_date, c.end_date, coalesce(c.participants_count, 0),
         coalesce(c.entry_cost, 0), coalesce(c.reward_stars, 100), c.prize_description,
         exists (
           select 1 from challenge_participations p
           where p.challenge_id = c.id and p.user_id = auth.uid()
         )
  from challenges c
  where c.type = 'sponsored'
    and c.show_in_feed
    and c.status = 'active'
    and c.end_date > now()
    and coalesce((select (value ->> 'enabled')::boolean from app_config where key = 'sponsored_feed'), true)
  order by c.end_date asc
  limit 5;
$$;

revoke execute on function get_feed_sponsored_challenges() from public;
grant execute on function get_feed_sponsored_challenges() to anon, authenticated;

-- -------------------------------------------------------------------------
-- 4. Brouillons de défis sponsorisés (panneau admin uniquement)
-- -------------------------------------------------------------------------
create table if not exists sponsored_challenge_drafts (
  id uuid primary key default gen_random_uuid(),
  title text,
  description text,
  sponsor_name text not null default 'Passe D',
  sponsor_logo_url text,
  sponsor_confirmed boolean not null default false,
  start_date timestamptz,
  end_date timestamptz,
  entry_cost integer check (entry_cost is null or entry_cost between 0 and 10000),
  reward_stars integer check (reward_stars is null or reward_stars between 0 and 100000),
  prize_description text,
  category text,
  challenge_id uuid references challenges (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Aucun accès direct (ni lecture ni écriture) : seulement les fonctions admin.
alter table sponsored_challenge_drafts enable row level security;
revoke all on sponsored_challenge_drafts from anon, authenticated;

-- Le défi Passe D, préparé et NON activé. Sponsor non confirmé.
insert into sponsored_challenge_drafts (sponsor_name, sponsor_confirmed)
select 'Passe D', false
where not exists (select 1 from sponsored_challenge_drafts where sponsor_name = 'Passe D');

-- Ce qui manque pour pouvoir activer un brouillon.
create or replace function private.sponsored_draft_missing(d sponsored_challenge_drafts)
returns text[]
language plpgsql
stable
set search_path = public
as $$
declare
  v text[] := '{}';
begin
  if d.title is null or char_length(trim(d.title)) < 3 then v := v || 'titre'; end if;
  if d.description is null or char_length(trim(d.description)) < 10 then v := v || 'description'; end if;
  if d.sponsor_logo_url is null or d.sponsor_logo_url !~ '^https://' then v := v || 'logo du sponsor'; end if;
  if d.start_date is null then v := v || 'date de début'; end if;
  if d.end_date is null then v := v || 'date de fin'; end if;
  if d.start_date is not null and d.end_date is not null and d.end_date <= d.start_date then
    v := v || 'fin après le début';
  end if;
  if d.end_date is not null and d.end_date <= now() then v := v || 'fin dans le futur'; end if;
  if d.entry_cost is null then v := v || 'coût d''entrée'; end if;
  if d.reward_stars is null then v := v || 'récompense en Stars'; end if;
  if not d.sponsor_confirmed then v := v || 'sponsor confirmé'; end if;
  return v;
end;
$$;

revoke all on function private.sponsored_draft_missing(sponsored_challenge_drafts) from public, anon, authenticated;

create or replace function admin_list_sponsored_drafts()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform private.require_admin();
  return coalesce((
    select jsonb_agg(
      to_jsonb(d) || jsonb_build_object(
        'missing', to_jsonb(private.sponsored_draft_missing(d)),
        'challenge_status', (select c.status from challenges c where c.id = d.challenge_id)
      ) order by d.created_at)
    from sponsored_challenge_drafts d
  ), '[]'::jsonb);
end;
$$;

-- Crée (p_id null) ou modifie un brouillon. Les champs absents de p_fields
-- ne changent pas ; une valeur null efface le champ.
create or replace function admin_save_sponsored_draft(p_id uuid, p_fields jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid := p_id;
  d sponsored_challenge_drafts;
begin
  perform private.require_admin();
  if v_id is null then
    insert into sponsored_challenge_drafts default values returning id into v_id;
  end if;
  select * into d from sponsored_challenge_drafts where id = v_id for update;
  if d.id is null then
    raise exception 'Brouillon introuvable.' using errcode = 'P0001';
  end if;
  if d.challenge_id is not null then
    raise exception 'Ce défi est déjà activé : il ne se modifie plus ici.' using errcode = 'P0001';
  end if;

  update sponsored_challenge_drafts set
    title = case when p_fields ? 'title' then left(nullif(trim(p_fields ->> 'title'), ''), 80) else title end,
    description = case when p_fields ? 'description' then left(nullif(trim(p_fields ->> 'description'), ''), 1000) else description end,
    sponsor_name = case when p_fields ? 'sponsor_name' then coalesce(left(nullif(trim(p_fields ->> 'sponsor_name'), ''), 60), sponsor_name) else sponsor_name end,
    sponsor_logo_url = case when p_fields ? 'sponsor_logo_url' then left(nullif(trim(p_fields ->> 'sponsor_logo_url'), ''), 500) else sponsor_logo_url end,
    sponsor_confirmed = case when p_fields ? 'sponsor_confirmed' then coalesce((p_fields ->> 'sponsor_confirmed')::boolean, false) else sponsor_confirmed end,
    start_date = case when p_fields ? 'start_date' then (p_fields ->> 'start_date')::timestamptz else start_date end,
    end_date = case when p_fields ? 'end_date' then (p_fields ->> 'end_date')::timestamptz else end_date end,
    entry_cost = case when p_fields ? 'entry_cost' then (p_fields ->> 'entry_cost')::integer else entry_cost end,
    reward_stars = case when p_fields ? 'reward_stars' then (p_fields ->> 'reward_stars')::integer else reward_stars end,
    prize_description = case when p_fields ? 'prize_description' then left(nullif(trim(p_fields ->> 'prize_description'), ''), 500) else prize_description end,
    category = case when p_fields ? 'category' then nullif(trim(p_fields ->> 'category'), '') else category end,
    updated_at = now()
  where id = v_id
  returning * into d;

  return to_jsonb(d) || jsonb_build_object('missing', to_jsonb(private.sponsored_draft_missing(d)));
end;
$$;

-- Active un brouillon : crée le vrai défi (type sponsorisé, dans le fil).
-- Refuse tant qu'il manque quelque chose, sponsor confirmé compris.
create or replace function admin_activate_sponsored_draft(p_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin uuid := private.require_admin();
  d sponsored_challenge_drafts;
  v_missing text[];
  v_challenge_id uuid;
begin
  select * into d from sponsored_challenge_drafts where id = p_id for update;
  if d.id is null then
    raise exception 'Brouillon introuvable.' using errcode = 'P0001';
  end if;
  if d.challenge_id is not null then
    raise exception 'Ce défi est déjà activé.' using errcode = 'P0001';
  end if;
  v_missing := private.sponsored_draft_missing(d);
  if array_length(v_missing, 1) > 0 then
    raise exception 'Impossible d''activer : il manque %.', array_to_string(v_missing, ', ')
      using errcode = 'P0001';
  end if;
  -- Un vrai lot (prix réel) ne s'achète jamais : entrée gratuite.
  if d.prize_description is not null and d.entry_cost > 0 then
    raise exception 'Un défi avec un lot réel doit être gratuit (coût d''entrée 0).' using errcode = 'P0001';
  end if;

  insert into challenges (
    creator_id, title, description, type, category, entry_cost, prize_pool, prize_currency,
    prize_description, sponsor_name, sponsor_logo_url, is_official, start_date, end_date,
    status, reward_stars, show_in_feed
  ) values (
    v_admin, d.title, d.description, 'sponsored', d.category, d.entry_cost, 0,
    case when d.prize_description is not null then 'real' else 'coins' end,
    d.prize_description, d.sponsor_name, d.sponsor_logo_url, false, d.start_date, d.end_date,
    'active', d.reward_stars, true
  )
  returning id into v_challenge_id;

  update sponsored_challenge_drafts set challenge_id = v_challenge_id, updated_at = now()
  where id = d.id;

  return jsonb_build_object('challenge_id', v_challenge_id);
end;
$$;

-- Retirer un défi sponsorisé du fil (sans le supprimer).
create or replace function admin_set_challenge_in_feed(p_challenge_id uuid, p_show boolean)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform private.require_admin();
  update challenges set show_in_feed = coalesce(p_show, false)
  where id = p_challenge_id and type = 'sponsored';
  if not found then
    raise exception 'Défi sponsorisé introuvable.' using errcode = 'P0001';
  end if;
  return jsonb_build_object('show_in_feed', coalesce(p_show, false));
end;
$$;

-- Fréquence de la carte dans le fil.
create or replace function admin_set_sponsored_feed(p_every_n integer, p_enabled boolean default true)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v jsonb;
begin
  perform private.require_admin();
  if p_every_n is null or p_every_n < 2 or p_every_n > 50 then
    raise exception 'La fréquence doit être entre 2 et 50 vidéos.' using errcode = 'P0001';
  end if;
  v := jsonb_build_object('enabled', coalesce(p_enabled, true), 'every_n', p_every_n);
  insert into app_config (key, value, description)
  values ('sponsored_feed', v, 'Défi sponsorisé dans le fil : une carte toutes les every_n vidéos (Pour toi et Tendances).')
  on conflict (key) do update set value = excluded.value;
  return v;
end;
$$;

-- -------------------------------------------------------------------------
-- 5. Votes
-- -------------------------------------------------------------------------
-- Empreintes techniques du vote (jamais lisibles par les joueurs) : hachées,
-- pour repérer plusieurs comptes sur un même appareil ou un même réseau.
create table if not exists private.vote_fingerprints (
  vote_id uuid primary key references public.challenge_votes (id) on delete cascade,
  challenge_id uuid not null,
  voter_id uuid,
  device_hash text,
  network_hash text,
  created_at timestamptz not null default now()
);
create index if not exists idx_vote_fp_device on private.vote_fingerprints (challenge_id, device_hash);
create index if not exists idx_vote_fp_network on private.vote_fingerprints (challenge_id, network_hash);
create index if not exists idx_vote_fp_voter on private.vote_fingerprints (voter_id, created_at);

-- Alertes d'abus, vues dans le panneau admin.
create table if not exists vote_abuse_flags (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references challenges (id) on delete cascade,
  vote_id uuid references challenge_votes (id) on delete set null,
  voter_id uuid references profiles (id) on delete set null,
  reason text not null check (reason in ('same_device', 'same_network', 'new_account', 'burst')),
  details jsonb not null default '{}'::jsonb,
  status text not null default 'pending' check (status in ('pending', 'ignored', 'vote_removed')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid
);
create index if not exists idx_vote_flags_status on vote_abuse_flags (status, created_at desc);
alter table vote_abuse_flags enable row level security;
revoke all on vote_abuse_flags from anon, authenticated;

create or replace function private.request_network_hash()
returns text
language plpgsql
stable
as $$
declare
  v_headers jsonb;
  v_ip text;
begin
  begin
    v_headers := nullif(current_setting('request.headers', true), '')::jsonb;
  exception when others then
    return null;
  end;
  v_ip := coalesce(v_headers ->> 'cf-connecting-ip', split_part(v_headers ->> 'x-forwarded-for', ',', 1));
  if v_ip is null or trim(v_ip) = '' then
    return null;
  end if;
  return encode(sha256(convert_to('fiq-net:' || trim(v_ip), 'UTF8')), 'hex');
exception when others then
  return null;
end;
$$;

revoke all on function private.request_network_hash() from public, anon, authenticated;

-- Remplace la version de 0024 (mêmes règles, plus : compte banni explicite,
-- participant sans vidéo, limite de débit, empreintes et alertes d'abus).
drop function if exists vote_for_participant(uuid, uuid);
create or replace function vote_for_participant(
  p_challenge_id uuid,
  p_participant_id uuid,
  p_device_id text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user_id uuid := auth.uid();
  v_challenge record;
  v_voter record;
  v_has_video boolean;
  v_vote_id uuid;
  v_votes integer;
  v_minute integer;
  v_day integer;
  v_device text;
  v_network text;
  v_n integer;
begin
  if v_user_id is null then
    raise exception 'Connecte-toi pour voter.' using errcode = '28000';
  end if;

  select p.id, p.is_banned, p.created_at into v_voter from profiles p where p.id = v_user_id;
  if v_voter.id is null then
    raise exception 'Compte introuvable.' using errcode = 'P0001';
  end if;
  if coalesce(v_voter.is_banned, false) then
    raise exception 'Ton compte est suspendu : tu ne peux pas voter.' using errcode = 'P0001';
  end if;

  if v_user_id = p_participant_id then
    raise exception 'Tu ne peux pas voter pour toi-même.' using errcode = 'P0001';
  end if;

  select * into v_challenge from challenges where id = p_challenge_id;
  if v_challenge.id is null or v_challenge.status = 'draft' then
    raise exception 'Défi introuvable.' using errcode = 'P0001';
  end if;

  if now() < v_challenge.start_date then
    raise exception 'Les votes ouvrent le %.',
      to_char(v_challenge.start_date at time zone 'Europe/London', 'DD/MM/YYYY HH24:MI')
      using errcode = 'P0001';
  end if;

  if v_challenge.status not in ('active', 'voting') or now() > v_challenge.end_date then
    raise exception 'Les votes de ce défi sont terminés.' using errcode = 'P0001';
  end if;

  if v_challenge.type = 'battle' then
    if v_challenge.participants_count < 2 then
      raise exception 'Les votes ouvrent quand l''adversaire a relevé la Battle.'
        using errcode = 'P0001';
    end if;
    if exists (
      select 1 from challenge_participations
      where challenge_id = p_challenge_id and user_id = v_user_id
    ) then
      raise exception 'Les joueurs de la Battle ne votent pas.' using errcode = 'P0001';
    end if;
  end if;

  -- Seuls les vrais joueurs votent : au moins une vidéo publiée, ou un
  -- compte de plus de 24 h (règle de 0024, inchangée).
  v_has_video := exists (select 1 from videos v where v.user_id = v_user_id and v.status = 'active');
  if not v_has_video and now() - v_voter.created_at < interval '24 hours' then
    raise exception 'Publie d''abord une vidéo pour pouvoir voter (ou attends 24 h).'
      using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from challenge_participations
    where challenge_id = p_challenge_id and user_id = p_participant_id
  ) then
    raise exception 'Ce participant n''existe pas dans ce défi.' using errcode = 'P0001';
  end if;

  -- Participant qui n'a pas encore envoyé sa vidéo (inscription d'abord,
  -- vidéo ensuite) ou vidéo retirée par la modération.
  if not exists (
    select 1 from challenge_participations cp
    join videos v on v.id = cp.video_id
    where cp.challenge_id = p_challenge_id and cp.user_id = p_participant_id
      and v.status = 'active'
  ) then
    raise exception 'Cette vidéo ne peut pas recevoir de votes pour l''instant.' using errcode = 'P0001';
  end if;

  if exists (select 1 from challenge_votes where challenge_id = p_challenge_id and voter_id = v_user_id) then
    raise exception 'Tu as déjà voté dans ce défi.' using errcode = 'P0001';
  end if;

  -- Limite de débit (par compte).
  insert into private.rate_limit_hits as h (user_id, action, bucket, hits)
  values (v_user_id, 'vote:min', date_trunc('minute', now()), 1)
  on conflict (user_id, action, bucket) do update set hits = h.hits + 1
  returning hits into v_minute;
  if v_minute > private.config_int('vote_rules', 'per_minute', 10) then
    raise exception 'Trop de votes en peu de temps. Réessaie dans une minute.' using errcode = 'P0001';
  end if;
  insert into private.rate_limit_hits as h (user_id, action, bucket, hits)
  values (v_user_id, 'vote:day', date_trunc('day', now()), 1)
  on conflict (user_id, action, bucket) do update set hits = h.hits + 1
  returning hits into v_day;
  if v_day > private.config_int('vote_rules', 'per_day', 100) then
    raise exception 'Limite de votes du jour atteinte. Réessaie demain.' using errcode = 'P0001';
  end if;

  insert into challenge_votes (challenge_id, voter_id, participant_id)
  values (p_challenge_id, v_user_id, p_participant_id)
  returning id into v_vote_id;

  update challenge_participations
  set votes_count = votes_count + 1
  where challenge_id = p_challenge_id and user_id = p_participant_id
  returning votes_count into v_votes;

  -- Empreintes + détection d'abus (n'empêche pas le vote : l'admin décide).
  v_device := case
    when p_device_id is not null and char_length(p_device_id) between 8 and 128
      then encode(sha256(convert_to('fiq-dev:' || p_device_id, 'UTF8')), 'hex')
  end;
  v_network := private.request_network_hash();
  insert into private.vote_fingerprints (vote_id, challenge_id, voter_id, device_hash, network_hash)
  values (v_vote_id, p_challenge_id, v_user_id, v_device, v_network);

  if v_device is not null then
    select count(distinct voter_id) into v_n from private.vote_fingerprints
    where challenge_id = p_challenge_id and device_hash = v_device;
    if v_n >= private.config_int('vote_rules', 'same_device_accounts', 3) then
      insert into vote_abuse_flags (challenge_id, vote_id, voter_id, reason, details)
      values (p_challenge_id, v_vote_id, v_user_id, 'same_device', jsonb_build_object('accounts', v_n));
    end if;
  end if;

  if v_network is not null then
    select count(distinct voter_id) into v_n from private.vote_fingerprints
    where challenge_id = p_challenge_id and network_hash = v_network;
    if v_n >= private.config_int('vote_rules', 'same_network_accounts', 5) then
      insert into vote_abuse_flags (challenge_id, vote_id, voter_id, reason, details)
      values (p_challenge_id, v_vote_id, v_user_id, 'same_network', jsonb_build_object('accounts', v_n));
    end if;
  end if;

  if now() - v_voter.created_at < make_interval(mins => private.config_int('vote_rules', 'new_account_minutes', 30)) then
    insert into vote_abuse_flags (challenge_id, vote_id, voter_id, reason, details)
    values (p_challenge_id, v_vote_id, v_user_id, 'new_account',
            jsonb_build_object('account_age_minutes', floor(extract(epoch from now() - v_voter.created_at) / 60)));
  end if;

  select count(*) into v_n from private.vote_fingerprints
  where voter_id = v_user_id
    and created_at > now() - make_interval(mins => private.config_int('vote_rules', 'burst_minutes', 10));
  if v_n >= private.config_int('vote_rules', 'burst_votes', 15) then
    insert into vote_abuse_flags (challenge_id, vote_id, voter_id, reason, details)
    values (p_challenge_id, v_vote_id, v_user_id, 'burst', jsonb_build_object('votes', v_n));
  end if;

  return jsonb_build_object('voted', true, 'votes_count', v_votes);
exception
  when unique_violation then
    raise exception 'Tu as déjà voté dans ce défi.' using errcode = 'P0001';
end;
$$;

revoke execute on function vote_for_participant(uuid, uuid, text) from public, anon;
grant execute on function vote_for_participant(uuid, uuid, text) to authenticated;

-- Pour le bouton Voter : les défis en cours de chaque vidéo. Une vidéo hors
-- défi ne renvoie rien (pas de bouton).
create or replace function get_video_challenge_entries(p_video_ids uuid[])
returns table (
  video_id uuid,
  challenge_id uuid,
  challenge_title text,
  challenge_type text,
  is_sponsored boolean,
  participant_id uuid,
  votes_count integer,
  start_date timestamptz,
  end_date timestamptz,
  battle_ready boolean,
  my_vote_participant_id uuid,
  is_mine boolean,
  i_am_battle_player boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select cp.video_id, c.id, c.title, c.type, c.type = 'sponsored', cp.user_id,
         coalesce(cp.votes_count, 0), c.start_date, c.end_date,
         c.type <> 'battle' or coalesce(c.participants_count, 0) >= 2,
         (select cv.participant_id from challenge_votes cv
           where cv.challenge_id = c.id and cv.voter_id = auth.uid() limit 1),
         cp.user_id = auth.uid(),
         c.type = 'battle' and exists (
           select 1 from challenge_participations me
           where me.challenge_id = c.id and me.user_id = auth.uid()
         )
  from challenge_participations cp
  join challenges c on c.id = cp.challenge_id
  where cp.video_id = any ((coalesce(p_video_ids, '{}'::uuid[]))[1:100])
    and c.status in ('active', 'voting')
  order by cp.video_id, c.end_date asc;
$$;

revoke execute on function get_video_challenge_entries(uuid[]) from public;
grant execute on function get_video_challenge_entries(uuid[]) to anon, authenticated;

-- -------------------------------------------------------------------------
-- 6. Panneau admin : alertes de vote
-- -------------------------------------------------------------------------
create or replace function admin_list_vote_flags(p_status text default 'pending', p_limit integer default 100)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform private.require_admin();
  return coalesce((
    select jsonb_agg(row_to_json(x) order by x.created_at desc)
    from (
      select f.id, f.reason, f.details, f.status, f.created_at, f.resolved_at,
             f.challenge_id, c.title as challenge_title,
             f.voter_id, p.username as voter_username, p.created_at as voter_created_at,
             f.vote_id,
             (select pp.username from challenge_votes v join profiles pp on pp.id = v.participant_id
               where v.id = f.vote_id) as voted_for_username
      from vote_abuse_flags f
      join challenges c on c.id = f.challenge_id
      left join profiles p on p.id = f.voter_id
      where p_status is null or p_status = 'all' or f.status = p_status
      order by f.created_at desc
      limit least(greatest(coalesce(p_limit, 100), 1), 500)
    ) x
  ), '[]'::jsonb);
end;
$$;

-- p_action : 'ignore' (vote gardé) ou 'remove_vote' (vote annulé, compteur
-- corrigé ; les autres alertes du même vote sont closes aussi).
create or replace function admin_resolve_vote_flag(p_flag_id uuid, p_action text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin uuid := private.require_admin();
  f vote_abuse_flags;
  v_vote challenge_votes;
begin
  if p_action not in ('ignore', 'remove_vote') then
    raise exception 'Action inconnue.' using errcode = 'P0001';
  end if;
  select * into f from vote_abuse_flags where id = p_flag_id for update;
  if f.id is null then
    raise exception 'Alerte introuvable.' using errcode = 'P0001';
  end if;

  if p_action = 'remove_vote' and f.vote_id is not null then
    update vote_abuse_flags
    set status = 'vote_removed', resolved_at = now(), resolved_by = v_admin
    where (vote_id = f.vote_id or id = f.id) and status = 'pending';
    select * into v_vote from challenge_votes where id = f.vote_id;
    if v_vote.id is not null then
      update challenge_participations set votes_count = greatest(votes_count - 1, 0)
      where challenge_id = v_vote.challenge_id and user_id = v_vote.participant_id;
      delete from challenge_votes where id = v_vote.id;
    end if;
  else
    update vote_abuse_flags
    set status = case when p_action = 'remove_vote' then 'vote_removed' else 'ignored' end,
        resolved_at = now(), resolved_by = v_admin
    where id = f.id;
  end if;

  return jsonb_build_object('status', case when p_action = 'remove_vote' then 'vote_removed' else 'ignored' end);
end;
$$;

-- Le tableau de bord admin compte aussi les alertes de vote.
create or replace function admin_pending_vote_flags_count()
returns integer
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform private.require_admin();
  return (select count(*) from vote_abuse_flags where status = 'pending');
end;
$$;

-- -------------------------------------------------------------------------
-- Droits
-- -------------------------------------------------------------------------
revoke execute on function admin_list_sponsored_drafts() from public, anon;
revoke execute on function admin_save_sponsored_draft(uuid, jsonb) from public, anon;
revoke execute on function admin_activate_sponsored_draft(uuid) from public, anon;
revoke execute on function admin_set_challenge_in_feed(uuid, boolean) from public, anon;
revoke execute on function admin_set_sponsored_feed(integer, boolean) from public, anon;
revoke execute on function admin_list_vote_flags(text, integer) from public, anon;
revoke execute on function admin_resolve_vote_flag(uuid, text) from public, anon;
revoke execute on function admin_pending_vote_flags_count() from public, anon;

grant execute on function admin_list_sponsored_drafts() to authenticated;
grant execute on function admin_save_sponsored_draft(uuid, jsonb) to authenticated;
grant execute on function admin_activate_sponsored_draft(uuid) to authenticated;
grant execute on function admin_set_challenge_in_feed(uuid, boolean) to authenticated;
grant execute on function admin_set_sponsored_feed(integer, boolean) to authenticated;
grant execute on function admin_list_vote_flags(text, integer) to authenticated;
grant execute on function admin_resolve_vote_flag(uuid, text) to authenticated;
grant execute on function admin_pending_vote_flags_count() to authenticated;
