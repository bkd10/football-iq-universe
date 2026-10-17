-- Football IQ Universe : installation complète de la base (toutes les migrations, dans l'ordre).
-- À coller UNE SEULE FOIS dans Supabase > SQL Editor, sur un projet vide, puis Run.
-- Généré à partir de supabase/migrations/ (ne pas modifier à la main).


-- ===================== 20260101000000_initial_schema.sql =====================
-- Football IQ Universe — Schéma initial
-- Voir PARTIE 3 de la spécification technique pour la philosophie complète :
-- support de millions d'utilisateurs, séparation stricte économie (Ballons)
-- / réputation (Stars), rôles extensibles sans migration destructrice,
-- RLS partout, tables du scouting et de l'IA prévues même si désactivées.

create extension if not exists pgcrypto;

-- =========================================================================
-- profiles — extension de auth.users
-- =========================================================================
create table profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text unique not null,
  display_name text,
  avatar_url text,
  bio text default '',
  country text,
  city text,
  birth_date date,
  position text, -- attaquant, milieu, defenseur, gardien
  preferred_foot text default 'droit', -- gauche, droit, les_deux
  height_cm integer,
  weight_kg integer,

  -- Rôle et permissions (pour pouvoir les changer à distance sans update de
  -- l'app — voir feature flags)
  role text not null default 'player',
  -- player, creator, coach, club, academy, scout, brand, admin
  is_verified boolean default false,
  verification_type text, -- talent, official_club, official_academy, brand

  -- Économie
  coins integer not null default 500,

  -- Réputation / Football IQ — JAMAIS modifiable directement par le client
  stars integer not null default 0,
  level text not null default 'rookie', -- rookie, rising_star, prodigy, legend

  -- Football IQ détaillé (5 dimensions)
  iq_technique integer default 0,
  iq_creativity integer default 0,
  iq_popularity integer default 0,
  iq_consistency integer default 0,
  iq_tactical integer default 0,

  -- Engagement
  streak_days integer default 0,
  last_login_date date,

  -- Compteurs (dénormalisés pour performance)
  followers_count integer default 0,
  following_count integer default 0,
  videos_count integer default 0,
  moves_created_count integer default 0,
  likes_received_count integer default 0,
  challenges_won_count integer default 0,

  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  constraint username_length check (char_length(username) >= 3)
);

create index idx_profiles_username on profiles (username);
create index idx_profiles_country on profiles (country);
create index idx_profiles_role on profiles (role);
create index idx_profiles_stars on profiles (stars desc);
create index idx_profiles_position on profiles (position);

-- =========================================================================
-- videos
-- =========================================================================
create table videos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles (id) on delete cascade,

  video_url text not null,
  thumbnail_url text,
  duration_seconds integer,
  caption text default '',
  category text not null default 'freestyle',
  -- dribble, shot, pass, control, freestyle, celebration, defense, goalkeeper

  -- Système de Moves
  is_move boolean default false,
  move_name text,
  move_slug text unique, -- pour URLs propres
  original_move_id uuid references videos (id) on delete set null,

  -- Métriques (dénormalisées)
  views_count integer default 0,
  likes_count integer default 0,
  masterclass_count integer default 0,
  comments_count integer default 0,
  shares_count integer default 0,
  reproductions_count integer default 0,

  -- Score algorithmique (calculé par Edge Function)
  talent_score decimal(10, 4) default 0,
  quality_ratio decimal(5, 4) default 0, -- likes/views

  -- Modération
  status text default 'active', -- active, under_review, removed, flagged
  is_boosted boolean default false,
  boost_expires_at timestamptz,

  -- IA (prévu, désactivé MVP)
  ai_analyzed boolean default false,
  ai_metadata jsonb,

  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index idx_videos_user on videos (user_id);
create index idx_videos_category on videos (category);
create index idx_videos_talent_score on videos (talent_score desc);
create index idx_videos_created on videos (created_at desc);
create index idx_videos_is_move on videos (is_move) where is_move = true;
create index idx_videos_original_move on videos (original_move_id);
create index idx_videos_status on videos (status);

-- =========================================================================
-- likes
-- =========================================================================
create table likes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles (id) on delete cascade,
  video_id uuid not null references videos (id) on delete cascade,
  type text not null default 'like', -- like, masterclass
  created_at timestamptz default now(),
  unique (user_id, video_id)
);

create index idx_likes_video on likes (video_id);
create index idx_likes_user on likes (user_id);

-- =========================================================================
-- comments
-- =========================================================================
create table comments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles (id) on delete cascade,
  video_id uuid not null references videos (id) on delete cascade,
  parent_id uuid references comments (id) on delete cascade, -- réponses
  content text not null,
  likes_count integer default 0,
  status text default 'active',
  created_at timestamptz default now()
);

create index idx_comments_video on comments (video_id);
create index idx_comments_parent on comments (parent_id);

-- =========================================================================
-- follows
-- =========================================================================
create table follows (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid not null references profiles (id) on delete cascade,
  following_id uuid not null references profiles (id) on delete cascade,
  created_at timestamptz default now(),
  unique (follower_id, following_id),
  check (follower_id != following_id)
);

create index idx_follows_follower on follows (follower_id);
create index idx_follows_following on follows (following_id);

-- =========================================================================
-- challenges
-- =========================================================================
create table challenges (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references profiles (id) on delete cascade,

  title text not null,
  description text default '',
  type text not null default 'challenge',
  -- battle, challenge, king, world, sponsored
  category text, -- catégorie de geste ciblée

  -- Économie
  entry_cost integer default 0,
  prize_pool integer default 0,
  prize_currency text default 'coins', -- coins, real (sponsored)

  -- Battle (1v1)
  opponent_id uuid references profiles (id),

  -- King Challenge
  current_record decimal(10, 2),
  record_holder_id uuid references profiles (id),
  record_unit text, -- jongles, secondes, etc.

  -- Limites
  max_participants integer,
  participants_count integer default 0,

  -- Dates
  start_date timestamptz default now(),
  end_date timestamptz not null,

  -- Statut
  status text default 'active', -- draft, active, voting, completed, cancelled
  winner_id uuid references profiles (id),

  -- Sponsor (prévu)
  sponsor_id uuid references profiles (id),
  sponsor_name text,
  sponsor_logo_url text,
  is_official boolean default false,

  created_at timestamptz default now()
);

create index idx_challenges_type on challenges (type);
create index idx_challenges_status on challenges (status);
create index idx_challenges_end_date on challenges (end_date);
create index idx_challenges_creator on challenges (creator_id);

-- =========================================================================
-- challenge_participations
-- =========================================================================
create table challenge_participations (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references challenges (id) on delete cascade,
  user_id uuid not null references profiles (id) on delete cascade,
  video_id uuid not null references videos (id) on delete cascade,
  votes_count integer default 0,
  score decimal(10, 2), -- pour King Challenge
  rank integer,
  created_at timestamptz default now(),
  unique (challenge_id, user_id)
);

create index idx_participations_challenge on challenge_participations (challenge_id);
create index idx_participations_user on challenge_participations (user_id);

-- =========================================================================
-- challenge_votes
-- =========================================================================
create table challenge_votes (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references challenges (id) on delete cascade,
  voter_id uuid not null references profiles (id) on delete cascade,
  participant_id uuid not null references profiles (id) on delete cascade,
  created_at timestamptz default now(),
  unique (challenge_id, voter_id)
);

create index idx_votes_challenge on challenge_votes (challenge_id);

-- =========================================================================
-- transactions — économie
-- =========================================================================
create table transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles (id) on delete cascade,

  type text not null, -- earn, spend, purchase, refund
  amount integer not null,
  currency text not null default 'coins', -- coins, stars
  balance_after integer, -- solde après transaction

  reason text not null,
  -- daily_login, post_video, win_challenge, boost_video, purchase_pack,
  -- move_reproduced, masterclass_received, ad_watched, invite_friend, etc.

  reference_type text, -- challenge, video, purchase
  reference_id uuid,

  -- Pour les achats réels
  purchase_platform text, -- apple, google, stripe
  purchase_receipt text,
  real_amount_cents integer,
  real_currency text,

  created_at timestamptz default now()
);

create index idx_transactions_user on transactions (user_id);
create index idx_transactions_type on transactions (type);
create index idx_transactions_created on transactions (created_at desc);

-- =========================================================================
-- badges
-- =========================================================================
create table badges (
  id uuid primary key default gen_random_uuid(),
  code text unique not null, -- viral, assidu_100, world_champion
  name text not null,
  description text,
  icon_url text,
  category text, -- achievement, streak, competition, special, level
  rarity text default 'common', -- common, rare, epic, legendary
  requirement jsonb, -- conditions programmatiques
  created_at timestamptz default now()
);

-- =========================================================================
-- user_badges
-- =========================================================================
create table user_badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles (id) on delete cascade,
  badge_id uuid not null references badges (id) on delete cascade,
  earned_at timestamptz default now(),
  unique (user_id, badge_id)
);

create index idx_user_badges_user on user_badges (user_id);

-- =========================================================================
-- daily_missions
-- =========================================================================
create table daily_missions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles (id) on delete cascade,
  mission_date date not null default current_date,
  login_completed boolean default false,
  video_posted boolean default false,
  challenge_participated boolean default false,
  videos_watched integer default 0,
  coins_earned integer default 0,
  all_completed boolean default false,
  unique (user_id, mission_date)
);

create index idx_missions_user_date on daily_missions (user_id, mission_date);

-- =========================================================================
-- notifications
-- =========================================================================
create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles (id) on delete cascade,
  type text not null,
  -- new_follower, like, comment, challenge_ended, badge_earned,
  -- move_reproduced, challenge_won, scout_interest
  title text not null,
  body text,
  actor_id uuid references profiles (id), -- qui a déclenché
  reference_type text,
  reference_id uuid,
  is_read boolean default false,
  created_at timestamptz default now()
);

create index idx_notifications_user on notifications (user_id, is_read);
create index idx_notifications_created on notifications (created_at desc);

-- =========================================================================
-- Tables SCOUTING (prévues, RLS restreint tant que non activées — voir
-- feature_flags.scouting)
-- =========================================================================

-- Intérêt d'un scout pour un joueur
create table scout_interests (
  id uuid primary key default gen_random_uuid(),
  scout_id uuid not null references profiles (id) on delete cascade,
  player_id uuid not null references profiles (id) on delete cascade,
  status text default 'interested', -- interested, contacted, shortlisted
  notes text,
  created_at timestamptz default now(),
  unique (scout_id, player_id)
);

-- Abonnements scout
create table scout_subscriptions (
  id uuid primary key default gen_random_uuid(),
  scout_id uuid not null references profiles (id) on delete cascade,
  plan text not null, -- basic, pro, elite
  status text default 'active',
  started_at timestamptz default now(),
  expires_at timestamptz,
  stripe_subscription_id text
);

-- Organisations (clubs, académies)
create table organizations (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles (id),
  name text not null,
  type text not null, -- club, academy
  country text,
  logo_url text,
  is_verified boolean default false,
  created_at timestamptz default now()
);

-- Membres d'une organisation
create table organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations (id) on delete cascade,
  user_id uuid not null references profiles (id) on delete cascade,
  role text default 'player', -- player, coach, staff
  created_at timestamptz default now(),
  unique (organization_id, user_id)
);

-- =========================================================================
-- app_config — feature flags et paramètres économiques à distance
-- =========================================================================
create table app_config (
  key text primary key,
  value jsonb not null,
  description text,
  updated_at timestamptz default now()
);


-- ===================== 20260101000001_rls_policies.sql =====================
-- Row Level Security — activée sur TOUTES les tables.
--
-- Principe de sécurité crucial : les Ballons (coins) et les Stars ne
-- peuvent JAMAIS être modifiés directement par le client. Toute
-- modification passe par une Edge Function utilisant la clé service_role
-- (qui bypass RLS). Le client ne fait qu'appeler des fonctions, jamais des
-- UPDATE directs sur coins ou stars. C'est ce qui empêche la triche.

-- =========================================================================
-- profiles — lecture publique, écriture propre (hors coins/stars/level/iq_*)
-- =========================================================================
alter table profiles enable row level security;

create policy "Profiles are viewable by everyone"
on profiles for select
using (true);

create policy "Users can update own profile"
on profiles for update
using (auth.uid() = id);

-- =========================================================================
-- videos — lecture publique (si active), écriture propre
-- =========================================================================
alter table videos enable row level security;

create policy "Active videos viewable by everyone"
on videos for select
using (status = 'active' or user_id = auth.uid());

create policy "Users can insert own videos"
on videos for insert
with check (auth.uid() = user_id);

create policy "Users can update own videos"
on videos for update
using (auth.uid() = user_id);

create policy "Users can delete own videos"
on videos for delete
using (auth.uid() = user_id);

-- =========================================================================
-- likes
-- =========================================================================
alter table likes enable row level security;

create policy "Likes are viewable by everyone"
on likes for select
using (true);

create policy "Users can like as themselves"
on likes for insert
with check (auth.uid() = user_id);

create policy "Users can remove their own like"
on likes for delete
using (auth.uid() = user_id);

-- =========================================================================
-- comments
-- =========================================================================
alter table comments enable row level security;

create policy "Active comments are viewable by everyone"
on comments for select
using (status = 'active');

create policy "Users can comment as themselves"
on comments for insert
with check (auth.uid() = user_id);

create policy "Users can update own comments"
on comments for update
using (auth.uid() = user_id);

create policy "Users can delete own comments"
on comments for delete
using (auth.uid() = user_id);

-- =========================================================================
-- follows
-- =========================================================================
alter table follows enable row level security;

create policy "Follows are viewable by everyone"
on follows for select
using (true);

create policy "Users can follow as themselves"
on follows for insert
with check (auth.uid() = follower_id);

create policy "Users can unfollow as themselves"
on follows for delete
using (auth.uid() = follower_id);

-- =========================================================================
-- challenges
-- =========================================================================
alter table challenges enable row level security;

create policy "Challenges are viewable by everyone"
on challenges for select
using (true);

create policy "Users can create challenges as themselves"
on challenges for insert
with check (auth.uid() = creator_id);

-- Seuls les champs éditoriaux d'un défi encore en brouillon sont modifiables
-- côté client. La résolution (status, winner_id, prize_pool distribué) est
-- réservée à l'Edge Function `resolve-challenge` (service role).
create policy "Creators can edit own draft challenges"
on challenges for update
using (auth.uid() = creator_id and status = 'draft');

-- =========================================================================
-- challenge_participations
-- =========================================================================
alter table challenge_participations enable row level security;

create policy "Participations are viewable by everyone"
on challenge_participations for select
using (true);

create policy "Users can join a challenge as themselves"
on challenge_participations for insert
with check (auth.uid() = user_id);

-- =========================================================================
-- challenge_votes
-- =========================================================================
alter table challenge_votes enable row level security;

create policy "Vote counts are viewable by everyone"
on challenge_votes for select
using (true);

create policy "Users can vote as themselves"
on challenge_votes for insert
with check (auth.uid() = voter_id and voter_id != participant_id);

-- =========================================================================
-- transactions — lecture propre uniquement, PAS d'écriture directe.
-- Seules les Edge Functions (service role) peuvent créer des transactions.
-- =========================================================================
alter table transactions enable row level security;

create policy "Users can view own transactions"
on transactions for select
using (auth.uid() = user_id);

-- =========================================================================
-- badges — catalogue public, pas d'écriture client
-- =========================================================================
alter table badges enable row level security;

create policy "Badges catalog is viewable by everyone"
on badges for select
using (true);

-- =========================================================================
-- user_badges — lecture publique (Football Passport), attribution
-- réservée au serveur
-- =========================================================================
alter table user_badges enable row level security;

create policy "Earned badges are viewable by everyone"
on user_badges for select
using (true);

-- =========================================================================
-- daily_missions — lecture propre uniquement ; la progression est mise à
-- jour par l'Edge Function `process-daily-missions`
-- =========================================================================
alter table daily_missions enable row level security;

create policy "Users can view own daily missions"
on daily_missions for select
using (auth.uid() = user_id);

-- =========================================================================
-- notifications — lecture propre, seul le flag is_read est modifiable
-- =========================================================================
alter table notifications enable row level security;

create policy "Users can view own notifications"
on notifications for select
using (auth.uid() = user_id);

create policy "Users can mark own notifications as read"
on notifications for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- =========================================================================
-- app_config — lecture publique (feature flags nécessaires au démarrage),
-- pas d'écriture client
-- =========================================================================
alter table app_config enable row level security;

create policy "App config is readable by everyone"
on app_config for select
using (true);

-- =========================================================================
-- scout_interests — accès uniquement si role = scout, sur ses propres
-- watchlists (fonctionnalité désactivée en MVP via feature flag côté app)
-- =========================================================================
alter table scout_interests enable row level security;

create policy "Scouts can manage own interests"
on scout_interests for all
using (
  auth.uid() = scout_id
  and exists (
    select 1 from profiles
    where id = auth.uid() and role = 'scout'
  )
);

-- =========================================================================
-- scout_subscriptions — lecture propre uniquement
-- =========================================================================
alter table scout_subscriptions enable row level security;

create policy "Scouts can view own subscription"
on scout_subscriptions for select
using (auth.uid() = scout_id);

-- =========================================================================
-- organizations — lecture publique, gestion par le owner
-- =========================================================================
alter table organizations enable row level security;

create policy "Organizations are viewable by everyone"
on organizations for select
using (true);

create policy "Owners can manage own organization"
on organizations for update
using (auth.uid() = owner_id);

create policy "Users can create an organization they own"
on organizations for insert
with check (auth.uid() = owner_id);

-- =========================================================================
-- organization_members — lecture publique, gestion par le owner de l'org
-- =========================================================================
alter table organization_members enable row level security;

create policy "Organization members are viewable by everyone"
on organization_members for select
using (true);

create policy "Org owners can manage members"
on organization_members for all
using (
  exists (
    select 1 from organizations
    where organizations.id = organization_members.organization_id
      and organizations.owner_id = auth.uid()
  )
);


-- ===================== 20260101000002_triggers.sql =====================
-- Triggers et fonctions PostgreSQL — PARTIE 3.4 de la spécification.

-- =========================================================================
-- Mise à jour automatique du niveau selon les Stars (Rookie/Rising
-- Star/Prodigy/Legend — PARTIE 6.2). Ne dépend d'aucun appel client :
-- se déclenche dès que `stars` est modifié par une Edge Function.
-- =========================================================================
create or replace function update_user_level()
returns trigger as $$
begin
  new.level := case
    when new.stars >= 25000 then 'legend'
    when new.stars >= 5000 then 'prodigy'
    when new.stars >= 500 then 'rising_star'
    else 'rookie'
  end;
  return new;
end;
$$ language plpgsql;

create trigger trigger_update_level
before update of stars on profiles
for each row
execute function update_user_level();

-- =========================================================================
-- Compteurs de follows dénormalisés
-- =========================================================================
create or replace function handle_new_follow()
returns trigger as $$
begin
  update profiles set following_count = following_count + 1
  where id = new.follower_id;

  update profiles set followers_count = followers_count + 1
  where id = new.following_id;

  return new;
end;
$$ language plpgsql;

create trigger trigger_new_follow
after insert on follows
for each row
execute function handle_new_follow();

create or replace function handle_unfollow()
returns trigger as $$
begin
  update profiles set following_count = greatest(following_count - 1, 0)
  where id = old.follower_id;

  update profiles set followers_count = greatest(followers_count - 1, 0)
  where id = old.following_id;

  return old;
end;
$$ language plpgsql;

create trigger trigger_unfollow
after delete on follows
for each row
execute function handle_unfollow();

-- =========================================================================
-- Compteurs de likes dénormalisés sur videos
-- =========================================================================
create or replace function handle_new_like()
returns trigger as $$
begin
  if new.type = 'masterclass' then
    update videos set masterclass_count = masterclass_count + 1
    where id = new.video_id;
  else
    update videos set likes_count = likes_count + 1
    where id = new.video_id;
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trigger_new_like
after insert on likes
for each row
execute function handle_new_like();

create or replace function handle_remove_like()
returns trigger as $$
begin
  if old.type = 'masterclass' then
    update videos set masterclass_count = greatest(masterclass_count - 1, 0)
    where id = old.video_id;
  else
    update videos set likes_count = greatest(likes_count - 1, 0)
    where id = old.video_id;
  end if;
  return old;
end;
$$ language plpgsql;

create trigger trigger_remove_like
after delete on likes
for each row
execute function handle_remove_like();

-- =========================================================================
-- Compteur de commentaires dénormalisé
-- =========================================================================
create or replace function handle_new_comment()
returns trigger as $$
begin
  update videos set comments_count = comments_count + 1
  where id = new.video_id;
  return new;
end;
$$ language plpgsql;

create trigger trigger_new_comment
after insert on comments
for each row
execute function handle_new_comment();

-- =========================================================================
-- Compteur de vidéos et de Moves créés par profil
-- =========================================================================
create or replace function handle_new_video()
returns trigger as $$
begin
  update profiles set videos_count = videos_count + 1
  where id = new.user_id;

  if new.is_move then
    update profiles set moves_created_count = moves_created_count + 1
    where id = new.user_id;
  end if;

  if new.original_move_id is not null then
    update videos set reproductions_count = reproductions_count + 1
    where id = new.original_move_id;
  end if;

  return new;
end;
$$ language plpgsql;

create trigger trigger_new_video
after insert on videos
for each row
execute function handle_new_video();

-- =========================================================================
-- Provisionnement automatique du profil à la création d'un compte
-- (auth.users -> profiles). Les infos d'inscription (username, pays,
-- poste, pied fort) sont transmises via `data:` dans `supabase.auth.signUp`
-- et lues ici depuis raw_user_meta_data. Le bonus de bienvenue (Ballons)
-- est appliqué directement à la création : ce n'est pas une "récompense"
-- soumise à triche, juste le solde de départ d'un nouveau compte.
-- =========================================================================
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (
    id,
    username,
    display_name,
    country,
    position,
    preferred_foot,
    birth_date,
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
    500
  );

  insert into public.transactions (user_id, type, amount, currency, balance_after, reason)
  values (new.id, 'earn', 500, 'coins', 500, 'welcome_bonus');

  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function handle_new_user();

-- =========================================================================
-- Maintenance générique de `updated_at`
-- =========================================================================
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

create trigger trigger_profiles_updated_at
before update on profiles
for each row
execute function set_updated_at();

create trigger trigger_videos_updated_at
before update on videos
for each row
execute function set_updated_at();


-- ===================== 20260101000003_seed_data.sql =====================
-- Données d'amorçage : feature flags, paramètres économiques, badges.

-- =========================================================================
-- app_config — miroir de `core/config/feature_flags.dart` et
-- `core/constants/economy_constants.dart`
-- =========================================================================
insert into app_config (key, value, description) values
(
  'feature_flags',
  '{
    "scouting": false,
    "payments": false,
    "club_accounts": false,
    "academy_accounts": false,
    "ai_analysis": false,
    "live_battles": false,
    "world_challenges": false,
    "sponsored_challenges": false
  }'::jsonb,
  'Activation/désactivation de fonctionnalités sans redéploiement.'
),
(
  'economy',
  '{
    "welcome_bonus": 500,
    "daily_login_min": 10,
    "daily_login_max": 20,
    "post_video": 5,
    "max_post_video_per_day": 3,
    "move_reproduced": 1,
    "masterclass_received": 2,
    "ad_watched": 30,
    "max_ad_watched_per_day": 5,
    "invite_friend": 100,
    "streak_7_days_bonus": 50,
    "streak_30_days_bonus": 200,
    "join_challenge_cost": 20,
    "join_battle_min_cost": 50,
    "create_challenge_cost": 200,
    "boost_video_cost": 100,
    "custom_badge_cost": 300,
    "special_effect_cost": 50
  }'::jsonb,
  'Valeurs de l''économie Ballons, ajustables à distance après lancement.'
);

-- =========================================================================
-- badges — catalogue de départ (voir PARTIE 8.7/8.8 pour les récompenses
-- hebdomadaires, attribuées dynamiquement par les Edge Functions)
-- =========================================================================
insert into badges (code, name, description, category, rarity) values
('welcome', 'Bienvenue', 'A rejoint Football IQ Universe.', 'achievement', 'common'),
('first_video', 'Premier Pas', 'A posté sa première vidéo.', 'achievement', 'common'),
('first_move', 'Inventeur', 'A créé son premier Move.', 'achievement', 'rare'),
('viral', 'Viral', 'Une vidéo a dépassé 100 000 vues.', 'achievement', 'epic'),
('assidu_7', 'Régulier', '7 jours de connexion consécutifs.', 'streak', 'common'),
('assidu_30', 'Discipline de Fer', '30 jours de connexion consécutifs.', 'streak', 'rare'),
('first_challenge_win', 'Premier Sacre', 'A remporté son premier défi.', 'competition', 'rare'),
('world_champion', 'Champion du Monde', 'A remporté un Défi Monde hebdomadaire.', 'competition', 'legendary'),
('next_football_star', 'Next Football Star', 'Top 10 de la progression hebdomadaire.', 'special', 'epic'),
('rising_star', 'Rising Star', 'A atteint le niveau Rising Star.', 'level', 'common'),
('prodigy', 'Prodigy', 'A atteint le niveau Prodigy.', 'level', 'epic'),
('legend', 'Legend', 'A atteint le niveau Legend.', 'level', 'legendary');


-- ===================== 20260101000004_storage_and_reactions.sql =====================
-- Storage RLS + ajustements liés aux réactions (likes/masterclass) et aux
-- vues vidéo, introduits par la Semaine 3-4 (upload, feed, interactions).

-- =========================================================================
-- storage.objects — lecture publique, écriture restreinte au dossier
-- <user_id>/... de l'utilisateur (convention utilisée par
-- lib/core/services/storage_service.dart)
-- =========================================================================

create policy "Public read access to app buckets"
on storage.objects for select
using (bucket_id = any (array['videos', 'thumbnails', 'avatars']));

create policy "Users can upload to their own folder"
on storage.objects for insert
with check (
  bucket_id = any (array['videos', 'thumbnails', 'avatars'])
  and (storage.foldername(name)) [1] = auth.uid()::text
);

create policy "Users can update their own files"
on storage.objects for update
using (
  bucket_id = any (array['videos', 'thumbnails', 'avatars'])
  and (storage.foldername(name)) [1] = auth.uid()::text
);

create policy "Users can delete their own files"
on storage.objects for delete
using (
  bucket_id = any (array['videos', 'thumbnails', 'avatars'])
  and (storage.foldername(name)) [1] = auth.uid()::text
);

-- =========================================================================
-- Un utilisateur n'a qu'UNE réaction par vidéo (UNIQUE(user_id, video_id)),
-- basculée via `upsert` côté client (like <-> masterclass). Le trigger
-- `handle_new_like`/`handle_remove_like` ne couvre que INSERT/DELETE : ce
-- trigger complète pour le cas UPDATE (changement de type sur upsert), afin
-- que likes_count/masterclass_count restent exacts.
-- =========================================================================
create or replace function handle_like_type_change()
returns trigger as $$
begin
  if new.type = old.type then
    return new;
  end if;

  if old.type = 'masterclass' then
    update videos set masterclass_count = greatest(masterclass_count - 1, 0)
    where id = old.video_id;
  else
    update videos set likes_count = greatest(likes_count - 1, 0)
    where id = old.video_id;
  end if;

  if new.type = 'masterclass' then
    update videos set masterclass_count = masterclass_count + 1
    where id = new.video_id;
  else
    update videos set likes_count = likes_count + 1
    where id = new.video_id;
  end if;

  return new;
end;
$$ language plpgsql;

create trigger trigger_like_type_change
after update of type on likes
for each row
execute function handle_like_type_change();

-- =========================================================================
-- Comptage des vues + attribution de Stars au créateur (1 Star / 100 vues
-- — PARTIE 4.2/6). Fonction SECURITY DEFINER : le client appelle
-- exclusivement `increment_video_views`, jamais un UPDATE direct sur
-- `videos.views_count` ou `profiles.stars`. Sert de version SQL du futur
-- Edge Function `handle-video-view` tant que celui-ci n'est pas développé.
-- =========================================================================
create or replace function increment_video_views(p_video_id uuid)
returns void as $$
declare
  v_creator_id uuid;
  v_new_views integer;
begin
  update videos
  set views_count = views_count + 1
  where id = p_video_id
  returning user_id, views_count into v_creator_id, v_new_views;

  if v_creator_id is null then
    return;
  end if;

  if v_new_views % 100 = 0 then
    update profiles set stars = stars + 1 where id = v_creator_id;

    insert into transactions (
      user_id, type, amount, currency, reason, reference_type, reference_id
    ) values (
      v_creator_id, 'earn', 1, 'stars', 'video_views_milestone', 'video', p_video_id
    );
  end if;
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function increment_video_views(uuid) to authenticated;


-- ===================== 20260101000005_economy_rpc.sql =====================
-- Économie (Ballons) — PARTIE 4.2 / 7 de la spécification.
--
-- Choix d'implémentation : la spec décrit des Edge Functions TypeScript/Deno
-- (`award-coins`, `spend-coins`). Elles sont implémentées ici comme des
-- fonctions Postgres SECURITY DEFINER, appelées directement via
-- `supabase.rpc(...)` — même garantie anti-triche (le solde et les
-- transactions ne sont modifiables que côté serveur, et `auth.uid()` est lu
-- depuis le JWT vérifié par PostgREST, jamais fourni par le client), sans
-- dépendre d'un runtime Deno qu'on ne peut ni exécuter ni tester ici. À
-- migrer vers de vraies Edge Functions si une logique plus riche devient
-- nécessaire (appel à une régie pub externe, rate limiting applicatif...).

-- =========================================================================
-- award_coins — attribue des Ballons pour une action gratuite validée
-- =========================================================================
create or replace function award_coins(
  p_reason text,
  p_reference_id uuid default null
)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_economy jsonb;
  v_amount integer;
  v_today date := current_date;
  v_last_login date;
  v_streak integer;
  v_count_today integer;
  v_new_balance integer;
  v_streak_bonus integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  select value into v_economy from app_config where key = 'economy';

  if p_reason = 'daily_login' then
    select last_login_date, streak_days into v_last_login, v_streak
    from profiles where id = v_user_id for update;

    if v_last_login = v_today then
      raise exception 'Connexion quotidienne déjà réclamée aujourd''hui.' using errcode = 'P0001';
    end if;

    if v_last_login = v_today - 1 then
      v_streak := coalesce(v_streak, 0) + 1;
    else
      v_streak := 1;
    end if;

    v_amount := coalesce((v_economy ->> 'daily_login_max')::integer, 20);

    v_streak_bonus := case
      when v_streak = 7 then coalesce((v_economy ->> 'streak_7_days_bonus')::integer, 50)
      when v_streak = 30 then coalesce((v_economy ->> 'streak_30_days_bonus')::integer, 200)
      else 0
    end;
    v_amount := v_amount + v_streak_bonus;

    update profiles
    set coins = coins + v_amount,
        last_login_date = v_today,
        streak_days = v_streak
    where id = v_user_id
    returning coins into v_new_balance;

    insert into daily_missions (user_id, mission_date, login_completed, coins_earned)
    values (v_user_id, v_today, true, v_amount)
    on conflict (user_id, mission_date)
    do update set login_completed = true,
                  coins_earned = daily_missions.coins_earned + v_amount;

    if v_streak = 7 then
      insert into user_badges (user_id, badge_id)
      select v_user_id, id from badges where code = 'assidu_7'
      on conflict (user_id, badge_id) do nothing;
    elsif v_streak = 30 then
      insert into user_badges (user_id, badge_id)
      select v_user_id, id from badges where code = 'assidu_30'
      on conflict (user_id, badge_id) do nothing;
    end if;

  elsif p_reason = 'post_video' then
    select count(*) into v_count_today
    from transactions
    where user_id = v_user_id and reason = 'post_video' and created_at >= v_today;

    if v_count_today >= coalesce((v_economy ->> 'max_post_video_per_day')::integer, 3) then
      raise exception 'Limite quotidienne de récompenses vidéo atteinte.' using errcode = 'P0001';
    end if;

    v_amount := coalesce((v_economy ->> 'post_video')::integer, 5);

    update profiles set coins = coins + v_amount
    where id = v_user_id
    returning coins into v_new_balance;

    insert into daily_missions (user_id, mission_date, video_posted, coins_earned)
    values (v_user_id, v_today, true, v_amount)
    on conflict (user_id, mission_date)
    do update set video_posted = true,
                  coins_earned = daily_missions.coins_earned + v_amount;

  elsif p_reason = 'ad_watched' then
    select count(*) into v_count_today
    from transactions
    where user_id = v_user_id and reason = 'ad_watched' and created_at >= v_today;

    if v_count_today >= coalesce((v_economy ->> 'max_ad_watched_per_day')::integer, 5) then
      raise exception 'Limite quotidienne de publicités atteinte.' using errcode = 'P0001';
    end if;

    v_amount := coalesce((v_economy ->> 'ad_watched')::integer, 30);

    update profiles set coins = coins + v_amount
    where id = v_user_id
    returning coins into v_new_balance;

  else
    raise exception 'Raison de récompense non prise en charge : %', p_reason using errcode = 'P0001';
  end if;

  insert into transactions (user_id, type, amount, currency, balance_after, reason, reference_id)
  values (v_user_id, 'earn', v_amount, 'coins', v_new_balance, p_reason, p_reference_id);

  return jsonb_build_object('new_balance', v_new_balance, 'amount_awarded', v_amount);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function award_coins(text, uuid) to authenticated;

-- =========================================================================
-- spend_coins — débite des Ballons pour une action payante, montant
-- toujours dérivé de app_config.economy (jamais du client)
-- =========================================================================
create or replace function spend_coins(
  p_reason text,
  p_reference_id uuid default null,
  p_amount integer default null
)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_economy jsonb;
  v_expected_amount integer;
  v_new_balance integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  select value into v_economy from app_config where key = 'economy';

  v_expected_amount := case p_reason
    when 'join_challenge' then coalesce((v_economy ->> 'join_challenge_cost')::integer, 20)
    when 'join_battle' then coalesce((v_economy ->> 'join_battle_min_cost')::integer, 50)
    when 'create_challenge' then coalesce((v_economy ->> 'create_challenge_cost')::integer, 200)
    when 'boost_video' then coalesce((v_economy ->> 'boost_video_cost')::integer, 100)
    when 'custom_badge' then coalesce((v_economy ->> 'custom_badge_cost')::integer, 300)
    when 'special_effect' then coalesce((v_economy ->> 'special_effect_cost')::integer, 50)
    else null
  end;

  if v_expected_amount is null then
    raise exception 'Raison de dépense non prise en charge : %', p_reason using errcode = 'P0001';
  end if;

  -- `p_amount` n'est accepté qu'à titre défensif : s'il est fourni, il doit
  -- correspondre au tarif serveur, sous peine de rejet.
  if p_amount is not null and p_amount <> v_expected_amount then
    raise exception 'Montant invalide pour cette action.' using errcode = 'P0001';
  end if;

  update profiles
  set coins = coins - v_expected_amount
  where id = v_user_id and coins >= v_expected_amount
  returning coins into v_new_balance;

  if v_new_balance is null then
    raise exception 'Solde de Ballons insuffisant.' using errcode = 'P0001';
  end if;

  insert into transactions (user_id, type, amount, currency, balance_after, reason, reference_id)
  values (v_user_id, 'spend', -v_expected_amount, 'coins', v_new_balance, p_reason, p_reference_id);

  return jsonb_build_object('new_balance', v_new_balance, 'amount_spent', v_expected_amount);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function spend_coins(text, uuid, integer) to authenticated;


-- ===================== 20260101000006_daily_missions_rpc.sql =====================
-- Missions quotidiennes — PARTIE 8.5. `login_completed`/`video_posted`
-- sont déjà mis à jour par `award_coins` (voir migration précédente) au
-- moment où l'utilisateur réclame son bonus de connexion / publie une
-- vidéo. Cette migration ajoute le suivi "vidéos regardées" et son bonus
-- de palier (+5 Ballons à la 3e vidéo du jour).

create or replace function increment_videos_watched()
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_today date := current_date;
  v_watched integer;
  v_bonus_awarded boolean := false;
  v_new_balance integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  insert into daily_missions (user_id, mission_date, videos_watched)
  values (v_user_id, v_today, 1)
  on conflict (user_id, mission_date)
  do update set videos_watched = daily_missions.videos_watched + 1
  returning videos_watched into v_watched;

  if v_watched = 3 then
    update profiles set coins = coins + 5
    where id = v_user_id
    returning coins into v_new_balance;

    update daily_missions set coins_earned = coins_earned + 5
    where user_id = v_user_id and mission_date = v_today;

    insert into transactions (user_id, type, amount, currency, balance_after, reason)
    values (v_user_id, 'earn', 5, 'coins', v_new_balance, 'daily_videos_watched');

    v_bonus_awarded := true;
  end if;

  return jsonb_build_object('videos_watched', v_watched, 'bonus_awarded', v_bonus_awarded);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function increment_videos_watched() to authenticated;


-- ===================== 20260101000007_move_reproduction_reward.sql =====================
-- Récompense l'inventeur d'un Move à chaque reproduction (+1 Ballon — voir
-- PARTIE 7.1 "Move reproduit : 1 Ballon"). Remplace `handle_new_video`
-- (définie dans 20260101000002_triggers.sql) plutôt que de la modifier :
-- le trigger existant pointe déjà vers cette fonction, `create or replace`
-- suffit à changer son comportement sans la recréer.
create or replace function handle_new_video()
returns trigger as $$
declare
  v_original_creator_id uuid;
  v_new_balance integer;
begin
  update profiles set videos_count = videos_count + 1
  where id = new.user_id;

  if new.is_move then
    update profiles set moves_created_count = moves_created_count + 1
    where id = new.user_id;
  end if;

  if new.original_move_id is not null then
    update videos set reproductions_count = reproductions_count + 1
    where id = new.original_move_id;

    select user_id into v_original_creator_id
    from videos where id = new.original_move_id;

    -- Pas d'auto-récompense si on reproduit son propre Move.
    if v_original_creator_id is not null and v_original_creator_id != new.user_id then
      update profiles set coins = coins + 1
      where id = v_original_creator_id
      returning coins into v_new_balance;

      insert into transactions (
        user_id, type, amount, currency, balance_after, reason,
        reference_type, reference_id
      ) values (
        v_original_creator_id, 'earn', 1, 'coins', v_new_balance, 'move_reproduced',
        'video', new.id
      );
    end if;
  end if;

  return new;
end;
$$ language plpgsql;


-- ===================== 20260101000008_challenges_rpc.sql =====================
-- Défis (Battle/Challenge/King/World/Sponsored) — PARTIE 4.2/8.3.
-- Comme pour l'économie et les missions, les Edge Functions décrites par
-- la spec (`resolve-challenge`) sont implémentées en fonctions Postgres
-- SECURITY DEFINER : même garantie anti-triche, sans dépendre d'un
-- runtime Deno qu'on ne peut pas exécuter/tester ici.

-- =========================================================================
-- join_challenge — débite l'entrée et inscrit une vidéo du joueur
-- =========================================================================
create or replace function join_challenge(p_challenge_id uuid, p_video_id uuid)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_entry_cost integer;
  v_status text;
  v_end_date timestamptz;
  v_max_participants integer;
  v_participants_count integer;
  v_video_owner uuid;
  v_new_balance integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  select entry_cost, status, end_date, max_participants, participants_count
    into v_entry_cost, v_status, v_end_date, v_max_participants, v_participants_count
  from challenges where id = p_challenge_id
  for update;

  if v_status is null then
    raise exception 'Défi introuvable.' using errcode = 'P0001';
  end if;

  if v_status != 'active' or now() > v_end_date then
    raise exception 'Ce défi n''accepte plus de participations.' using errcode = 'P0001';
  end if;

  if v_max_participants is not null and v_participants_count >= v_max_participants then
    raise exception 'Ce défi est complet.' using errcode = 'P0001';
  end if;

  select user_id into v_video_owner from videos where id = p_video_id;
  if v_video_owner is null or v_video_owner != v_user_id then
    raise exception 'Tu ne peux participer qu''avec l''une de tes propres vidéos.'
      using errcode = 'P0001';
  end if;

  if exists (
    select 1 from challenge_participations
    where challenge_id = p_challenge_id and user_id = v_user_id
  ) then
    raise exception 'Tu participes déjà à ce défi.' using errcode = 'P0001';
  end if;

  if v_entry_cost > 0 then
    update profiles set coins = coins - v_entry_cost
    where id = v_user_id and coins >= v_entry_cost
    returning coins into v_new_balance;

    if v_new_balance is null then
      raise exception 'Solde de Ballons insuffisant.' using errcode = 'P0001';
    end if;

    insert into transactions (
      user_id, type, amount, currency, balance_after, reason, reference_type, reference_id
    ) values (
      v_user_id, 'spend', -v_entry_cost, 'coins', v_new_balance, 'join_challenge',
      'challenge', p_challenge_id
    );
  end if;

  insert into challenge_participations (challenge_id, user_id, video_id)
  values (p_challenge_id, v_user_id, p_video_id);

  update challenges set participants_count = participants_count + 1
  where id = p_challenge_id;

  return jsonb_build_object('joined', true);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function join_challenge(uuid, uuid) to authenticated;

-- =========================================================================
-- create_challenge — débite le coût de création et crée le défi
-- =========================================================================
create or replace function create_challenge(
  p_title text,
  p_description text,
  p_type text,
  p_end_date timestamptz,
  p_category text default null,
  p_prize_pool integer default 0,
  p_max_participants integer default null,
  p_record_unit text default null
)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_economy jsonb;
  v_create_cost integer;
  v_entry_cost integer;
  v_new_balance integer;
  v_challenge_id uuid;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  -- World (hebdomadaire officiel) et Sponsored (marques) ne sont pas
  -- créables par les joueurs — voir PARTIE 8.3.
  if p_type not in ('battle', 'challenge', 'king') then
    raise exception
      'Seuls les défis Battle, Challenge et King peuvent être créés par les joueurs.'
      using errcode = 'P0001';
  end if;

  if p_end_date <= now() then
    raise exception 'La date de fin doit être dans le futur.' using errcode = 'P0001';
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
  text, text, text, timestamptz, text, integer, integer, text
) to authenticated;

-- =========================================================================
-- vote_for_participant — un vote par défi et par utilisateur
-- =========================================================================
create or replace function vote_for_participant(p_challenge_id uuid, p_participant_id uuid)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_status text;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  select status into v_status from challenges where id = p_challenge_id;
  if v_status is null then
    raise exception 'Défi introuvable.' using errcode = 'P0001';
  end if;

  if v_status not in ('active', 'voting') then
    raise exception 'Ce défi n''accepte plus de votes.' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from challenge_participations
    where challenge_id = p_challenge_id and user_id = p_participant_id
  ) then
    raise exception 'Ce participant n''existe pas dans ce défi.' using errcode = 'P0001';
  end if;

  insert into challenge_votes (challenge_id, voter_id, participant_id)
  values (p_challenge_id, v_user_id, p_participant_id);

  update challenge_participations
  set votes_count = votes_count + 1
  where challenge_id = p_challenge_id and user_id = p_participant_id;

  return jsonb_build_object('voted', true);
exception
  when unique_violation then
    raise exception 'Tu as déjà voté dans ce défi.' using errcode = 'P0001';
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function vote_for_participant(uuid, uuid) to authenticated;

-- =========================================================================
-- resolve_expired_challenges — détermine le(s) gagnant(s), distribue le
-- prize_pool, attribue les Stars, notifie. PAS de grant à `authenticated` :
-- opération système, appelée par pg_cron ou manuellement en service_role.
-- =========================================================================
create or replace function resolve_expired_challenges()
returns integer as $$
declare
  v_challenge record;
  v_winner_user_id uuid;
  v_new_balance integer;
  v_resolved_count integer := 0;
  v_rank integer;
  v_participation record;
begin
  for v_challenge in
    select * from challenges
    where status = 'active' and end_date < now()
  loop
    v_winner_user_id := null;

    if v_challenge.type = 'king' then
      v_winner_user_id := v_challenge.record_holder_id;
    else
      select user_id into v_winner_user_id
      from challenge_participations
      where challenge_id = v_challenge.id
      order by votes_count desc, created_at asc
      limit 1;

      v_rank := 1;
      for v_participation in
        select id from challenge_participations
        where challenge_id = v_challenge.id
        order by votes_count desc, created_at asc
      loop
        update challenge_participations set rank = v_rank where id = v_participation.id;
        v_rank := v_rank + 1;
      end loop;
    end if;

    if v_winner_user_id is not null then
      if v_challenge.prize_pool > 0 and v_challenge.prize_currency = 'coins' then
        update profiles set coins = coins + v_challenge.prize_pool
        where id = v_winner_user_id
        returning coins into v_new_balance;

        insert into transactions (
          user_id, type, amount, currency, balance_after, reason,
          reference_type, reference_id
        ) values (
          v_winner_user_id, 'earn', v_challenge.prize_pool, 'coins', v_new_balance,
          'win_challenge', 'challenge', v_challenge.id
        );
      end if;

      update profiles
      set stars = stars + 100, challenges_won_count = challenges_won_count + 1
      where id = v_winner_user_id;

      insert into notifications (user_id, type, title, body, reference_type, reference_id)
      values (
        v_winner_user_id, 'challenge_won', 'Défi remporté !',
        'Tu as remporté "' || v_challenge.title || '" 🏆',
        'challenge', v_challenge.id
      );
    end if;

    update challenges
    set status = 'completed', winner_id = v_winner_user_id
    where id = v_challenge.id;

    v_resolved_count := v_resolved_count + 1;
  end loop;

  return v_resolved_count;
end;
$$ language plpgsql security definer set search_path = public;

-- Planification automatique (nécessite l'extension pg_cron — Database >
-- Extensions dans le dashboard Supabase) :
--   select cron.schedule('resolve-expired-challenges', '*/15 * * * *',
--     'select resolve_expired_challenges();');
-- En attendant, un admin peut l'appeler manuellement depuis le SQL Editor.

-- =========================================================================
-- Durcissement RLS : `join_challenge`/`create_challenge` gèrent maintenant
-- le débit de Ballons de façon atomique. Les anciennes policies INSERT
-- directes (20260101000001_rls_policies.sql) permettaient de créer un défi
-- ou de rejoindre une participation sans payer — elles sont supprimées ;
-- seules les fonctions SECURITY DEFINER ci-dessus peuvent désormais écrire
-- dans `challenges`/`challenge_participations`.
drop policy if exists "Users can create challenges as themselves" on challenges;
drop policy if exists "Users can join a challenge as themselves" on challenge_participations;


-- ===================== 20260101000009_protect_profile_columns.sql =====================
-- Correctif de sécurité : la policy RLS "Users can update own profile"
-- (USING auth.uid() = id) autorise un UPDATE sur N'IMPORTE QUELLE colonne
-- de la ligne — y compris coins/stars/iq_*/level, que tout ce projet est
-- censé ne modifier que via les fonctions SECURITY DEFINER (award_coins,
-- spend_coins, join_challenge, resolve_expired_challenges, triggers de
-- compteurs...). RLS ne fait que filtrer les LIGNES, pas les colonnes : il
-- faut un privilège Postgres au niveau colonne pour fermer ce trou.
--
-- Les fonctions SECURITY DEFINER restent non affectées : elles s'exécutent
-- avec les privilèges du propriétaire de la fonction, pas ceux du rôle
-- `authenticated` de l'appelant.

revoke update on profiles from authenticated;

grant update (
  username, display_name, avatar_url, bio, country, city, birth_date,
  position, preferred_foot, height_cm, weight_kg
) on profiles to authenticated;

-- Même trou sur `videos` : "Users can update own videos" (auth.uid() =
-- user_id) autoriserait sinon un client à s'auto-attribuer des vues, des
-- likes, un talent_score, ou à se retirer lui-même de modération
-- (status/is_boosted). Seuls caption/category/is_move/move_name restent
-- éditables par le créateur ; le reste est écrit uniquement par les
-- triggers/RPC SECURITY DEFINER.
revoke update on videos from authenticated;

grant update (caption, category, is_move, move_name) on videos to authenticated;


-- ===================== 20260101000010_pepite_of_the_day.sql =====================
-- La Pépite du Jour — voir PARTIE 8.9 : "À l'ouverture de l'app, une vidéo
-- d'un talent mis en avant. Pas une pub — du contenu inspirant. Ici, un
-- inconnu peut devenir une star."
--
-- Sélection anti-biais : parmi les vidéos récentes à fort talent_score
-- venant de profils encore peu suivis (< 500 abonnés), un tirage
-- déterministe par jour (même pépite pour tout le monde, change chaque
-- jour) évite d'avoir besoin d'un cron job dédié.

create or replace function get_pepite_of_the_day()
returns table (
  video_id uuid,
  video_url text,
  thumbnail_url text,
  caption text,
  category text,
  views_count integer,
  user_id uuid,
  username text,
  display_name text,
  avatar_url text,
  country text,
  city text,
  player_position text,
  stars integer,
  followers_count integer,
  world_rank integer
)
language sql
stable
as $$
  with candidates as (
    select
      v.id as video_id, v.video_url, v.thumbnail_url, v.caption, v.category,
      v.views_count, v.user_id,
      p.username, p.display_name, p.avatar_url, p.country, p.city,
      p.position as player_position, p.stars, p.followers_count
    from videos v
    join profiles p on p.id = v.user_id
    where v.status = 'active'
      and v.created_at > now() - interval '30 days'
      and p.followers_count < 500
    order by v.talent_score desc
    limit 50
  )
  select
    c.video_id, c.video_url, c.thumbnail_url, c.caption, c.category,
    c.views_count, c.user_id, c.username, c.display_name, c.avatar_url,
    c.country, c.city, c.player_position, c.stars, c.followers_count,
    (select count(*) + 1 from profiles p2 where p2.stars > c.stars)::integer as world_rank
  from candidates c
  order by md5(c.video_id::text || to_char(current_date, 'YYYY-MM-DD'))
  limit 1;
$$;

grant execute on function get_pepite_of_the_day() to authenticated, anon;


-- ===================== 20260101000011_notification_triggers.sql =====================
-- Déclencheurs manquants pour peupler `notifications` (PARTIE 3.2) — seul
-- `challenge_won` était déjà émis (dans `resolve_expired_challenges`).
-- Sans ceux-ci, la table restait vide en pratique et l'écran
-- "Notifications" (PARTIE 9.2, écran 31) n'aurait jamais eu de contenu.

-- =========================================================================
-- new_follower
-- =========================================================================
create or replace function notify_new_follower()
returns trigger as $$
begin
  insert into notifications (user_id, type, title, body, actor_id, reference_type, reference_id)
  select
    new.following_id, 'new_follower', 'Nouvel abonné',
    '@' || p.username || ' a commencé à te suivre.',
    new.follower_id, 'profile', new.follower_id
  from profiles p where p.id = new.follower_id;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger trigger_notify_new_follower
after insert on follows
for each row
execute function notify_new_follower();

-- =========================================================================
-- like / masterclass — notifie le créateur de la vidéo (sauf auto-like)
-- =========================================================================
create or replace function notify_new_like()
returns trigger as $$
declare
  v_video_owner uuid;
  v_actor_username text;
begin
  select user_id into v_video_owner from videos where id = new.video_id;
  if v_video_owner is null or v_video_owner = new.user_id then
    return new;
  end if;

  select username into v_actor_username from profiles where id = new.user_id;

  insert into notifications (user_id, type, title, body, actor_id, reference_type, reference_id)
  values (
    v_video_owner,
    case when new.type = 'masterclass' then 'masterclass' else 'like' end,
    case when new.type = 'masterclass' then 'Nouveau vote Masterclass' else 'Nouveau like' end,
    '@' || coalesce(v_actor_username, 'un joueur') ||
      case when new.type = 'masterclass' then ' a voté Masterclass pour ta vidéo.' else ' a aimé ta vidéo.' end,
    new.user_id, 'video', new.video_id
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger trigger_notify_new_like
after insert on likes
for each row
execute function notify_new_like();

-- =========================================================================
-- comment
-- =========================================================================
create or replace function notify_new_comment()
returns trigger as $$
declare
  v_video_owner uuid;
  v_actor_username text;
begin
  select user_id into v_video_owner from videos where id = new.video_id;
  if v_video_owner is null or v_video_owner = new.user_id then
    return new;
  end if;

  select username into v_actor_username from profiles where id = new.user_id;

  insert into notifications (user_id, type, title, body, actor_id, reference_type, reference_id)
  values (
    v_video_owner, 'comment', 'Nouveau commentaire',
    '@' || coalesce(v_actor_username, 'un joueur') || ' a commenté ta vidéo.',
    new.user_id, 'video', new.video_id
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger trigger_notify_new_comment
after insert on comments
for each row
execute function notify_new_comment();

-- =========================================================================
-- move_reproduced — crédite l'inventeur du Move (voir PARTIE 8.2 : "reste
-- l'inventeur affiché À VIE")
-- =========================================================================
create or replace function notify_move_reproduced()
returns trigger as $$
declare
  v_move_owner uuid;
  v_move_name text;
  v_actor_username text;
begin
  if new.original_move_id is null then
    return new;
  end if;

  select user_id, move_name into v_move_owner, v_move_name
  from videos where id = new.original_move_id;

  if v_move_owner is null or v_move_owner = new.user_id then
    return new;
  end if;

  select username into v_actor_username from profiles where id = new.user_id;

  insert into notifications (user_id, type, title, body, actor_id, reference_type, reference_id)
  values (
    v_move_owner, 'move_reproduced', 'Ton Move a été reproduit !',
    '@' || coalesce(v_actor_username, 'un joueur') || ' a reproduit "' ||
      coalesce(v_move_name, 'ton Move') || '".',
    new.user_id, 'video', new.id
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger trigger_notify_move_reproduced
after insert on videos
for each row
execute function notify_move_reproduced();

-- =========================================================================
-- badge_earned
-- =========================================================================
create or replace function notify_badge_earned()
returns trigger as $$
declare
  v_badge_name text;
begin
  select name into v_badge_name from badges where id = new.badge_id;

  insert into notifications (user_id, type, title, body, reference_type, reference_id)
  values (
    new.user_id, 'badge_earned', 'Nouveau badge débloqué',
    coalesce(v_badge_name, 'Un nouveau badge') || ' rejoint ton Football Passport 🏅',
    'badge', new.badge_id
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger trigger_notify_badge_earned
after insert on user_badges
for each row
execute function notify_badge_earned();


-- ===================== 20260101000012_challenge_prize_pool.sql =====================
-- Cagnotte réelle pour les Battles/Défis/King créés par un joueur, et
-- correction d'un bug d'étiquetage dans l'historique du portefeuille.
--
-- Avant ce correctif, `prize_pool` restait à 0 pour tout défi créé par un
-- joueur (aucun champ dans l'écran de création ne permet de le fixer) :
-- le gagnant ne touchait donc jamais les Ballons des perdants, qui étaient
-- simplement perdus. Désormais, chaque droit d'entrée payé via
-- `join_challenge` alimente `prize_pool`, qui est intégralement reversé au
-- vainqueur par `resolve_expired_challenges` (logique déjà existante,
-- inchangée). Le coût de création (200 Ballons, payé une fois par le
-- créateur) n'entre jamais dans la cagnotte — seuls les droits d'entrée des
-- participants la constituent.
--
-- Corrige aussi : la transaction générée par `join_challenge` utilisait
-- toujours la raison `join_challenge`, même pour un défi de type `battle`,
-- alors que `join_battle` existe déjà comme raison distincte (libellé
-- "Participation à une Battle" côté Wallet) mais n'était jamais produite.
create or replace function join_challenge(p_challenge_id uuid, p_video_id uuid)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_type text;
  v_entry_cost integer;
  v_status text;
  v_end_date timestamptz;
  v_max_participants integer;
  v_participants_count integer;
  v_video_owner uuid;
  v_new_balance integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  select type, entry_cost, status, end_date, max_participants, participants_count
    into v_type, v_entry_cost, v_status, v_end_date, v_max_participants, v_participants_count
  from challenges where id = p_challenge_id
  for update;

  if v_status is null then
    raise exception 'Défi introuvable.' using errcode = 'P0001';
  end if;

  if v_status != 'active' or now() > v_end_date then
    raise exception 'Ce défi n''accepte plus de participations.' using errcode = 'P0001';
  end if;

  if v_max_participants is not null and v_participants_count >= v_max_participants then
    raise exception 'Ce défi est complet.' using errcode = 'P0001';
  end if;

  select user_id into v_video_owner from videos where id = p_video_id;
  if v_video_owner is null or v_video_owner != v_user_id then
    raise exception 'Tu ne peux participer qu''avec l''une de tes propres vidéos.'
      using errcode = 'P0001';
  end if;

  if exists (
    select 1 from challenge_participations
    where challenge_id = p_challenge_id and user_id = v_user_id
  ) then
    raise exception 'Tu participes déjà à ce défi.' using errcode = 'P0001';
  end if;

  if v_entry_cost > 0 then
    update profiles set coins = coins - v_entry_cost
    where id = v_user_id and coins >= v_entry_cost
    returning coins into v_new_balance;

    if v_new_balance is null then
      raise exception 'Solde de Ballons insuffisant.' using errcode = 'P0001';
    end if;

    insert into transactions (
      user_id, type, amount, currency, balance_after, reason, reference_type, reference_id
    ) values (
      v_user_id, 'spend', -v_entry_cost, 'coins', v_new_balance,
      case when v_type = 'battle' then 'join_battle' else 'join_challenge' end,
      'challenge', p_challenge_id
    );

    -- Le droit d'entrée rejoint la cagnotte : c'est ce qui sera reversé en
    -- intégralité au vainqueur par `resolve_expired_challenges`.
    update challenges set prize_pool = prize_pool + v_entry_cost
    where id = p_challenge_id;
  end if;

  insert into challenge_participations (challenge_id, user_id, video_id)
  values (p_challenge_id, v_user_id, p_video_id);

  update challenges set participants_count = participants_count + 1
  where id = p_challenge_id;

  return jsonb_build_object('joined', true);
end;
$$ language plpgsql security definer set search_path = public;


-- ===================== 20260101000013_scouting_messaging.sql =====================
-- Messagerie recruteur ↔ joueur — voir PARTIE 8.4/8.5. Complète les tables
-- `scout_interests`/`scout_subscriptions` déjà prévues dans le schéma
-- initial mais jamais branchées à aucun flux (aucune interface recruteur
-- n'existait jusqu'ici).
--
-- Règle centrale : le contact avec un mineur n'est JAMAIS direct. Un
-- recruteur ne peut écrire à un joueur mineur qu'après approbation d'un
-- tuteur, via un lien à usage unique (le tuteur n'a pas nécessairement de
-- compte dans l'app). Sans email transactionnel configuré, ce lien est
-- transmis manuellement par le joueur lui-même (SMS/WhatsApp) plutôt que
-- simulé par un faux envoi automatique.

-- =========================================================================
-- handle_new_user — accepte désormais un `role` optionnel dans les
-- métadonnées d'inscription ('player' par défaut), avec allowlist stricte
-- pour qu'un client ne puisse jamais s'auto-attribuer 'admin' ou tout autre
-- rôle non prévu pour l'auto-inscription. Un compte recruteur ne reçoit pas
-- le bonus de bienvenue en Ballons (économie propre aux joueurs).
-- =========================================================================
create or replace function handle_new_user()
returns trigger as $$
declare
  v_role text := coalesce(new.raw_user_meta_data ->> 'role', 'player');
begin
  if v_role not in ('player', 'scout') then
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
-- guardian_contacts — table séparée de `profiles`, volontairement. `profiles`
-- a une policy "viewable by everyone" (RLS filtre des LIGNES, jamais des
-- COLONNES) : y ajouter l'email d'un tuteur l'aurait exposé publiquement à
-- quiconque consulte le Football Passport de n'importe quel joueur. Une
-- table à part, avec sa propre policy restreinte au joueur concerné,
-- élimine ce risque structurellement plutôt que de compter sur le client
-- pour ne simplement pas afficher le champ.
create table guardian_contacts (
  player_id uuid primary key references profiles (id) on delete cascade,
  guardian_name text,
  guardian_email text not null,
  updated_at timestamptz default now()
);

alter table guardian_contacts enable row level security;

create policy "Players manage their own guardian contact"
on guardian_contacts for all
using (auth.uid() = player_id)
with check (auth.uid() = player_id);

-- =========================================================================
-- conversations — une par (joueur, recruteur). Jamais écrite directement
-- par le client : uniquement via les fonctions SECURITY DEFINER ci-dessous,
-- pour imposer l'abonnement actif du recruteur et la médiation tuteur.
-- =========================================================================
create table conversations (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references profiles (id) on delete cascade,
  scout_id uuid not null references profiles (id) on delete cascade,
  status text not null default 'active',
  -- active, pending_guardian_approval, declined
  guardian_approval_token uuid default gen_random_uuid(),
  requested_at timestamptz default now(),
  approved_at timestamptz,
  last_message_at timestamptz,
  unique (player_id, scout_id)
);

create index idx_conversations_player on conversations (player_id);
create index idx_conversations_scout on conversations (scout_id);

alter table conversations enable row level security;

create policy "Participants can view own conversations"
on conversations for select
using (auth.uid() = player_id or auth.uid() = scout_id);

-- =========================================================================
-- messages
-- =========================================================================
create table messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references conversations (id) on delete cascade,
  sender_id uuid not null references profiles (id),
  body text not null,
  created_at timestamptz default now(),
  read_at timestamptz
);

create index idx_messages_conversation on messages (conversation_id, created_at);

alter table messages enable row level security;

create policy "Participants can view messages in own conversations"
on messages for select
using (
  exists (
    select 1 from conversations
    where conversations.id = messages.conversation_id
      and (conversations.player_id = auth.uid() or conversations.scout_id = auth.uid())
  )
);

-- Marquer un message reçu comme lu reste une simple mise à jour de colonne
-- (aucune logique économique/anti-triche en jeu) : une policy RLS directe
-- suffit, pas besoin de RPC. `sender_id != auth.uid()` empêche de marquer
-- ses propres messages comme lus.
create policy "Recipients can mark received messages as read"
on messages for update
using (
  sender_id != auth.uid()
  and exists (
    select 1 from conversations
    where conversations.id = messages.conversation_id
      and (conversations.player_id = auth.uid() or conversations.scout_id = auth.uid())
  )
)
with check (
  sender_id != auth.uid()
  and exists (
    select 1 from conversations
    where conversations.id = messages.conversation_id
      and (conversations.player_id = auth.uid() or conversations.scout_id = auth.uid())
  )
);

-- =========================================================================
-- request_scout_contact — un recruteur (abonnement actif requis) demande à
-- contacter un joueur. Date de naissance inconnue traitée comme mineure par
-- prudence (en pratique toujours renseignée à l'inscription).
-- =========================================================================
create or replace function request_scout_contact(p_player_id uuid)
returns jsonb as $$
declare
  v_scout_id uuid := auth.uid();
  v_scout_role text;
  v_has_active_sub boolean;
  v_birth_date date;
  v_guardian_email text;
  v_is_minor boolean;
  v_conversation_id uuid;
  v_status text;
begin
  if v_scout_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  if v_scout_id = p_player_id then
    raise exception 'Action invalide.' using errcode = 'P0001';
  end if;

  select role into v_scout_role from profiles where id = v_scout_id;
  if v_scout_role != 'scout' then
    raise exception 'Seul un compte recruteur peut contacter un joueur.'
      using errcode = 'P0001';
  end if;

  select exists (
    select 1 from scout_subscriptions
    where scout_id = v_scout_id and status = 'active'
      and (expires_at is null or expires_at > now())
  ) into v_has_active_sub;

  if not v_has_active_sub then
    raise exception 'Un abonnement actif est requis pour contacter un joueur.'
      using errcode = 'P0001';
  end if;

  select birth_date into v_birth_date
  from profiles where id = p_player_id and role = 'player';

  if not found then
    raise exception 'Joueur introuvable.' using errcode = 'P0001';
  end if;

  v_is_minor := v_birth_date is null or v_birth_date > (current_date - interval '18 years');

  if v_is_minor then
    select guardian_email into v_guardian_email
    from guardian_contacts where player_id = p_player_id;

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
  values (
    p_player_id, v_scout_id, v_status,
    case when v_status = 'active' then now() else null end
  )
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

-- =========================================================================
-- get_guardian_approval_token — réservée au joueur concerné : c'est lui qui
-- transmet ce lien à son tuteur (SMS/WhatsApp) faute d'email transactionnel
-- configuré. Le recruteur ne doit jamais pouvoir l'obtenir : la liste
-- générale des conversations (`getConversations`, côté client) ne
-- sélectionne jamais la colonne `guardian_approval_token`, cette fonction
-- est le seul chemin pour l'obtenir, et elle vérifie explicitement
-- `auth.uid() = player_id`.
-- =========================================================================
create or replace function get_guardian_approval_token(p_conversation_id uuid)
returns uuid as $$
declare
  v_token uuid;
begin
  select guardian_approval_token into v_token
  from conversations
  where id = p_conversation_id
    and player_id = auth.uid()
    and status = 'pending_guardian_approval';

  if v_token is null then
    raise exception 'Conversation introuvable ou déjà approuvée.' using errcode = 'P0001';
  end if;

  return v_token;
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function get_guardian_approval_token(uuid) to authenticated;

-- =========================================================================
-- approve_guardian_contact / decline_guardian_contact — actionnées via un
-- lien à usage unique connu du seul tuteur : ouvertes aussi à `anon` car le
-- tuteur n'a pas nécessairement de compte dans l'app. La seule protection
-- est la connaissance du jeton (uuid aléatoire, non énumérable).
-- =========================================================================
create or replace function approve_guardian_contact(p_token uuid)
returns jsonb as $$
declare
  v_conversation conversations%rowtype;
begin
  select * into v_conversation from conversations
  where guardian_approval_token = p_token and status = 'pending_guardian_approval';

  if v_conversation.id is null then
    raise exception 'Lien invalide ou déjà utilisé.' using errcode = 'P0001';
  end if;

  update conversations
  set status = 'active', approved_at = now()
  where id = v_conversation.id;

  insert into notifications (user_id, type, title, body, reference_type, reference_id)
  values (
    v_conversation.player_id, 'contact_approved', 'Contact approuvé',
    'Le contact avec le recruteur a été approuvé — vous pouvez échanger.',
    'conversation', v_conversation.id
  );
  insert into notifications (user_id, type, title, body, reference_type, reference_id)
  values (
    v_conversation.scout_id, 'contact_approved', 'Contact approuvé',
    'Le tuteur a approuvé le contact — vous pouvez échanger.',
    'conversation', v_conversation.id
  );

  return jsonb_build_object('approved', true, 'conversation_id', v_conversation.id);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function approve_guardian_contact(uuid) to authenticated, anon;

create or replace function decline_guardian_contact(p_token uuid)
returns jsonb as $$
declare
  v_conversation conversations%rowtype;
begin
  select * into v_conversation from conversations
  where guardian_approval_token = p_token and status = 'pending_guardian_approval';

  if v_conversation.id is null then
    raise exception 'Lien invalide ou déjà utilisé.' using errcode = 'P0001';
  end if;

  update conversations set status = 'declined' where id = v_conversation.id;

  return jsonb_build_object('declined', true);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function decline_guardian_contact(uuid) to authenticated, anon;

-- =========================================================================
-- send_message — unique canal d'écriture des messages : vérifie que
-- l'expéditeur appartient bien à la conversation et qu'elle est active
-- (jamais en attente d'approbation, jamais déclinée).
-- =========================================================================
create or replace function send_message(p_conversation_id uuid, p_body text)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_conversation conversations%rowtype;
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

  insert into messages (conversation_id, sender_id, body)
  values (p_conversation_id, v_user_id, trim(p_body))
  returning id into v_message_id;

  update conversations set last_message_at = now() where id = p_conversation_id;

  return jsonb_build_object('message_id', v_message_id);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function send_message(uuid, text) to authenticated;

-- =========================================================================
-- start_scout_trial — essai gratuit de 14 jours. En l'absence de moyen de
-- paiement réel branché (Stripe), un essai clairement gratuit et
-- fonctionnel est préférable à un faux bouton "S'abonner" qui ne
-- débiterait jamais personne (même principe que l'écran Boutique).
-- =========================================================================
create or replace function start_scout_trial()
returns jsonb as $$
declare
  v_scout_id uuid := auth.uid();
  v_scout_role text;
  v_existing boolean;
begin
  if v_scout_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  select role into v_scout_role from profiles where id = v_scout_id;
  if v_scout_role != 'scout' then
    raise exception 'Réservé aux comptes recruteurs.' using errcode = 'P0001';
  end if;

  select exists (
    select 1 from scout_subscriptions where scout_id = v_scout_id
  ) into v_existing;

  if v_existing then
    raise exception 'Tu as déjà utilisé ton essai gratuit.' using errcode = 'P0001';
  end if;

  insert into scout_subscriptions (scout_id, plan, status, expires_at)
  values (v_scout_id, 'trial', 'active', now() + interval '14 days');

  return jsonb_build_object('started', true);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function start_scout_trial() to authenticated;

-- =========================================================================
-- scout_search_players — recherche joueurs pour un recruteur. Ne renvoie
-- jamais la date de naissance exacte (seulement `is_minor`), cohérent avec
-- l'absence de géolocalisation précise déjà en place pour le Football
-- Passport public (protection des mineurs, PARTIE 8.4).
-- =========================================================================
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

  if not exists (select 1 from profiles where id = auth.uid() and role = 'scout') then
    raise exception 'Réservé aux comptes recruteurs.' using errcode = 'P0001';
  end if;

  return query
  select
    p.id, p.username, p.display_name, p.avatar_url, p.country, p.city, p.position,
    (p.birth_date is null or p.birth_date > (current_date - interval '18 years')),
    p.stars, p.level, p.followers_count
  from profiles p
  where p.role = 'player'
    and (p_query is null or p_query = '' or p.username ilike '%' || p_query || '%')
    and (p_position is null or p.position = p_position)
    and (p_country is null or p.country = p_country)
  order by p.stars desc
  limit 30;
end;
$$ language plpgsql stable security definer set search_path = public;

grant execute on function scout_search_players(text, text, text) to authenticated;


-- ===================== 20260101000014_sponsored_challenges.sql =====================
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


-- ===================== 20260101000015_hardening.sql =====================
-- =========================================================================
-- Durcissement : règles de suppression de compte, anti-triche vote, et
-- signalement de contenu.
--
-- Contexte : la suppression de compte (RGPD/App Store/Play Store) doit
-- réellement fonctionner. Or toute ligne dont la contrainte de clé
-- étrangère vers profiles(id) n'a pas de règle ON DELETE explicite bloque
-- la suppression avec une erreur Postgres peu lisible pour l'utilisateur
-- final. Ce fichier applique la distinction :
--   - "appartient au compte" (vidéo, like, commentaire...) -> déjà en
--     cascade depuis la migration initiale, rien à changer ici.
--   - "trace d'un événement passé" (qui a voté, qui a gagné, qui a créé
--     un défi, l'auteur d'une transaction...) -> on garde la ligne mais on
--     détache la référence à la personne (ON DELETE SET NULL). L'écriture
--     comptable ou l'historique de vote survit à la personne qui l'a
--     produite.
-- =========================================================================

-- -------------------------------------------------------------------------
-- challenges.creator_id — actuellement "not null ... on delete cascade" :
-- si le créateur supprime son compte, supprimer tout le défi effacerait
-- aussi les participations et votes des AUTRES joueurs, qui n'ont rien
-- demandé. On garde le défi (creator_id devient null, l'UI doit savoir
-- afficher "Créateur supprimé") et on détache seulement la référence.
-- -------------------------------------------------------------------------
alter table challenges alter column creator_id drop not null;
alter table challenges drop constraint challenges_creator_id_fkey;
alter table challenges
  add constraint challenges_creator_id_fkey
  foreign key (creator_id) references profiles (id) on delete set null;

-- -------------------------------------------------------------------------
-- challenge_votes.voter_id / participant_id — actuellement
-- "not null ... on delete cascade" : supprimer un vote parce que
-- l'électeur ou le participant a supprimé son compte fausserait
-- votes_count (déjà incrémenté ailleurs) pour tout le monde. On détache la
-- référence, le vote lui-même (et son effet sur le compteur) reste.
-- -------------------------------------------------------------------------
alter table challenge_votes alter column voter_id drop not null;
alter table challenge_votes drop constraint challenge_votes_voter_id_fkey;
alter table challenge_votes
  add constraint challenge_votes_voter_id_fkey
  foreign key (voter_id) references profiles (id) on delete set null;

alter table challenge_votes alter column participant_id drop not null;
alter table challenge_votes drop constraint challenge_votes_participant_id_fkey;
alter table challenge_votes
  add constraint challenge_votes_participant_id_fkey
  foreign key (participant_id) references profiles (id) on delete set null;

-- -------------------------------------------------------------------------
-- transactions.user_id — actuellement "not null ... on delete cascade" :
-- une transaction est une écriture comptable. Elle doit survivre à la
-- personne pour que le grand livre (somme des transactions == solde
-- affiché avant suppression) reste vérifiable après coup, et pour toute
-- obligation comptable/anti-fraude. Supprimer les transactions d'un compte
-- supprimé reviendrait à effacer une preuve d'audit.
-- -------------------------------------------------------------------------
alter table transactions alter column user_id drop not null;
alter table transactions drop constraint transactions_user_id_fkey;
alter table transactions
  add constraint transactions_user_id_fkey
  foreign key (user_id) references profiles (id) on delete set null;

-- -------------------------------------------------------------------------
-- challenges.opponent_id / record_holder_id / winner_id / sponsor_id —
-- déjà nullables mais sans règle de suppression explicite (donc "no
-- action" par défaut : Postgres refuserait la suppression du compte tant
-- qu'une de ces colonnes le référence). Même raisonnement que winner_id :
-- ce sont des résultats/rôles ponctuels sur un défi qui doit rester
-- consultable même si la personne concernée n'existe plus.
-- -------------------------------------------------------------------------
alter table challenges drop constraint challenges_opponent_id_fkey;
alter table challenges
  add constraint challenges_opponent_id_fkey
  foreign key (opponent_id) references profiles (id) on delete set null;

alter table challenges drop constraint challenges_record_holder_id_fkey;
alter table challenges
  add constraint challenges_record_holder_id_fkey
  foreign key (record_holder_id) references profiles (id) on delete set null;

alter table challenges drop constraint challenges_winner_id_fkey;
alter table challenges
  add constraint challenges_winner_id_fkey
  foreign key (winner_id) references profiles (id) on delete set null;

alter table challenges drop constraint challenges_sponsor_id_fkey;
alter table challenges
  add constraint challenges_sponsor_id_fkey
  foreign key (sponsor_id) references profiles (id) on delete set null;

-- -------------------------------------------------------------------------
-- notifications.actor_id — qui a déclenché la notif (ex : "X a aimé ta
-- vidéo"). Si X supprime son compte, la notification elle-même doit rester
-- lisible ("Quelqu'un a aimé ta vidéo" plutôt qu'une notif cassée), donc
-- SET NULL et pas CASCADE — ce n'est pas la notif du destinataire qui doit
-- disparaître.
-- -------------------------------------------------------------------------
alter table notifications drop constraint notifications_actor_id_fkey;
alter table notifications
  add constraint notifications_actor_id_fkey
  foreign key (actor_id) references profiles (id) on delete set null;

-- -------------------------------------------------------------------------
-- organizations.owner_id / messages.sender_id — actuellement "not null"
-- sans règle de suppression (bloquerait la suppression du compte). Ces
-- tables ne sont pas encore exposées dans l'app (organizations : aucune UI
-- ; messages : cascade déjà via conversations dans la grande majorité des
-- cas), mais on corrige quand même pour que la suppression de compte ne
-- puisse jamais échouer avec une erreur Postgres imprévisible plus tard.
-- -------------------------------------------------------------------------
alter table organizations alter column owner_id drop not null;
alter table organizations drop constraint organizations_owner_id_fkey;
alter table organizations
  add constraint organizations_owner_id_fkey
  foreign key (owner_id) references profiles (id) on delete set null;

alter table messages alter column sender_id drop not null;
alter table messages drop constraint messages_sender_id_fkey;
alter table messages
  add constraint messages_sender_id_fkey
  foreign key (sender_id) references profiles (id) on delete set null;

-- =========================================================================
-- Anti-triche : empêcher qu'un joueur vote pour lui-même.
--
-- Une policy RLS `with check (voter_id != participant_id)` existe déjà sur
-- l'insert direct (20260101000001_rls_policies.sql), mais elle ne protège
-- que l'écriture directe via PostgREST. Le vote passe en réalité par la
-- fonction SECURITY DEFINER `vote_for_participant`, qui insère elle-même
-- dans challenge_votes et n'est PAS soumise au `with check` de la table
-- (SECURITY DEFINER exécute avec les droits du propriétaire de la
-- fonction). Rien n'empêchait donc aujourd'hui d'appeler
-- vote_for_participant(défi, soi-même). On corrige à deux niveaux :
-- une contrainte CHECK au niveau table (dernière ligne de défense, vraie
-- même si un futur code contourne la fonction), et un rejet explicite dans
-- la fonction elle-même (message clair pour l'utilisateur au lieu d'une
-- violation de contrainte brute).
-- =========================================================================
alter table challenge_votes
  add constraint challenge_votes_no_self_vote
  check (voter_id is null or participant_id is null or voter_id != participant_id);

create or replace function vote_for_participant(p_challenge_id uuid, p_participant_id uuid)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_status text;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  if v_user_id = p_participant_id then
    raise exception 'Tu ne peux pas voter pour toi-même.' using errcode = 'P0001';
  end if;

  select status into v_status from challenges where id = p_challenge_id;
  if v_status is null then
    raise exception 'Défi introuvable.' using errcode = 'P0001';
  end if;

  if v_status not in ('active', 'voting') then
    raise exception 'Ce défi n''accepte plus de votes.' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from challenge_participations
    where challenge_id = p_challenge_id and user_id = p_participant_id
  ) then
    raise exception 'Ce participant n''existe pas dans ce défi.' using errcode = 'P0001';
  end if;

  insert into challenge_votes (challenge_id, voter_id, participant_id)
  values (p_challenge_id, v_user_id, p_participant_id);

  update challenge_participations
  set votes_count = votes_count + 1
  where challenge_id = p_challenge_id and user_id = p_participant_id;

  return jsonb_build_object('voted', true);
exception
  when unique_violation then
    raise exception 'Tu as déjà voté dans ce défi.' using errcode = 'P0001';
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- Décision documentée : un créateur PEUT participer à et remporter son
-- propre défi (Battle/Challenge/King). C'est un choix délibéré, pas un
-- oubli : join_challenge() ne l'a jamais interdit, et le code existant
-- (ex. écran de création) ne présuppose pas le contraire. Économiquement
-- ce n'est pas exploitable pour se créer de l'argent : le créateur paie
-- son propre droit d'entrée comme les autres, qui alimente la cagnotte
-- commune, et il ne peut gagner que ce que la cagnotte contient réellement
-- (voir resolve_expired_challenges). Au pire, un créateur seul participant
-- récupère exactement ce qu'il a lui-même mis, sans gain. Si ce choix
-- devait changer, il faudrait l'appliquer dans join_challenge() (rejeter
-- p_challenge_id dont creator_id = auth.uid()), pas seulement côté UI.
-- -------------------------------------------------------------------------

-- =========================================================================
-- content_reports — modération : signalement de vidéo, commentaire ou
-- profil par un utilisateur, traité ensuite par un compte role = 'admin'.
-- =========================================================================
create table content_reports (
  id uuid primary key default gen_random_uuid(),
  target_type text not null check (target_type in ('video', 'comment', 'profile')),
  target_id uuid not null,
  -- Trace, pas appartenance : si le signaleur supprime son compte, le
  -- signalement doit rester pour la modération, seule l'identité s'efface.
  reporter_id uuid references profiles (id) on delete set null,
  reason text not null,
  status text not null default 'pending'
    check (status in ('pending', 'reviewed', 'actioned', 'dismissed')),
  resolved_by uuid references profiles (id) on delete set null,
  resolution_note text,
  created_at timestamptz default now(),
  resolved_at timestamptz
);

create index idx_content_reports_status on content_reports (status);
create index idx_content_reports_target on content_reports (target_type, target_id);
create index idx_content_reports_reporter on content_reports (reporter_id);

alter table content_reports enable row level security;

create policy "Users can report content as themselves"
on content_reports for insert
with check (auth.uid() = reporter_id);

create policy "Users can view own reports"
on content_reports for select
using (auth.uid() = reporter_id);

create policy "Admins can view all reports"
on content_reports for select
using (
  exists (select 1 from profiles where id = auth.uid() and role = 'admin')
);

create policy "Admins can resolve reports"
on content_reports for update
using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'))
with check (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));


-- ===================== 20260101000016_welcome_bonus_on_confirmation.sql =====================
-- =========================================================================
-- Conditionner le bonus de bienvenue (500 Ballons) à une adresse e-mail
-- confirmée.
--
-- Jusqu'ici `handle_new_user()` créditait les 500 Ballons dès l'insertion
-- dans auth.users, c'est-à-dire dès la soumission du formulaire
-- d'inscription — avant toute confirmation d'e-mail. N'importe qui pouvait
-- donc créer un nombre illimité de comptes avec des adresses jetables et
-- accumuler des Ballons sans jamais confirmer aucune d'entre elles.
--
-- On distingue maintenant deux cas, pour rester correct que la
-- confirmation d'e-mail soit activée ou non côté Supabase Auth :
--   1. Si le compte est déjà confirmé au moment de l'insertion (email
--      confirmation désactivée en dev/test, ou fournisseur OAuth qui
--      confirme automatiquement) : le bonus est crédité immédiatement,
--      comme avant.
--   2. Sinon : `handle_new_user()` crée le profil avec 0 Ballon, et un
--      second trigger sur auth.users, déclenché seulement au moment où
--      `email_confirmed_at` passe de null à une valeur (clic sur le lien
--      reçu par e-mail), crédite alors les 500 Ballons.
-- Dans les deux cas, le bonus n'est jamais accordé deux fois : soit la
-- branche 1 l'a déjà fait à l'insertion et la branche 2 ne se déclenche
-- pas (email_confirmed_at était déjà non-null, la condition `old ... is
-- null` est fausse), soit l'inverse.
-- =========================================================================

create or replace function handle_new_user()
returns trigger as $$
declare
  v_role text := coalesce(new.raw_user_meta_data ->> 'role', 'player');
  v_already_confirmed boolean := new.email_confirmed_at is not null;
  v_initial_coins integer := case
    when v_role = 'player' and v_already_confirmed then 500
    else 0
  end;
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
    v_initial_coins
  );

  if v_initial_coins > 0 then
    insert into public.transactions (user_id, type, amount, currency, balance_after, reason)
    values (new.id, 'earn', v_initial_coins, 'coins', v_initial_coins, 'welcome_bonus');
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- Crédite le bonus de bienvenue au moment réel de la confirmation d'e-mail,
-- pour les comptes qui n'étaient pas déjà confirmés à l'inscription.
-- -------------------------------------------------------------------------
create or replace function handle_user_email_confirmed()
returns trigger as $$
declare
  v_new_balance integer;
begin
  update public.profiles
  set coins = coins + 500
  where id = new.id and role = 'player'
  returning coins into v_new_balance;

  if v_new_balance is not null then
    insert into public.transactions (user_id, type, amount, currency, balance_after, reason)
    values (new.id, 'earn', 500, 'coins', v_new_balance, 'welcome_bonus');
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_auth_user_email_confirmed on auth.users;

create trigger on_auth_user_email_confirmed
after update on auth.users
for each row
when (old.email_confirmed_at is null and new.email_confirmed_at is not null)
execute function handle_user_email_confirmed();


-- ===================== 20260101000017_local_timezone_daily_resets.sql =====================
-- =========================================================================
-- Fuseau horaire local pour tout ce qui touche à "aujourd'hui" : série de
-- connexion (streak_days), missions quotidiennes, plafonds journaliers
-- (vidéos postées, publicités regardées).
--
-- Jusqu'ici `current_date` était évalué côté serveur Postgres (fuseau du
-- serveur, en pratique UTC). Un joueur qui se connecte à 23h50 heure de
-- Paris (été, UTC+2) le voit déjà comme le lendemain en UTC ; à l'inverse
-- quelqu'un à Los Angeles (UTC-7/-8) voit encore "hier" bien après minuit
-- chez lui. Résultat concret : une série de connexions peut se casser à
-- tort, ou un plafond quotidien peut se réinitialiser au mauvais moment —
-- "Une série perdue à tort est la façon la plus sûre de perdre un
-- utilisateur fidèle."
--
-- Correctif : chaque RPC concernée accepte maintenant un paramètre
-- optionnel `p_local_date`, la date calendaire calculée côté client à
-- partir de l'heure locale de l'appareil (`DateTime.now()`, pas `.toUtc()`)
-- plutôt que côté serveur. Si absent (rétrocompatibilité, ancien client),
-- on retombe sur `current_date` — comportement identique à avant, jamais
-- pire.
--
-- Pour les plafonds quotidiens (vidéos postées, publicités regardées), on
-- ne compte plus les lignes de `transactions` depuis "minuit" (ce qui
-- recastait de toute façon la date en timestamptz à minuit *serveur*,
-- réintroduisant le même bug même avec la bonne date) : on utilise un
-- compteur dédié sur la ligne `daily_missions` du jour local concerné, qui
-- est déjà la bonne unité de "jour" une fois `p_local_date` en place.
-- =========================================================================

alter table daily_missions add column if not exists posts_count integer default 0;
alter table daily_missions add column if not exists ads_watched_count integer default 0;

-- `create or replace function` ne remplace une fonction que si sa signature
-- (types de paramètres) est identique. Ajouter un 3e paramètre change la
-- signature : sans ce `drop`, l'ancienne version à 2 paramètres resterait
-- appelable en parallèle (et un vieux client mis en cache la trouverait
-- toujours), avec `current_date` serveur jamais corrigé.
drop function if exists award_coins(text, uuid);
drop function if exists increment_videos_watched();

create or replace function award_coins(
  p_reason text,
  p_reference_id uuid default null,
  p_local_date date default null
)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_economy jsonb;
  v_amount integer;
  v_today date := coalesce(p_local_date, current_date);
  v_last_login date;
  v_streak integer;
  v_count_today integer;
  v_new_balance integer;
  v_streak_bonus integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  select value into v_economy from app_config where key = 'economy';

  if p_reason = 'daily_login' then
    select last_login_date, streak_days into v_last_login, v_streak
    from profiles where id = v_user_id for update;

    if v_last_login = v_today then
      raise exception 'Connexion quotidienne déjà réclamée aujourd''hui.' using errcode = 'P0001';
    end if;

    if v_last_login = v_today - 1 then
      v_streak := coalesce(v_streak, 0) + 1;
    else
      v_streak := 1;
    end if;

    v_amount := coalesce((v_economy ->> 'daily_login_max')::integer, 20);

    v_streak_bonus := case
      when v_streak = 7 then coalesce((v_economy ->> 'streak_7_days_bonus')::integer, 50)
      when v_streak = 30 then coalesce((v_economy ->> 'streak_30_days_bonus')::integer, 200)
      else 0
    end;
    v_amount := v_amount + v_streak_bonus;

    update profiles
    set coins = coins + v_amount,
        last_login_date = v_today,
        streak_days = v_streak
    where id = v_user_id
    returning coins into v_new_balance;

    insert into daily_missions (user_id, mission_date, login_completed, coins_earned)
    values (v_user_id, v_today, true, v_amount)
    on conflict (user_id, mission_date)
    do update set login_completed = true,
                  coins_earned = daily_missions.coins_earned + v_amount;

    if v_streak = 7 then
      insert into user_badges (user_id, badge_id)
      select v_user_id, id from badges where code = 'assidu_7'
      on conflict (user_id, badge_id) do nothing;
    elsif v_streak = 30 then
      insert into user_badges (user_id, badge_id)
      select v_user_id, id from badges where code = 'assidu_30'
      on conflict (user_id, badge_id) do nothing;
    end if;

  elsif p_reason = 'post_video' then
    select coalesce(posts_count, 0) into v_count_today
    from daily_missions
    where user_id = v_user_id and mission_date = v_today;

    if coalesce(v_count_today, 0) >= coalesce((v_economy ->> 'max_post_video_per_day')::integer, 3) then
      raise exception 'Limite quotidienne de récompenses vidéo atteinte.' using errcode = 'P0001';
    end if;

    v_amount := coalesce((v_economy ->> 'post_video')::integer, 5);

    update profiles set coins = coins + v_amount
    where id = v_user_id
    returning coins into v_new_balance;

    insert into daily_missions (user_id, mission_date, video_posted, coins_earned, posts_count)
    values (v_user_id, v_today, true, v_amount, 1)
    on conflict (user_id, mission_date)
    do update set video_posted = true,
                  coins_earned = daily_missions.coins_earned + v_amount,
                  posts_count = daily_missions.posts_count + 1;

  elsif p_reason = 'ad_watched' then
    select coalesce(ads_watched_count, 0) into v_count_today
    from daily_missions
    where user_id = v_user_id and mission_date = v_today;

    if coalesce(v_count_today, 0) >= coalesce((v_economy ->> 'max_ad_watched_per_day')::integer, 5) then
      raise exception 'Limite quotidienne de publicités atteinte.' using errcode = 'P0001';
    end if;

    v_amount := coalesce((v_economy ->> 'ad_watched')::integer, 30);

    update profiles set coins = coins + v_amount
    where id = v_user_id
    returning coins into v_new_balance;

    insert into daily_missions (user_id, mission_date, coins_earned, ads_watched_count)
    values (v_user_id, v_today, v_amount, 1)
    on conflict (user_id, mission_date)
    do update set coins_earned = daily_missions.coins_earned + v_amount,
                  ads_watched_count = daily_missions.ads_watched_count + 1;

  else
    raise exception 'Raison de récompense non prise en charge : %', p_reason using errcode = 'P0001';
  end if;

  insert into transactions (user_id, type, amount, currency, balance_after, reason, reference_id)
  values (v_user_id, 'earn', v_amount, 'coins', v_new_balance, p_reason, p_reference_id);

  return jsonb_build_object('new_balance', v_new_balance, 'amount_awarded', v_amount);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function award_coins(text, uuid, date) to authenticated;

create or replace function increment_videos_watched(p_local_date date default null)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_today date := coalesce(p_local_date, current_date);
  v_watched integer;
  v_bonus_awarded boolean := false;
  v_new_balance integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  insert into daily_missions (user_id, mission_date, videos_watched)
  values (v_user_id, v_today, 1)
  on conflict (user_id, mission_date)
  do update set videos_watched = daily_missions.videos_watched + 1
  returning videos_watched into v_watched;

  if v_watched = 3 then
    update profiles set coins = coins + 5
    where id = v_user_id
    returning coins into v_new_balance;

    update daily_missions set coins_earned = coins_earned + 5
    where user_id = v_user_id and mission_date = v_today;

    insert into transactions (user_id, type, amount, currency, balance_after, reason)
    values (v_user_id, 'earn', 5, 'coins', v_new_balance, 'daily_videos_watched');

    v_bonus_awarded := true;
  end if;

  return jsonb_build_object('videos_watched', v_watched, 'bonus_awarded', v_bonus_awarded);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function increment_videos_watched(date) to authenticated;


-- ===================== 20260101000018_ledger_reconciliation.sql =====================
-- =========================================================================
-- Grand livre : corriger une source de dérive réelle, et ajouter une
-- requête de contrôle pour en détecter d'autres proactivement.
--
-- "Elle insère dans transactions et met à jour le solde, dans la même
-- transaction. Aucun autre chemin n'a le droit de toucher coins ou stars."
-- — vrai pour award_coins/spend_coins/join_challenge/create_challenge,
-- vérifié. FAUX pour un cas trouvé en auditant resolve_expired_challenges :
-- le bonus de 100 Stars versé au vainqueur d'un défi
-- (`set stars = stars + 100 ...`) ne générait AUCUNE ligne dans
-- `transactions`, contrairement au prize_pool en Ballons juste au-dessus
-- dans la même fonction, qui lui insère bien sa transaction. Résultat :
-- `profiles.stars` divergeait silencieusement et définitivement de la
-- somme du grand livre à chaque défi résolu, sans qu'aucun bug applicatif
-- ne le déclenche jamais — c'est une omission structurelle, pas une race
-- condition. On la corrige ici, et le Wallet peut désormais aussi
-- afficher "+100 ⭐ Défi remporté" dans l'historique, ce qu'il ne pouvait
-- pas faire avant faute de transaction.
-- =========================================================================

create or replace function resolve_expired_challenges()
returns integer as $$
declare
  v_challenge record;
  v_winner_user_id uuid;
  v_new_balance integer;
  v_new_stars integer;
  v_resolved_count integer := 0;
  v_rank integer;
  v_participation record;
begin
  for v_challenge in
    select * from challenges
    where status = 'active' and end_date < now()
  loop
    v_winner_user_id := null;

    if v_challenge.type = 'king' then
      v_winner_user_id := v_challenge.record_holder_id;
    else
      select user_id into v_winner_user_id
      from challenge_participations
      where challenge_id = v_challenge.id
      order by votes_count desc, created_at asc
      limit 1;

      v_rank := 1;
      for v_participation in
        select id from challenge_participations
        where challenge_id = v_challenge.id
        order by votes_count desc, created_at asc
      loop
        update challenge_participations set rank = v_rank where id = v_participation.id;
        v_rank := v_rank + 1;
      end loop;
    end if;

    if v_winner_user_id is not null then
      if v_challenge.prize_pool > 0 and v_challenge.prize_currency = 'coins' then
        update profiles set coins = coins + v_challenge.prize_pool
        where id = v_winner_user_id
        returning coins into v_new_balance;

        insert into transactions (
          user_id, type, amount, currency, balance_after, reason,
          reference_type, reference_id
        ) values (
          v_winner_user_id, 'earn', v_challenge.prize_pool, 'coins', v_new_balance,
          'win_challenge', 'challenge', v_challenge.id
        );
      end if;

      update profiles
      set stars = stars + 100, challenges_won_count = challenges_won_count + 1
      where id = v_winner_user_id
      returning stars into v_new_stars;

      insert into transactions (
        user_id, type, amount, currency, balance_after, reason,
        reference_type, reference_id
      ) values (
        v_winner_user_id, 'earn', 100, 'stars', v_new_stars,
        'win_challenge', 'challenge', v_challenge.id
      );

      insert into notifications (user_id, type, title, body, reference_type, reference_id)
      values (
        v_winner_user_id, 'challenge_won', 'Défi remporté !',
        'Tu as remporté "' || v_challenge.title || '" 🏆',
        'challenge', v_challenge.id
      );
    end if;

    update challenges
    set status = 'completed', winner_id = v_winner_user_id
    where id = v_challenge.id;

    v_resolved_count := v_resolved_count + 1;
  end loop;

  return v_resolved_count;
end;
$$ language plpgsql security definer set search_path = public;

-- =========================================================================
-- find_ledger_drift — compare le solde stocké (profiles.coins/stars) à la
-- somme du grand livre (transactions) pour chaque utilisateur et chaque
-- devise, et ne retourne QUE les lignes qui divergent. Réservée aux
-- administrateurs (expose le solde de tout le monde) : à exécuter
-- périodiquement (cron externe, ou manuellement dans le SQL Editor) pour
-- détecter au plus tôt tout futur chemin qui modifierait coins/stars sans
-- passer par une transaction.
--
-- `user_id is not null` exclut volontairement les transactions dont
-- l'auteur a supprimé son compte (transactions.user_id passe à null via
-- ON DELETE SET NULL, voir 20260101000015_hardening.sql) : ces lignes ne
-- peuvent plus être rapprochées d'un profil, ce n'est pas une dérive.
-- =========================================================================
create or replace function find_ledger_drift()
returns table (
  user_id uuid,
  currency text,
  stored_balance integer,
  ledger_sum bigint,
  drift bigint
) as $$
begin
  if not exists (
    select 1 from profiles where id = auth.uid() and role = 'admin'
  ) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;

  return query
  select p.id, 'coins'::text, p.coins, coalesce(t.ledger_sum, 0::bigint),
         p.coins::bigint - coalesce(t.ledger_sum, 0::bigint)
  from profiles p
  left join (
    select transactions.user_id, sum(amount) as ledger_sum
    from transactions
    where currency = 'coins' and user_id is not null
    group by transactions.user_id
  ) t on t.user_id = p.id
  where p.coins != coalesce(t.ledger_sum, 0)

  union all

  select p.id, 'stars'::text, p.stars, coalesce(t.ledger_sum, 0::bigint),
         p.stars::bigint - coalesce(t.ledger_sum, 0::bigint)
  from profiles p
  left join (
    select transactions.user_id, sum(amount) as ledger_sum
    from transactions
    where currency = 'stars' and user_id is not null
    group by transactions.user_id
  ) t on t.user_id = p.id
  where p.stars != coalesce(t.ledger_sum, 0);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function find_ledger_drift() to authenticated;


-- ===================== 20260101000019_canonical_values.sql =====================
-- =========================================================================
-- Valeurs canoniques : les colonnes `text` à valeurs contraintes
-- (statuts, types, rôles...) n'avaient jusqu'ici qu'un commentaire SQL à
-- titre indicatif — rien n'empêchait la base d'accepter une valeur
-- inventée ou mal orthographiée insérée par un futur bug (le commentaire
-- n'est pas exécuté). On transforme chaque liste déjà documentée en une
-- vraie contrainte CHECK : la base rejette désormais toute valeur hors
-- de la liste, au lieu de silencieusement l'accepter et de casser un
-- switch/case côté Flutter qui ne la reconnaît pas.
--
-- Chaque liste ci-dessous a été vérifiée contre l'usage réel dans les
-- migrations et le code Flutter (pas seulement recopiée depuis le
-- commentaire d'origine) — deux écarts trouvés au passage :
--   - `scout_subscriptions.plan` : le commentaire d'origine annonçait
--     "basic, pro, elite" mais `start_scout_trial()` insère en réalité
--     'trial', qui n'était dans aucune liste. Ajouté.
--   - `profiles.role` : le commentaire d'origine listait aussi 'creator',
--     'coach', 'club', 'academy' — mais aucun code n'assigne jamais ces
--     valeurs (le trigger `handle_new_user` limite déjà à
--     player/scout/brand, et retombe sur 'player' sinon) et aucun écran
--     ne sait les afficher. Les inclure dans la contrainte laisserait un
--     compte atterrir dans un rôle qu'aucun code ne comprend. Restreint
--     ici à ce qui existe réellement (player/scout/brand/admin) ; à
--     élargir dans une future migration quand les comptes Club/Académie
--     seront réellement implémentés (voir HANDOFF.md section 2.2).
-- =========================================================================

alter table profiles
  add constraint profiles_role_check
  check (role in ('player', 'scout', 'brand', 'admin'));

alter table profiles
  add constraint profiles_position_check
  check (position is null or position in ('attaquant', 'milieu', 'defenseur', 'gardien'));

alter table profiles
  add constraint profiles_preferred_foot_check
  check (preferred_foot in ('gauche', 'droit', 'les_deux'));

alter table profiles
  add constraint profiles_level_check
  check (level in ('rookie', 'rising_star', 'prodigy', 'legend'));

alter table profiles
  add constraint profiles_verification_type_check
  check (
    verification_type is null
    or verification_type in ('talent', 'official_club', 'official_academy', 'brand')
  );

alter table videos
  add constraint videos_category_check
  check (category in (
    'dribble', 'shot', 'pass', 'control', 'freestyle', 'celebration', 'defense', 'goalkeeper'
  ));

alter table videos
  add constraint videos_status_check
  check (status in ('active', 'under_review', 'removed', 'flagged'));

alter table likes
  add constraint likes_type_check
  check (type in ('like', 'masterclass'));

alter table comments
  add constraint comments_status_check
  check (status in ('active', 'under_review', 'removed'));

alter table challenges
  add constraint challenges_type_check
  check (type in ('battle', 'challenge', 'king', 'world', 'sponsored'));

alter table challenges
  add constraint challenges_status_check
  check (status in ('draft', 'active', 'voting', 'completed', 'cancelled'));

alter table challenges
  add constraint challenges_prize_currency_check
  check (prize_currency in ('coins', 'real'));

alter table transactions
  add constraint transactions_type_check
  check (type in ('earn', 'spend', 'purchase', 'refund'));

alter table transactions
  add constraint transactions_currency_check
  check (currency in ('coins', 'stars'));

alter table notifications
  add constraint notifications_type_check
  check (type in (
    'new_follower', 'like', 'masterclass', 'comment', 'move_reproduced',
    'badge_earned', 'challenge_won', 'scout_interest', 'contact_approved'
  ));

alter table conversations
  add constraint conversations_status_check
  check (status in ('active', 'pending_guardian_approval', 'declined'));

alter table scout_interests
  add constraint scout_interests_status_check
  check (status in ('interested', 'contacted', 'shortlisted'));

alter table scout_subscriptions
  add constraint scout_subscriptions_plan_check
  check (plan in ('trial', 'basic', 'pro', 'elite'));

alter table scout_subscriptions
  add constraint scout_subscriptions_status_check
  check (status in ('active'));

alter table organizations
  add constraint organizations_type_check
  check (type in ('club', 'academy'));

alter table organization_members
  add constraint organization_members_role_check
  check (role in ('player', 'coach', 'staff'));


-- ===================== 20260101000020_account_deletion.sql =====================
-- =========================================================================
-- Suppression réelle de compte (obligation légale — RGPD, exigence
-- App Store/Play Store). "Supprimer réellement, pas marquer supprimé" :
-- une colonne `deleted_at`/`is_deleted` laisserait la ligne `auth.users`
-- (et donc l'adresse e-mail) définitivement prise, empêchant la personne
-- de jamais recréer un compte avec la même adresse, et laissant ses
-- données réellement en base malgré la demande de suppression.
--
-- Choix d'implémentation : une fonction Postgres SECURITY DEFINER qui fait
-- `delete from auth.users where id = auth.uid()`, plutôt qu'un appel à
-- l'API d'administration Supabase (`auth.admin.deleteUser`, qui nécessite
-- la clé service-role et donc une Edge Function). Ce choix suit le même
-- principe que le reste du projet (RPC Postgres SECURITY DEFINER plutôt
-- que Deno, voir README) et s'appuie sur une contrainte déjà en place :
-- `profiles.id references auth.users(id) on delete cascade`
-- (20260101000000_initial_schema.sql). Supprimer la ligne `auth.users`
-- cascade donc automatiquement vers `profiles`, puis vers tout ce qui a
-- été mis en cascade sur `profiles.id` (vidéos, likes, commentaires,
-- participations, badges, missions, notifications...), et détache (SET
-- NULL) tout ce qui doit survivre comme trace (transactions, votes,
-- défis créés/gagnés — voir 20260101000015_hardening.sql).
--
-- Limite connue, à documenter pour le développeur qui reprend le projet :
-- le rôle propriétaire de cette fonction doit avoir le droit de DELETE sur
-- `auth.users` — c'est le cas par défaut pour le rôle `postgres` sur la
-- plupart des projets Supabase actuels, mais si ce n'est pas le cas sur le
-- projet de production (permissions Supabase parfois durcies), l'appel
-- échouera avec une erreur de permission explicite plutôt que de
-- supprimer partiellement le compte (tout se passe dans une seule
-- transaction : soit tout est supprimé, soit rien ne l'est). Solution de
-- repli documentée si besoin : Edge Function côté serveur appelant
-- `auth.admin.deleteUser` avec la clé service-role.
--
-- Nettoyage du Storage : les fichiers (vidéos, miniatures, avatars) sont
-- rangés sous `<bucket>/<user_id>/...` (convention déjà utilisée par les
-- policies RLS de storage.objects, voir
-- 20260101000004_storage_and_reactions.sql). On supprime ici les lignes
-- `storage.objects` correspondantes avant de supprimer le compte, pour
-- qu'aucune vidéo ou avatar d'un compte supprimé ne reste accessible par
-- URL publique ou signée.
-- =========================================================================
create or replace function delete_my_account()
returns void as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  delete from storage.objects
  where bucket_id = any (array['videos', 'thumbnails', 'avatars'])
    and (storage.foldername(name)) [1] = v_user_id::text;

  delete from auth.users where id = v_user_id;
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function delete_my_account() to authenticated;


-- ===================== 20260101000021_security_audit_fixes.sql =====================
-- =========================================================================
-- Audit de sécurité (octobre 2026) — corrections vérifiées sur une vraie
-- instance Supabase locale (`supabase start` + appels HTTP réels comme le
-- ferait un client malveillant), pas seulement relues.
--
-- Chaque bloc ci-dessous corrige un problème reproduit avant correctif :
--   1. Follow / like / commentaire / publication de vidéo échouaient tous
--      ("permission denied for table profiles") : les triggers de
--      compteurs s'exécutaient avec les droits du client, privé de UPDATE
--      sur ces colonnes depuis 20260101000009.
--   2. `p_local_date` libre : réclamer le bonus de connexion / publicité
--      avec 10 dates inventées a crédité +550 Ballons en une seconde.
--   3. `create_challenge(p_prize_pool => 1000000)` créait une cagnotte de
--      1 000 000 de Ballons sans rien débiter.
--   4. N'importe qui (même non connecté) lisait la date de naissance
--      exacte de tous les joueurs, mineurs compris.
--   5. Un recruteur lisait `guardian_approval_token` dans ses propres
--      conversations et approuvait lui-même le contact avec un mineur.
--   6. `increment_video_views` appelable en boucle : 100 appels = 1 Star.
--  13. Les classements mélangeaient joueurs, recruteurs et marques
--      (corrigé côté app : filtre role = 'player').
--   7. Insertion de vidéo avec views_count/likes_count/talent_score/
--      is_boosted/status choisis par le client.
--   8. Mise à jour libre des notifications, commentaires (likes_count,
--      status), messages reçus (body) par leurs destinataires.
--   9. `delete_my_account` échouait toujours : Supabase interdit le DELETE
--      direct dans storage.objects (les fichiers sont supprimés par l'app
--      via l'API Storage avant l'appel, voir AuthRemoteDataSource).
--  10. `resolve_expired_challenges` exécutable par anon/authenticated
--      (droit EXECUTE par défaut sur PUBLIC).
--  11. Modération : "Agir" sur un signalement ne retirait jamais le
--      contenu (seul le statut du signalement changeait).
--  12. Basculer un like en Masterclass échouait (aucune policy UPDATE).
-- =========================================================================

-- -------------------------------------------------------------------------
-- 1. Triggers de compteurs : SECURITY DEFINER (ils touchent les lignes
--    d'AUTRES utilisateurs, ce que RLS et les droits colonnes interdisent
--    à juste titre au client).
-- -------------------------------------------------------------------------
alter function handle_new_follow() security definer set search_path = public;
alter function handle_unfollow() security definer set search_path = public;
alter function handle_new_like() security definer set search_path = public;
alter function handle_remove_like() security definer set search_path = public;
alter function handle_like_type_change() security definer set search_path = public;
alter function handle_new_comment() security definer set search_path = public;

-- Le compteur de commentaires ne redescendait jamais à la suppression.
create or replace function handle_remove_comment()
returns trigger as $$
begin
  update videos set comments_count = greatest(comments_count - 1, 0)
  where id = old.video_id;
  return old;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists trigger_remove_comment on comments;
create trigger trigger_remove_comment
after delete on comments
for each row
execute function handle_remove_comment();

-- Idem pour le compteur de vidéos du profil.
create or replace function handle_remove_video()
returns trigger as $$
begin
  update profiles set videos_count = greatest(videos_count - 1, 0)
  where id = old.user_id;
  if old.is_move then
    update profiles set moves_created_count = greatest(moves_created_count - 1, 0)
    where id = old.user_id;
  end if;
  return old;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists trigger_remove_video on videos;
create trigger trigger_remove_video
after delete on videos
for each row
execute function handle_remove_video();

-- Nouvelle vidéo : la récompense "Move reproduit" n'est versée que si la
-- vidéo d'origine est réellement un Move, et une seule fois par couple
-- (reproducteur, Move) — sinon un ami pouvait publier 1 000 "reproductions"
-- du même Move pour créditer 1 000 Ballons à l'inventeur.
create or replace function handle_new_video()
returns trigger as $$
declare
  v_original_creator_id uuid;
  v_original_is_move boolean;
  v_new_balance integer;
  v_already_reproduced boolean;
begin
  update profiles set videos_count = videos_count + 1
  where id = new.user_id;

  if new.is_move then
    update profiles set moves_created_count = moves_created_count + 1
    where id = new.user_id;
  end if;

  if new.original_move_id is not null then
    select user_id, coalesce(is_move, false)
      into v_original_creator_id, v_original_is_move
    from videos where id = new.original_move_id;

    if not coalesce(v_original_is_move, false) then
      return new;
    end if;

    update videos set reproductions_count = reproductions_count + 1
    where id = new.original_move_id;

    select exists (
      select 1 from videos
      where user_id = new.user_id
        and original_move_id = new.original_move_id
        and id != new.id
    ) into v_already_reproduced;

    if v_original_creator_id is not null
       and v_original_creator_id != new.user_id
       and not v_already_reproduced then
      update profiles set coins = coins + 1
      where id = v_original_creator_id
      returning coins into v_new_balance;

      insert into transactions (
        user_id, type, amount, currency, balance_after, reason,
        reference_type, reference_id
      ) values (
        v_original_creator_id, 'earn', 1, 'coins', v_new_balance, 'move_reproduced',
        'video', new.id
      );
    end if;
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 2. Dates locales bornées. Les fuseaux réels vont de UTC-12 à UTC+14 : la
--    date locale d'un appareil honnête est donc toujours la date UTC du
--    jour, la veille ou le lendemain. Toute autre valeur est rejetée. Le
--    bonus de connexion exige en plus une date strictement postérieure à
--    la dernière réclamée (on ne peut plus "revenir" à une date passée).
-- -------------------------------------------------------------------------
create or replace function resolve_local_date(p_local_date date)
returns date as $$
declare
  v_utc_today date := (now() at time zone 'utc')::date;
begin
  if p_local_date is null then
    return v_utc_today;
  end if;
  if p_local_date < v_utc_today - 1 or p_local_date > v_utc_today + 1 then
    raise exception 'Date de l''appareil invalide. Vérifie la date et l''heure de ton téléphone.'
      using errcode = 'P0001';
  end if;
  return p_local_date;
end;
$$ language plpgsql stable set search_path = public;

create or replace function award_coins(
  p_reason text,
  p_reference_id uuid default null,
  p_local_date date default null
)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_economy jsonb;
  v_amount integer;
  v_today date;
  v_last_login date;
  v_streak integer;
  v_count_today integer;
  v_new_balance integer;
  v_streak_bonus integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  v_today := resolve_local_date(p_local_date);

  select value into v_economy from app_config where key = 'economy';

  if p_reason = 'daily_login' then
    select last_login_date, streak_days into v_last_login, v_streak
    from profiles where id = v_user_id for update;

    if v_last_login is not null and v_today <= v_last_login then
      raise exception 'Connexion quotidienne déjà réclamée aujourd''hui.' using errcode = 'P0001';
    end if;

    if v_last_login = v_today - 1 then
      v_streak := coalesce(v_streak, 0) + 1;
    else
      v_streak := 1;
    end if;

    v_amount := coalesce((v_economy ->> 'daily_login_max')::integer, 20);

    v_streak_bonus := case
      when v_streak = 7 then coalesce((v_economy ->> 'streak_7_days_bonus')::integer, 50)
      when v_streak = 30 then coalesce((v_economy ->> 'streak_30_days_bonus')::integer, 200)
      else 0
    end;
    v_amount := v_amount + v_streak_bonus;

    update profiles
    set coins = coins + v_amount,
        last_login_date = v_today,
        streak_days = v_streak
    where id = v_user_id
    returning coins into v_new_balance;

    insert into daily_missions (user_id, mission_date, login_completed, coins_earned)
    values (v_user_id, v_today, true, v_amount)
    on conflict (user_id, mission_date)
    do update set login_completed = true,
                  coins_earned = daily_missions.coins_earned + v_amount;

    if v_streak = 7 then
      insert into user_badges (user_id, badge_id)
      select v_user_id, id from badges where code = 'assidu_7'
      on conflict (user_id, badge_id) do nothing;
    elsif v_streak = 30 then
      insert into user_badges (user_id, badge_id)
      select v_user_id, id from badges where code = 'assidu_30'
      on conflict (user_id, badge_id) do nothing;
    end if;

  elsif p_reason = 'post_video' then
    -- La récompense doit désigner une vraie vidéo du joueur, publiée dans
    -- les dernières 24 h, et jamais déjà récompensée.
    if p_reference_id is null or not exists (
      select 1 from videos
      where id = p_reference_id
        and user_id = v_user_id
        and created_at > now() - interval '24 hours'
    ) then
      raise exception 'Vidéo introuvable pour cette récompense.' using errcode = 'P0001';
    end if;

    if exists (
      select 1 from transactions
      where user_id = v_user_id and reason = 'post_video' and reference_id = p_reference_id
    ) then
      raise exception 'Récompense déjà reçue pour cette vidéo.' using errcode = 'P0001';
    end if;

    select coalesce(posts_count, 0) into v_count_today
    from daily_missions
    where user_id = v_user_id and mission_date = v_today;

    if coalesce(v_count_today, 0) >= coalesce((v_economy ->> 'max_post_video_per_day')::integer, 3) then
      raise exception 'Limite quotidienne de récompenses vidéo atteinte.' using errcode = 'P0001';
    end if;

    v_amount := coalesce((v_economy ->> 'post_video')::integer, 5);

    update profiles set coins = coins + v_amount
    where id = v_user_id
    returning coins into v_new_balance;

    insert into daily_missions (user_id, mission_date, video_posted, coins_earned, posts_count)
    values (v_user_id, v_today, true, v_amount, 1)
    on conflict (user_id, mission_date)
    do update set video_posted = true,
                  coins_earned = daily_missions.coins_earned + v_amount,
                  posts_count = daily_missions.posts_count + 1;

  elsif p_reason = 'ad_watched' then
    -- Aucune régie publicitaire n'est branchée : rien ne prouve qu'une pub
    -- a été vue. Désactivé tant qu'une vérification serveur (callback de la
    -- régie) n'existe pas — sinon 150 Ballons gratuits par jour et par
    -- compte via un simple appel HTTP.
    raise exception 'Les récompenses publicitaires ne sont pas encore disponibles.'
      using errcode = 'P0001';

  else
    raise exception 'Raison de récompense non prise en charge : %', p_reason using errcode = 'P0001';
  end if;

  insert into transactions (user_id, type, amount, currency, balance_after, reason, reference_id)
  values (v_user_id, 'earn', v_amount, 'coins', v_new_balance, p_reason, p_reference_id);

  return jsonb_build_object('new_balance', v_new_balance, 'amount_awarded', v_amount);
end;
$$ language plpgsql security definer set search_path = public;

create or replace function increment_videos_watched(p_local_date date default null)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_today date;
  v_watched integer;
  v_bonus_awarded boolean := false;
  v_new_balance integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  v_today := resolve_local_date(p_local_date);

  insert into daily_missions (user_id, mission_date, videos_watched)
  values (v_user_id, v_today, 1)
  on conflict (user_id, mission_date)
  do update set videos_watched = daily_missions.videos_watched + 1
  returning videos_watched into v_watched;

  if v_watched = 3 then
    update profiles set coins = coins + 5
    where id = v_user_id
    returning coins into v_new_balance;

    update daily_missions set coins_earned = coins_earned + 5
    where user_id = v_user_id and mission_date = v_today;

    insert into transactions (user_id, type, amount, currency, balance_after, reason)
    values (v_user_id, 'earn', 5, 'coins', v_new_balance, 'daily_videos_watched');

    v_bonus_awarded := true;
  end if;

  return jsonb_build_object('videos_watched', v_watched, 'bonus_awarded', v_bonus_awarded);
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 3. create_challenge : la cagnotte d'un défi joueur part TOUJOURS de 0 et
--    n'est alimentée que par les droits d'entrée (join_challenge). Le
--    paramètre `p_prize_pool` est conservé pour ne pas casser la signature
--    appelée par l'app, mais ignoré. Ajout de bornes sur les champs libres.
-- -------------------------------------------------------------------------
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

  if p_title is null or char_length(trim(p_title)) < 3 or char_length(p_title) > 80 then
    raise exception 'Le titre doit faire entre 3 et 80 caractères.' using errcode = 'P0001';
  end if;

  if char_length(coalesce(p_description, '')) > 1000 then
    raise exception 'La description est trop longue (1000 caractères max).' using errcode = 'P0001';
  end if;

  if p_end_date <= now() then
    raise exception 'La date de fin doit être dans le futur.' using errcode = 'P0001';
  end if;

  if p_end_date > now() + interval '60 days' then
    raise exception 'Un défi ne peut pas durer plus de 60 jours.' using errcode = 'P0001';
  end if;

  if p_max_participants is not null and (p_max_participants < 2 or p_max_participants > 10000) then
    raise exception 'Nombre de participants invalide.' using errcode = 'P0001';
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
      v_user_id, trim(p_title), p_description, 'sponsored', p_category, 0, 0,
      'real', left(p_prize_description, 500), v_user_id, v_sponsor_name,
      p_max_participants, p_end_date, 'active'
    )
    returning id into v_challenge_id;

    return jsonb_build_object('challenge_id', v_challenge_id);
  end if;

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
    v_user_id, trim(p_title), p_description, p_type, p_category, v_entry_cost, 0,
    p_max_participants, left(p_record_unit, 30), p_end_date, 'active'
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

-- -------------------------------------------------------------------------
-- 4. Date de naissance : plus jamais lisible par les autres. Les droits
--    SELECT sont accordés colonne par colonne, sans `birth_date`. Le joueur
--    lit son propre profil complet via `get_my_profile()`.
-- -------------------------------------------------------------------------
revoke select on profiles from anon, authenticated;
grant select (
  id, username, display_name, avatar_url, bio, country, city, position,
  preferred_foot, height_cm, weight_kg, role, is_verified, verification_type,
  coins, stars, level, iq_technique, iq_creativity, iq_popularity,
  iq_consistency, iq_tactical, streak_days, last_login_date, followers_count,
  following_count, videos_count, moves_created_count, likes_received_count,
  challenges_won_count, created_at, updated_at
) on profiles to anon, authenticated;

create or replace function get_my_profile()
returns setof profiles as $$
  select * from profiles where id = auth.uid();
$$ language sql stable security definer set search_path = public;

revoke execute on function get_my_profile() from public, anon;
grant execute on function get_my_profile() to authenticated;

-- -------------------------------------------------------------------------
-- 5. Le jeton d'approbation tuteur n'est plus lisible via la table : seul
--    `get_guardian_approval_token()` (réservée au joueur) le renvoie.
-- -------------------------------------------------------------------------
revoke select on conversations from anon, authenticated;
grant select (
  id, player_id, scout_id, status, requested_at, approved_at, last_message_at
) on conversations to authenticated;
revoke insert, update, delete on conversations from anon, authenticated;

-- -------------------------------------------------------------------------
-- 6. Vues dédupliquées : une vue compte au plus une fois par spectateur,
--    par vidéo et par jour, et jamais sur sa propre vidéo.
-- -------------------------------------------------------------------------
-- Rangée dans un schéma `private` non exposé par l'API : une table
-- reliant videos et profiles dans `public` rendrait ambiguës les jointures
-- `creator:profiles(...)` de l'app (erreur PGRST201).
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists private.video_views (
  video_id uuid not null references public.videos (id) on delete cascade,
  viewer_id uuid not null references public.profiles (id) on delete cascade,
  view_date date not null default ((now() at time zone 'utc')::date),
  primary key (video_id, viewer_id, view_date)
);

alter table private.video_views enable row level security;

create or replace function increment_video_views(p_video_id uuid)
returns void as $$
declare
  v_viewer_id uuid := auth.uid();
  v_creator_id uuid;
  v_new_views integer;
  v_inserted integer;
begin
  if v_viewer_id is null then
    return;
  end if;

  select user_id into v_creator_id
  from videos where id = p_video_id and status = 'active';

  if v_creator_id is null or v_creator_id = v_viewer_id then
    return;
  end if;

  insert into private.video_views (video_id, viewer_id)
  values (p_video_id, v_viewer_id)
  on conflict do nothing;
  get diagnostics v_inserted = row_count;

  if v_inserted = 0 then
    return;
  end if;

  update videos
  set views_count = views_count + 1
  where id = p_video_id
  returning views_count into v_new_views;

  if v_new_views % 100 = 0 then
    update profiles set stars = stars + 1 where id = v_creator_id
    returning stars into v_new_views;

    insert into transactions (
      user_id, type, amount, currency, balance_after, reason, reference_type, reference_id
    ) values (
      v_creator_id, 'earn', 1, 'stars', v_new_views, 'video_views_milestone', 'video', p_video_id
    );
  end if;
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 7/8. Droits colonne par colonne en écriture : le client ne peut écrire
--      que les champs "éditoriaux", jamais les compteurs, scores, statuts
--      de modération ou champs de vérification.
-- -------------------------------------------------------------------------
revoke insert on videos from anon, authenticated;
grant insert (
  user_id, video_url, thumbnail_url, duration_seconds, caption, category,
  is_move, move_name, move_slug, original_move_id
) on videos to authenticated;

-- Une vidéo doit pointer vers le dossier Storage de son auteur (pas vers
-- un site externe arbitraire).
create or replace function check_video_urls()
returns trigger as $$
begin
  if new.video_url not like '%/storage/v1/object/public/videos/' || new.user_id::text || '/%' then
    raise exception 'URL de vidéo invalide.' using errcode = 'P0001';
  end if;
  if new.thumbnail_url is not null
     and new.thumbnail_url not like '%/storage/v1/object/public/thumbnails/' || new.user_id::text || '/%' then
    raise exception 'URL de miniature invalide.' using errcode = 'P0001';
  end if;
  return new;
end;
$$ language plpgsql set search_path = public;

drop trigger if exists trigger_check_video_urls on videos;
create trigger trigger_check_video_urls
before insert on videos
for each row
execute function check_video_urls();

revoke insert, update on comments from anon, authenticated;
grant insert (user_id, video_id, parent_id, content) on comments to authenticated;
grant update (content) on comments to authenticated;

revoke update on notifications from anon, authenticated;
grant update (is_read) on notifications to authenticated;
revoke insert, delete on notifications from anon, authenticated;

revoke update on messages from anon, authenticated;
grant update (read_at) on messages to authenticated;
revoke insert, delete on messages from anon, authenticated;

revoke insert, update on likes from anon, authenticated;
grant insert (user_id, video_id, type) on likes to authenticated;
grant update (type) on likes to authenticated;

-- 12. Basculer like <-> Masterclass (upsert côté app) nécessite une policy
--     UPDATE, absente jusqu'ici.
drop policy if exists "Users can change their own reaction" on likes;
create policy "Users can change their own reaction"
on likes for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

revoke insert, update on organizations from anon, authenticated;
grant insert (owner_id, name, type, country, logo_url) on organizations to authenticated;
grant update (name, country, logo_url) on organizations to authenticated;

revoke insert, update on content_reports from anon, authenticated;
grant insert (target_type, target_id, reporter_id, reason) on content_reports to authenticated;

-- Tables entièrement serveur : aucun droit d'écriture client (RLS les
-- bloquait déjà faute de policy ; on retire aussi le privilège, en
-- défense en profondeur).
revoke insert, update, delete on
  transactions, user_badges, daily_missions, badges, app_config,
  scout_subscriptions, challenge_participations, challenge_votes
from anon, authenticated;

-- Défis : uniquement via les RPC. La policy "brouillon modifiable" ne sert
-- à rien (aucun défi n'est créé en brouillon) et permettait en théorie de
-- modifier prize_pool/entry_cost.
drop policy if exists "Creators can edit own draft challenges" on challenges;
drop policy if exists "Users can vote as themselves" on challenge_votes;
revoke insert, update, delete on challenges from anon, authenticated;

-- Profil : le client n'insère jamais de ligne (trigger handle_new_user).
revoke insert, delete on profiles from anon, authenticated;

-- Longueurs maximales (anti-spam / anti-abus de stockage).
alter table profiles
  add constraint profiles_username_format
  check (username ~ '^[A-Za-z0-9_.]{3,30}$') not valid;
alter table profiles
  add constraint profiles_bio_length check (char_length(coalesce(bio, '')) <= 300) not valid;
alter table profiles
  add constraint profiles_display_name_length
  check (char_length(coalesce(display_name, '')) <= 50) not valid;
alter table videos
  add constraint videos_caption_length check (char_length(coalesce(caption, '')) <= 500) not valid;
alter table videos
  add constraint videos_move_name_length check (char_length(coalesce(move_name, '')) <= 60) not valid;
alter table comments
  add constraint comments_content_length
  check (char_length(content) between 1 and 500) not valid;
alter table messages
  add constraint messages_body_length check (char_length(body) between 1 and 2000) not valid;
alter table content_reports
  add constraint content_reports_reason_length check (char_length(reason) <= 500) not valid;

-- -------------------------------------------------------------------------
-- 9. Suppression de compte : plus de DELETE direct dans storage.objects
--    (refusé par Supabase). Les fichiers sont supprimés par l'app via
--    l'API Storage juste avant cet appel.
-- -------------------------------------------------------------------------
create or replace function delete_my_account()
returns void as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  delete from auth.users where id = v_user_id;
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 10. Fonctions réservées au système : plus exécutables par les clients.
-- -------------------------------------------------------------------------
revoke execute on function resolve_expired_challenges() from public, anon, authenticated;
revoke execute on function resolve_local_date(date) from public, anon, authenticated;
revoke execute on function handle_new_user() from public, anon, authenticated;
revoke execute on function handle_user_email_confirmed() from public, anon, authenticated;
revoke execute on function delete_my_account() from public, anon;
revoke execute on function award_coins(text, uuid, date) from public, anon;
revoke execute on function spend_coins(text, uuid, integer) from public, anon;
revoke execute on function increment_videos_watched(date) from public, anon;
revoke execute on function increment_video_views(uuid) from public, anon;
revoke execute on function find_ledger_drift() from public, anon;

-- -------------------------------------------------------------------------
-- 11. Modération effective : un admin qui "agit" sur un signalement retire
--     réellement la vidéo ou le commentaire visé.
-- -------------------------------------------------------------------------
create or replace function admin_resolve_report(
  p_report_id uuid,
  p_status text,
  p_note text default null
)
returns jsonb as $$
declare
  v_admin_id uuid := auth.uid();
  v_report content_reports%rowtype;
begin
  if not exists (select 1 from profiles where id = v_admin_id and role = 'admin') then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;

  if p_status not in ('reviewed', 'actioned', 'dismissed') then
    raise exception 'Statut invalide.' using errcode = 'P0001';
  end if;

  select * into v_report from content_reports where id = p_report_id for update;
  if v_report.id is null then
    raise exception 'Signalement introuvable.' using errcode = 'P0001';
  end if;

  if p_status = 'actioned' then
    if v_report.target_type = 'video' then
      update videos set status = 'removed' where id = v_report.target_id;
    elsif v_report.target_type = 'comment' then
      update comments set status = 'removed' where id = v_report.target_id;
    end if;
    -- Profil : aucune suppression automatique (décision humaine, via le
    -- dashboard Supabase), seul le signalement est marqué traité.
  end if;

  update content_reports
  set status = p_status,
      resolved_by = v_admin_id,
      resolution_note = p_note,
      resolved_at = now()
  where id = p_report_id;

  return jsonb_build_object('resolved', true);
end;
$$ language plpgsql security definer set search_path = public;

revoke execute on function admin_resolve_report(uuid, text, text) from public, anon;
grant execute on function admin_resolve_report(uuid, text, text) to authenticated;

-- -------------------------------------------------------------------------
-- Buckets Storage en production : `config.toml` ne sert qu'en local. Sans
-- ce bloc, un projet Supabase hébergé n'aurait ni les buckets ni leurs
-- limites de taille / types de fichiers.
-- -------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('videos', 'videos', true, 209715200, array['video/mp4', 'video/quicktime', 'video/webm']),
  ('thumbnails', 'thumbnails', true, 5242880, array['image/png', 'image/jpeg', 'image/webp']),
  ('avatars', 'avatars', true, 5242880, array['image/png', 'image/jpeg', 'image/webp'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- -------------------------------------------------------------------------
-- find_ledger_drift plantait à chaque appel ("column reference currency is
-- ambiguous" : les colonnes de RETURNS TABLE masquent celles de la table).
-- Même logique, colonnes qualifiées.
-- -------------------------------------------------------------------------
create or replace function find_ledger_drift()
returns table (
  user_id uuid,
  currency text,
  stored_balance integer,
  ledger_sum bigint,
  drift bigint
) as $$
begin
  if not exists (
    select 1 from profiles pr where pr.id = auth.uid() and pr.role = 'admin'
  ) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;

  return query
  with sums as (
    select tx.user_id as uid, tx.currency as cur, sum(tx.amount)::bigint as total
    from transactions tx
    where tx.user_id is not null
    group by tx.user_id, tx.currency
  ),
  balances as (
    select p.id as uid, 'coins'::text as cur, p.coins as bal from profiles p
    union all
    select p.id, 'stars'::text, p.stars from profiles p
  )
  select b.uid, b.cur, b.bal, coalesce(s.total, 0::bigint),
         b.bal::bigint - coalesce(s.total, 0::bigint)
  from balances b
  left join sums s on s.uid = b.uid and s.cur = b.cur
  where b.bal::bigint != coalesce(s.total, 0::bigint);
end;
$$ language plpgsql security definer set search_path = public;

revoke execute on function find_ledger_drift() from public, anon;
grant execute on function find_ledger_drift() to authenticated;


-- ===================== 20260101000022_admin_panel.sql =====================
-- =========================================================================
-- Panneau administrateur
--
-- Tout passe par des RPC SECURITY DEFINER qui vérifient elles-mêmes
-- `profiles.role = 'admin'` : l'app n'a aucun droit direct en plus, un
-- non-admin qui appelle ces fonctions reçoit "Réservé aux administrateurs."
--
--   1. Notifications de modération (type 'moderation').
--   2. Bannissement : profil marqué, connexion bloquée côté Auth, sessions
--      coupées, vidéos masquées (statut 'flagged') — réversible.
--   3. Signalements : liste avec aperçu du contenu, décision (retirer ou
--      garder) avec message pré-écrit à l'auteur et aux signaleurs ; tous
--      les signalements en attente sur le même contenu sont clos ensemble.
--   4. Statistiques du tableau de bord.
--   5. Liste des joueurs (recherche).
--   6. Défis officiels (type 'world', gratuits, sans coût de création).
-- =========================================================================

-- -------------------------------------------------------------------------
-- 1. Type de notification 'moderation'
-- -------------------------------------------------------------------------
alter table notifications drop constraint if exists notifications_type_check;
alter table notifications
  add constraint notifications_type_check
  check (type in (
    'new_follower', 'like', 'masterclass', 'comment', 'move_reproduced',
    'badge_earned', 'challenge_won', 'scout_interest', 'contact_approved',
    'moderation'
  ));

-- -------------------------------------------------------------------------
-- 2. Bannissement
-- -------------------------------------------------------------------------
alter table profiles add column if not exists is_banned boolean not null default false;
alter table profiles add column if not exists banned_at timestamptz;
alter table profiles add column if not exists ban_reason text;

-- Les colonnes de bannissement ne sont jamais lisibles ni modifiables via
-- l'API (les droits SELECT/UPDATE sur profiles sont colonne par colonne
-- depuis la migration 0021) : seul un admin les voit, via les RPC.

create schema if not exists private;

create or replace function private.require_admin()
returns uuid as $$
declare
  v_admin_id uuid := auth.uid();
begin
  if v_admin_id is null
     or not exists (select 1 from public.profiles where id = v_admin_id and role = 'admin') then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;
  return v_admin_id;
end;
$$ language plpgsql stable security definer set search_path = public;

create or replace function private.apply_ban(
  p_user_id uuid,
  p_banned boolean,
  p_reason text,
  p_admin_id uuid
)
returns void as $$
declare
  v_role text;
begin
  select role into v_role from public.profiles where id = p_user_id;
  if v_role is null then
    raise exception 'Joueur introuvable.' using errcode = 'P0001';
  end if;
  if p_user_id = p_admin_id then
    raise exception 'Tu ne peux pas te bannir toi-même.' using errcode = 'P0001';
  end if;
  if v_role = 'admin' then
    raise exception 'Impossible de bannir un administrateur.' using errcode = 'P0001';
  end if;

  if p_banned then
    update public.profiles
    set is_banned = true, banned_at = now(), ban_reason = left(p_reason, 500)
    where id = p_user_id;

    -- Connexion refusée par Supabase Auth, sessions en cours coupées.
    update auth.users set banned_until = now() + interval '100 years' where id = p_user_id;
    delete from auth.sessions where user_id = p_user_id;

    -- Vidéos masquées (pas supprimées : un débannissement les remet).
    update public.videos set status = 'flagged' where user_id = p_user_id and status = 'active';
  else
    update public.profiles
    set is_banned = false, banned_at = null, ban_reason = null
    where id = p_user_id;

    update auth.users set banned_until = null where id = p_user_id;
    update public.videos set status = 'active' where user_id = p_user_id and status = 'flagged';
  end if;
end;
$$ language plpgsql security definer set search_path = public;

revoke all on function private.require_admin() from public, anon, authenticated;
revoke all on function private.apply_ban(uuid, boolean, text, uuid) from public, anon, authenticated;

create or replace function admin_set_ban(
  p_user_id uuid,
  p_banned boolean,
  p_reason text default null
)
returns jsonb as $$
declare
  v_admin_id uuid := private.require_admin();
begin
  if p_banned and (p_reason is null or trim(p_reason) = '') then
    raise exception 'Indique la raison du bannissement.' using errcode = 'P0001';
  end if;
  perform private.apply_ban(p_user_id, p_banned, p_reason, v_admin_id);
  return jsonb_build_object('banned', p_banned);
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 3. Signalements
-- -------------------------------------------------------------------------

-- Liste des signalements en attente, regroupés par contenu signalé, avec
-- de quoi décider sans quitter l'écran (aperçu, auteur, nombre de
-- signalements, raisons).
create or replace function admin_list_reports()
returns table (
  report_id uuid,
  target_type text,
  target_id uuid,
  reason text,
  reasons text[],
  reports_count integer,
  reporter_username text,
  created_at timestamptz,
  author_id uuid,
  author_username text,
  preview_text text,
  video_url text,
  thumbnail_url text,
  target_status text
) as $$
begin
  perform private.require_admin();

  return query
  with grouped as (
    select r.target_type as g_type, r.target_id as g_id, count(*) as cnt,
           array_agg(distinct r.reason) as all_reasons
    from content_reports r
    where r.status = 'pending'
    group by r.target_type, r.target_id
  ),
  pending as (
    select distinct on (r.target_type, r.target_id) r.*, g.cnt, g.all_reasons
    from content_reports r
    join grouped g on g.g_type = r.target_type and g.g_id = r.target_id
    where r.status = 'pending'
    order by r.target_type, r.target_id, r.created_at
  )
  select
    p.id,
    p.target_type,
    p.target_id,
    p.reason,
    p.all_reasons,
    p.cnt::integer,
    rp.username,
    p.created_at,
    coalesce(v.user_id, c.user_id, tp.id),
    coalesce(va.username, ca.username, tp.username),
    case p.target_type
      when 'video' then v.caption
      when 'comment' then c.content
      else tp.bio
    end,
    v.video_url,
    v.thumbnail_url,
    case p.target_type
      when 'video' then coalesce(v.status, 'deleted')
      when 'comment' then coalesce(c.status, 'deleted')
      else case when tp.id is null then 'deleted' when tp.is_banned then 'banned' else 'active' end
    end
  from pending p
  left join profiles rp on rp.id = p.reporter_id
  left join videos v on p.target_type = 'video' and v.id = p.target_id
  left join profiles va on va.id = v.user_id
  left join comments c on p.target_type = 'comment' and c.id = p.target_id
  left join profiles ca on ca.id = c.user_id
  left join profiles tp on p.target_type = 'profile' and tp.id = p.target_id
  order by p.cnt desc, p.created_at asc;
end;
$$ language plpgsql stable security definer set search_path = public;

-- Remplace la version à 3 paramètres de la migration 0021.
drop function if exists admin_resolve_report(uuid, text, text);

-- p_status : 'actioned' (contenu retiré / profil banni) ou 'dismissed'
-- (contenu gardé). p_author_message et p_reporter_message : textes
-- (pré-écrits côté app, modifiables) envoyés en notification ; null = aucun.
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
  else
    v_author_id := v_report.target_id;
  end if;

  if p_status = 'actioned' then
    if v_report.target_type = 'video' then
      update videos set status = 'removed' where id = v_report.target_id;
    elsif v_report.target_type = 'comment' then
      update comments set status = 'removed' where id = v_report.target_id;
    elsif v_author_id is not null then
      perform private.apply_ban(
        v_author_id, true,
        coalesce(nullif(trim(p_author_message), ''), v_report.reason),
        v_admin_id
      );
    end if;
  end if;

  -- Message aux signaleurs (tous ceux en attente sur ce contenu).
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

  -- Message à l'auteur (inutile s'il vient d'être banni : il ne peut plus
  -- se connecter).
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

-- -------------------------------------------------------------------------
-- 4. Statistiques
-- -------------------------------------------------------------------------
create or replace function admin_dashboard_stats()
returns jsonb as $$
begin
  perform private.require_admin();

  return jsonb_build_object(
    'players_total', (select count(*) from profiles where role = 'player'),
    'players_today', (select count(*) from profiles where role = 'player' and created_at >= date_trunc('day', now())),
    'players_7d', (select count(*) from profiles where role = 'player' and created_at >= now() - interval '7 days'),
    'videos_total', (select count(*) from videos where status = 'active'),
    'videos_today', (select count(*) from videos where status = 'active' and created_at >= date_trunc('day', now())),
    'challenges_active', (select count(*) from challenges where status = 'active' and end_date > now()),
    'reports_pending', (select count(distinct (target_type, target_id)) from content_reports where status = 'pending'),
    'banned_total', (select count(*) from profiles where is_banned)
  );
end;
$$ language plpgsql stable security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 5. Joueurs
-- -------------------------------------------------------------------------
create or replace function admin_list_users(
  p_search text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table (
  id uuid,
  username text,
  display_name text,
  avatar_url text,
  email text,
  role text,
  created_at timestamptz,
  videos_count integer,
  followers_count integer,
  is_banned boolean,
  ban_reason text,
  reports_count bigint
) as $$
declare
  v_search text := nullif(trim(p_search), '');
begin
  perform private.require_admin();

  return query
  select
    p.id, p.username, p.display_name, p.avatar_url, u.email::text, p.role,
    p.created_at, p.videos_count, p.followers_count, p.is_banned, p.ban_reason,
    (select count(*) from content_reports r
      left join videos v on r.target_type = 'video' and v.id = r.target_id
      left join comments c on r.target_type = 'comment' and c.id = r.target_id
      where coalesce(v.user_id, c.user_id, case when r.target_type = 'profile' then r.target_id end) = p.id)
  from profiles p
  left join auth.users u on u.id = p.id
  where v_search is null
     or p.username ilike '%' || v_search || '%'
     or p.display_name ilike '%' || v_search || '%'
     or u.email ilike '%' || v_search || '%'
  order by p.created_at desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0);
end;
$$ language plpgsql stable security definer set search_path = public, auth;

-- -------------------------------------------------------------------------
-- 6. Défis officiels
-- -------------------------------------------------------------------------
create or replace function admin_create_official_challenge(
  p_title text,
  p_description text,
  p_end_date timestamptz,
  p_category text default null,
  p_prize_description text default null
)
returns jsonb as $$
declare
  v_admin_id uuid := private.require_admin();
  v_challenge_id uuid;
begin
  if p_title is null or char_length(trim(p_title)) < 3 or char_length(p_title) > 80 then
    raise exception 'Le titre doit faire entre 3 et 80 caractères.' using errcode = 'P0001';
  end if;
  if char_length(coalesce(p_description, '')) > 1000 then
    raise exception 'La description est trop longue (1000 caractères max).' using errcode = 'P0001';
  end if;
  if p_end_date is null or p_end_date <= now() then
    raise exception 'La date de fin doit être dans le futur.' using errcode = 'P0001';
  end if;
  if p_end_date > now() + interval '90 days' then
    raise exception 'Un défi officiel ne peut pas durer plus de 90 jours.' using errcode = 'P0001';
  end if;

  insert into challenges (
    creator_id, title, description, type, category, entry_cost, prize_pool,
    prize_description, sponsor_name, is_official, end_date, status
  ) values (
    v_admin_id, trim(p_title), coalesce(p_description, ''), 'world', p_category, 0, 0,
    left(nullif(trim(p_prize_description), ''), 500), 'Football IQ Universe', true,
    p_end_date, 'active'
  )
  returning id into v_challenge_id;

  return jsonb_build_object('challenge_id', v_challenge_id);
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- Droits
-- -------------------------------------------------------------------------
revoke execute on function admin_set_ban(uuid, boolean, text) from public, anon;
revoke execute on function admin_list_reports() from public, anon;
revoke execute on function admin_resolve_report(uuid, text, text, text, text) from public, anon;
revoke execute on function admin_dashboard_stats() from public, anon;
revoke execute on function admin_list_users(text, integer, integer) from public, anon;
revoke execute on function admin_create_official_challenge(text, text, timestamptz, text, text) from public, anon;

grant execute on function admin_set_ban(uuid, boolean, text) to authenticated;
grant execute on function admin_list_reports() to authenticated;
grant execute on function admin_resolve_report(uuid, text, text, text, text) to authenticated;
grant execute on function admin_dashboard_stats() to authenticated;
grant execute on function admin_list_users(text, integer, integer) to authenticated;
grant execute on function admin_create_official_challenge(text, text, timestamptz, text, text) to authenticated;


-- ===================== 20260101000023_respect_points.sql =====================
-- Points de Respect : la couleur de la carte joueur se gagne par paliers,
-- comme les disques d'or (Bronze, Argent, Or, Platine, Diamant).
--
-- `profiles.likes_received_count` existait mais n'était jamais mis à jour.
-- Il devient le total de points de Respect reçus par le joueur :
--   - un Respect reçu = 1 point ;
--   - une Masterclass reçue = 3 points.
-- Les réactions qu'un joueur met sur ses propres vidéos ne comptent pas.

create schema if not exists private;

create or replace function private.respect_points(p_type text)
returns integer
language sql
immutable
as $$
  select case when p_type = 'masterclass' then 3 else 1 end;
$$;

create or replace function handle_respect_points()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_video_id uuid;
  v_reactor_id uuid;
  v_owner_id uuid;
  v_delta integer;
begin
  if tg_op = 'INSERT' then
    v_video_id := new.video_id;
    v_reactor_id := new.user_id;
    v_delta := private.respect_points(new.type);
  elsif tg_op = 'DELETE' then
    v_video_id := old.video_id;
    v_reactor_id := old.user_id;
    v_delta := -private.respect_points(old.type);
  else
    if new.type = old.type then
      return null;
    end if;
    v_video_id := new.video_id;
    v_reactor_id := new.user_id;
    v_delta := private.respect_points(new.type) - private.respect_points(old.type);
  end if;

  select user_id into v_owner_id from videos where id = v_video_id;

  -- Vidéo déjà supprimée (suppression en cascade) : les points restent acquis.
  if v_owner_id is null or v_owner_id = v_reactor_id then
    return null;
  end if;

  update profiles
  set likes_received_count = greatest(coalesce(likes_received_count, 0) + v_delta, 0)
  where id = v_owner_id;

  return null;
end;
$$;

revoke execute on function handle_respect_points() from public, anon, authenticated;

drop trigger if exists trigger_respect_points on likes;
create trigger trigger_respect_points
after insert or delete or update of type on likes
for each row
execute function handle_respect_points();

-- Rattrapage : recalcule les points de tous les joueurs à partir des
-- réactions déjà présentes.
update profiles p
set likes_received_count = coalesce((
  select sum(private.respect_points(l.type))
  from likes l
  join videos v on v.id = l.video_id
  where v.user_id = p.id
    and l.user_id <> p.id
), 0);


-- ===================== 20260101000024_rules_v2.sql =====================
-- =========================================================================
-- Règles v2 (décidées par Tom le 15/10/2026)
--
-- Jetons (Ballons) :
--   - plus aucun Ballon pour la simple connexion quotidienne (ni bonus de
--     série) : se connecter sans jouer ne doit rien rapporter. La série de
--     jours et ses badges restent suivis ;
--   - plus de Ballon quand un Move est reproduit (des millions de
--     reproductions = des millions de Ballons gratuits) ;
--   - « regarder 3 vidéos » ne rapporte plus rien ;
--   - nouveau : regarder 20 vidéos EN ENTIER dans la journée = 30 Ballons,
--     une fois par jour. Le temps de visionnage est contrôlé par le serveur
--     (un robot ne peut pas aller plus vite que les vidéos).
--
-- Défis :
--   - Challenge : ouvert à tous, avec une date de début et une date de fin ;
--     on ne peut participer qu'entre les deux ;
--   - Battle : un contre un. Le créateur fixe les règles, la mise (en
--     Ballons) et éventuellement son adversaire. Les deux joueurs misent la
--     même somme, les autres utilisateurs votent, le gagnant remporte les
--     deux mises. Égalité ou adversaire absent : chacun est remboursé ;
--   - Monde (admin) et Sponsorisé (marque vérifiée) : inchangés, aucun
--     joueur ne peut en créer ;
--   - King : plus créable (aucun moyen de saisir un record).
--
-- Anti-triche des votes : pas de vote pour soi, pas de vote dans une
-- Battle à laquelle on participe, et seuls les comptes « réels » votent
-- (au moins une vidéo publiée, ou compte de plus de 24 h).
-- =========================================================================

-- -------------------------------------------------------------------------
-- 1. Connexion quotidienne : suivi de la série, sans Ballons
-- -------------------------------------------------------------------------
create or replace function award_coins(
  p_reason text,
  p_reference_id uuid default null,
  p_local_date date default null
)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_economy jsonb;
  v_amount integer;
  v_today date;
  v_last_login date;
  v_streak integer;
  v_count_today integer;
  v_new_balance integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  v_today := resolve_local_date(p_local_date);

  select value into v_economy from app_config where key = 'economy';

  if p_reason = 'daily_login' then
    select last_login_date, streak_days, coins into v_last_login, v_streak, v_new_balance
    from profiles where id = v_user_id for update;

    if v_last_login is not null and v_today <= v_last_login then
      raise exception 'Connexion quotidienne déjà réclamée aujourd''hui.' using errcode = 'P0001';
    end if;

    if v_last_login = v_today - 1 then
      v_streak := coalesce(v_streak, 0) + 1;
    else
      v_streak := 1;
    end if;

    update profiles
    set last_login_date = v_today,
        streak_days = v_streak
    where id = v_user_id;

    insert into daily_missions (user_id, mission_date, login_completed)
    values (v_user_id, v_today, true)
    on conflict (user_id, mission_date)
    do update set login_completed = true;

    if v_streak = 7 then
      insert into user_badges (user_id, badge_id)
      select v_user_id, id from badges where code = 'assidu_7'
      on conflict (user_id, badge_id) do nothing;
    elsif v_streak = 30 then
      insert into user_badges (user_id, badge_id)
      select v_user_id, id from badges where code = 'assidu_30'
      on conflict (user_id, badge_id) do nothing;
    end if;

    return jsonb_build_object('new_balance', v_new_balance, 'amount_awarded', 0);

  elsif p_reason = 'post_video' then
    if p_reference_id is null or not exists (
      select 1 from videos
      where id = p_reference_id
        and user_id = v_user_id
        and created_at > now() - interval '24 hours'
    ) then
      raise exception 'Vidéo introuvable pour cette récompense.' using errcode = 'P0001';
    end if;

    if exists (
      select 1 from transactions
      where user_id = v_user_id and reason = 'post_video' and reference_id = p_reference_id
    ) then
      raise exception 'Récompense déjà reçue pour cette vidéo.' using errcode = 'P0001';
    end if;

    select coalesce(posts_count, 0) into v_count_today
    from daily_missions
    where user_id = v_user_id and mission_date = v_today;

    if coalesce(v_count_today, 0) >= coalesce((v_economy ->> 'max_post_video_per_day')::integer, 3) then
      raise exception 'Limite quotidienne de récompenses vidéo atteinte.' using errcode = 'P0001';
    end if;

    v_amount := coalesce((v_economy ->> 'post_video')::integer, 5);

    update profiles set coins = coins + v_amount
    where id = v_user_id
    returning coins into v_new_balance;

    insert into daily_missions (user_id, mission_date, video_posted, coins_earned, posts_count)
    values (v_user_id, v_today, true, v_amount, 1)
    on conflict (user_id, mission_date)
    do update set video_posted = true,
                  coins_earned = daily_missions.coins_earned + v_amount,
                  posts_count = daily_missions.posts_count + 1;

  elsif p_reason = 'ad_watched' then
    raise exception 'Les récompenses publicitaires ne sont pas encore disponibles.'
      using errcode = 'P0001';

  else
    raise exception 'Raison de récompense non prise en charge : %', p_reason using errcode = 'P0001';
  end if;

  insert into transactions (user_id, type, amount, currency, balance_after, reason, reference_id)
  values (v_user_id, 'earn', v_amount, 'coins', v_new_balance, p_reason, p_reference_id);

  return jsonb_build_object('new_balance', v_new_balance, 'amount_awarded', v_amount);
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 2. Move reproduit : on garde le compteur, plus de Ballon
-- -------------------------------------------------------------------------
create or replace function handle_new_video()
returns trigger as $$
declare
  v_original_is_move boolean;
begin
  update profiles set videos_count = videos_count + 1
  where id = new.user_id;

  if new.is_move then
    update profiles set moves_created_count = moves_created_count + 1
    where id = new.user_id;
  end if;

  if new.original_move_id is not null then
    select coalesce(is_move, false) into v_original_is_move
    from videos where id = new.original_move_id;

    if coalesce(v_original_is_move, false) then
      update videos set reproductions_count = reproductions_count + 1
      where id = new.original_move_id;
    end if;
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 3. « Regarder 3 vidéos » : compteur seulement, plus de Ballons
-- -------------------------------------------------------------------------
create or replace function increment_videos_watched(p_local_date date default null)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_today date;
  v_watched integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  v_today := resolve_local_date(p_local_date);

  insert into daily_missions (user_id, mission_date, videos_watched)
  values (v_user_id, v_today, 1)
  on conflict (user_id, mission_date)
  do update set videos_watched = daily_missions.videos_watched + 1
  returning videos_watched into v_watched;

  return jsonb_build_object('videos_watched', v_watched, 'bonus_awarded', false);
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 4. 20 vidéos regardées en entier = 30 Ballons (une fois par jour)
--
-- L'app appelle `start_video_watch` quand une vidéo commence, puis
-- `complete_video_watch` quand elle arrive au bout. Le serveur exige que le
-- temps réellement écoulé couvre la durée de la vidéo, et que les
-- visionnages se suivent (on ne peut pas « regarder » 20 vidéos en même
-- temps) : 20 vidéos de 30 s demandent au moins 10 minutes réelles.
-- -------------------------------------------------------------------------
alter table daily_missions add column if not exists full_videos_watched integer not null default 0;
alter table daily_missions add column if not exists full_watch_rewarded boolean not null default false;
alter table daily_missions add column if not exists last_full_watch_at timestamptz;

-- Dans le schéma `private` : jamais exposé par l'API, et surtout pas vu
-- par PostgREST comme un second lien entre `videos` et `profiles` (ce qui
-- casserait la requête du feed).
create schema if not exists private;

create table if not exists private.video_watch_sessions (
  user_id uuid not null references profiles (id) on delete cascade,
  video_id uuid not null references videos (id) on delete cascade,
  watch_date date not null,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  primary key (user_id, video_id, watch_date)
);

revoke all on private.video_watch_sessions from public, anon, authenticated;

update app_config
set value = value || '{"full_watch_target": 20, "full_watch_reward": 30}'::jsonb
where key = 'economy';

create or replace function start_video_watch(p_video_id uuid, p_local_date date default null)
returns void as $$
declare
  v_user_id uuid := auth.uid();
  v_today date;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  v_today := resolve_local_date(p_local_date);

  if not exists (
    select 1 from videos
    where id = p_video_id and status = 'active' and user_id != v_user_id
  ) then
    return;
  end if;

  -- Un visionnage pas encore terminé repart de zéro (l'utilisateur est
  -- revenu sur la vidéo) ; un visionnage terminé ne compte qu'une fois.
  insert into private.video_watch_sessions (user_id, video_id, watch_date, started_at)
  values (v_user_id, p_video_id, v_today, now())
  on conflict (user_id, video_id, watch_date)
  do update set started_at = now()
  where private.video_watch_sessions.completed_at is null;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function complete_video_watch(
  p_video_id uuid,
  p_duration_seconds numeric default null,
  p_local_date date default null
)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_today date;
  v_economy jsonb;
  v_target integer;
  v_reward integer;
  v_started_at timestamptz;
  v_video_duration integer;
  v_required numeric;
  v_last_full timestamptz;
  v_rewarded boolean;
  v_count integer;
  v_new_balance integer;
  v_awarded boolean := false;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  v_today := resolve_local_date(p_local_date);
  select value into v_economy from app_config where key = 'economy';
  v_target := coalesce((v_economy ->> 'full_watch_target')::integer, 20);
  v_reward := coalesce((v_economy ->> 'full_watch_reward')::integer, 30);

  select s.started_at, v.duration_seconds
    into v_started_at, v_video_duration
  from private.video_watch_sessions s
  join videos v on v.id = s.video_id
  where s.user_id = v_user_id
    and s.video_id = p_video_id
    and s.watch_date = v_today
    and s.completed_at is null
    and v.status = 'active';

  if v_started_at is null then
    return jsonb_build_object('counted', false, 'reason', 'no_session');
  end if;

  -- Durée de référence : celle enregistrée à la publication, sinon celle
  -- vue par l'appareil, toujours entre 5 et 60 secondes.
  v_required := least(greatest(coalesce(v_video_duration, p_duration_seconds, 5), 5), 60);

  insert into daily_missions (user_id, mission_date)
  values (v_user_id, v_today)
  on conflict (user_id, mission_date) do nothing;

  select last_full_watch_at, full_watch_rewarded
    into v_last_full, v_rewarded
  from daily_missions
  where user_id = v_user_id and mission_date = v_today
  for update;

  -- 1 seconde de tolérance pour les arrondis de l'appareil.
  if now() - greatest(v_started_at, coalesce(v_last_full, v_started_at))
     < make_interval(secs => v_required - 1) then
    return jsonb_build_object('counted', false, 'reason', 'too_fast');
  end if;

  update private.video_watch_sessions
  set completed_at = now()
  where user_id = v_user_id and video_id = p_video_id and watch_date = v_today;

  update daily_missions
  set full_videos_watched = full_videos_watched + 1,
      last_full_watch_at = now()
  where user_id = v_user_id and mission_date = v_today
  returning full_videos_watched into v_count;

  if v_count >= v_target and not v_rewarded then
    update profiles set coins = coins + v_reward
    where id = v_user_id
    returning coins into v_new_balance;

    update daily_missions
    set full_watch_rewarded = true,
        coins_earned = coins_earned + v_reward
    where user_id = v_user_id and mission_date = v_today;

    insert into transactions (user_id, type, amount, currency, balance_after, reason)
    values (v_user_id, 'earn', v_reward, 'coins', v_new_balance, 'daily_full_watch');

    v_awarded := true;
  end if;

  return jsonb_build_object(
    'counted', true,
    'full_videos_watched', v_count,
    'target', v_target,
    'reward_awarded', v_awarded,
    'reward', v_reward
  );
end;
$$ language plpgsql security definer set search_path = public;

revoke execute on function start_video_watch(uuid, date) from public, anon;
revoke execute on function complete_video_watch(uuid, numeric, date) from public, anon;
grant execute on function start_video_watch(uuid, date) to authenticated;
grant execute on function complete_video_watch(uuid, numeric, date) to authenticated;

-- -------------------------------------------------------------------------
-- 5. Challenge : date de début + date de fin. Seul « challenge » est
--    créable par un joueur ici (la Battle a sa propre fonction).
-- -------------------------------------------------------------------------
drop function if exists create_challenge(text, text, text, timestamptz, text, integer, integer, text, text);

create or replace function create_challenge(
  p_title text,
  p_description text,
  p_type text,
  p_end_date timestamptz,
  p_category text default null,
  p_prize_pool integer default 0,
  p_max_participants integer default null,
  p_record_unit text default null,
  p_prize_description text default null,
  p_start_date timestamptz default null
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
  v_start timestamptz := greatest(coalesce(p_start_date, now()), now());
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  if p_title is null or char_length(trim(p_title)) < 3 or char_length(p_title) > 80 then
    raise exception 'Le titre doit faire entre 3 et 80 caractères.' using errcode = 'P0001';
  end if;

  if char_length(coalesce(p_description, '')) > 1000 then
    raise exception 'La description est trop longue (1000 caractères max).' using errcode = 'P0001';
  end if;

  if v_start > now() + interval '30 days' then
    raise exception 'Un défi doit commencer dans les 30 prochains jours.' using errcode = 'P0001';
  end if;

  if p_end_date <= v_start + interval '1 hour' then
    raise exception 'La date de fin doit être au moins 1 heure après le début.' using errcode = 'P0001';
  end if;

  if p_end_date > v_start + interval '60 days' then
    raise exception 'Un défi ne peut pas durer plus de 60 jours.' using errcode = 'P0001';
  end if;

  if p_max_participants is not null and (p_max_participants < 2 or p_max_participants > 10000) then
    raise exception 'Nombre de participants invalide.' using errcode = 'P0001';
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
      max_participants, start_date, end_date, status
    ) values (
      v_user_id, trim(p_title), p_description, 'sponsored', p_category, 0, 0,
      'real', left(p_prize_description, 500), v_user_id, v_sponsor_name,
      p_max_participants, v_start, p_end_date, 'active'
    )
    returning id into v_challenge_id;

    return jsonb_build_object('challenge_id', v_challenge_id);
  end if;

  if p_type = 'battle' then
    raise exception 'Une Battle se crée depuis l''écran Battle (1 contre 1).'
      using errcode = 'P0001';
  end if;

  if p_type != 'challenge' then
    raise exception 'Les défis Monde sont réservés à Football IQ.'
      using errcode = 'P0001';
  end if;

  select value into v_economy from app_config where key = 'economy';
  v_create_cost := coalesce((v_economy ->> 'create_challenge_cost')::integer, 200);
  v_entry_cost := coalesce((v_economy ->> 'join_challenge_cost')::integer, 20);

  update profiles set coins = coins - v_create_cost
  where id = v_user_id and coins >= v_create_cost
  returning coins into v_new_balance;

  if v_new_balance is null then
    raise exception 'Solde de Ballons insuffisant.' using errcode = 'P0001';
  end if;

  insert into challenges (
    creator_id, title, description, type, category, entry_cost, prize_pool,
    max_participants, start_date, end_date, status
  ) values (
    v_user_id, trim(p_title), p_description, 'challenge', p_category, v_entry_cost, 0,
    p_max_participants, v_start, p_end_date, 'active'
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

revoke execute on function create_challenge(text, text, text, timestamptz, text, integer, integer, text, text, timestamptz) from public, anon;
grant execute on function create_challenge(text, text, text, timestamptz, text, integer, integer, text, text, timestamptz) to authenticated;

-- -------------------------------------------------------------------------
-- 6. Battle : 1 contre 1, mise libre, règles libres
-- -------------------------------------------------------------------------
alter table notifications drop constraint if exists notifications_type_check;
alter table notifications
  add constraint notifications_type_check
  check (type in (
    'new_follower', 'like', 'masterclass', 'comment', 'move_reproduced',
    'badge_earned', 'challenge_won', 'scout_interest', 'contact_approved',
    'moderation', 'battle_invite', 'battle_result'
  ));

update app_config
set value = value || '{"battle_min_stake": 10, "battle_max_stake": 10000}'::jsonb
where key = 'economy';

create or replace function create_battle(
  p_title text,
  p_rules text,
  p_stake integer,
  p_video_id uuid,
  p_end_date timestamptz,
  p_opponent_username text default null
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

  if p_opponent_username is not null and trim(p_opponent_username) != '' then
    select id into v_opponent_id
    from profiles
    where lower(username) = lower(trim(both '@ ' from p_opponent_username))
      and not is_banned;

    if v_opponent_id is null then
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

revoke execute on function create_battle(text, text, integer, uuid, timestamptz, text) from public, anon;
grant execute on function create_battle(text, text, integer, uuid, timestamptz, text) to authenticated;

-- -------------------------------------------------------------------------
-- 7. Participer : entre la date de début et la date de fin ; Battle
--    réservée à l'adversaire désigné (ou au premier venu s'il n'y en a pas)
-- -------------------------------------------------------------------------
create or replace function join_challenge(p_challenge_id uuid, p_video_id uuid)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_challenge record;
  v_new_balance integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  select * into v_challenge from challenges where id = p_challenge_id for update;

  if v_challenge.id is null then
    raise exception 'Défi introuvable.' using errcode = 'P0001';
  end if;

  if v_challenge.status != 'active' or now() > v_challenge.end_date then
    raise exception 'Ce défi n''accepte plus de participations.' using errcode = 'P0001';
  end if;

  if now() < v_challenge.start_date then
    raise exception 'Ce défi n''a pas encore commencé.' using errcode = 'P0001';
  end if;

  if v_challenge.max_participants is not null
     and v_challenge.participants_count >= v_challenge.max_participants then
    raise exception 'Ce défi est complet.' using errcode = 'P0001';
  end if;

  if v_challenge.type = 'battle'
     and v_challenge.opponent_id is not null
     and v_challenge.opponent_id != v_user_id then
    raise exception 'Cette Battle est réservée au joueur défié.' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from videos
    where id = p_video_id and user_id = v_user_id and status = 'active'
  ) then
    raise exception 'Tu ne peux participer qu''avec l''une de tes propres vidéos.'
      using errcode = 'P0001';
  end if;

  if exists (
    select 1 from challenge_participations
    where challenge_id = p_challenge_id and user_id = v_user_id
  ) then
    raise exception 'Tu participes déjà à ce défi.' using errcode = 'P0001';
  end if;

  if v_challenge.entry_cost > 0 then
    update profiles set coins = coins - v_challenge.entry_cost
    where id = v_user_id and coins >= v_challenge.entry_cost
    returning coins into v_new_balance;

    if v_new_balance is null then
      raise exception 'Solde de Ballons insuffisant.' using errcode = 'P0001';
    end if;

    insert into transactions (
      user_id, type, amount, currency, balance_after, reason, reference_type, reference_id
    ) values (
      v_user_id, 'spend', -v_challenge.entry_cost, 'coins', v_new_balance,
      case when v_challenge.type = 'battle' then 'join_battle' else 'join_challenge' end,
      'challenge', p_challenge_id
    );

    update challenges set prize_pool = prize_pool + v_challenge.entry_cost
    where id = p_challenge_id;
  end if;

  insert into challenge_participations (challenge_id, user_id, video_id)
  values (p_challenge_id, v_user_id, p_video_id);

  update challenges
  set participants_count = participants_count + 1,
      opponent_id = case when type = 'battle' then coalesce(opponent_id, v_user_id) else opponent_id end
  where id = p_challenge_id;

  return jsonb_build_object('joined', true);
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 8. Votes protégés
-- -------------------------------------------------------------------------
create or replace function vote_for_participant(p_challenge_id uuid, p_participant_id uuid)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_challenge record;
  v_account_age interval;
  v_has_video boolean;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  if v_user_id = p_participant_id then
    raise exception 'Tu ne peux pas voter pour toi-même.' using errcode = 'P0001';
  end if;

  select * into v_challenge from challenges where id = p_challenge_id;
  if v_challenge.id is null then
    raise exception 'Défi introuvable.' using errcode = 'P0001';
  end if;

  if v_challenge.status not in ('active', 'voting') or now() > v_challenge.end_date then
    raise exception 'Ce défi n''accepte plus de votes.' using errcode = 'P0001';
  end if;

  if now() < v_challenge.start_date then
    raise exception 'Ce défi n''a pas encore commencé.' using errcode = 'P0001';
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
  -- compte de plus de 24 h. Bloque les comptes créés à la chaîne pour
  -- truquer un vote.
  select now() - p.created_at,
         exists (select 1 from videos v where v.user_id = p.id and v.status = 'active')
    into v_account_age, v_has_video
  from profiles p
  where p.id = v_user_id and not p.is_banned;

  if v_account_age is null then
    raise exception 'Compte introuvable.' using errcode = 'P0001';
  end if;

  if not v_has_video and v_account_age < interval '24 hours' then
    raise exception 'Publie d''abord une vidéo pour pouvoir voter (ou attends 24 h).'
      using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from challenge_participations
    where challenge_id = p_challenge_id and user_id = p_participant_id
  ) then
    raise exception 'Ce participant n''existe pas dans ce défi.' using errcode = 'P0001';
  end if;

  insert into challenge_votes (challenge_id, voter_id, participant_id)
  values (p_challenge_id, v_user_id, p_participant_id);

  update challenge_participations
  set votes_count = votes_count + 1
  where challenge_id = p_challenge_id and user_id = p_participant_id;

  return jsonb_build_object('voted', true);
exception
  when unique_violation then
    raise exception 'Tu as déjà voté dans ce défi.' using errcode = 'P0001';
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 9. Fin des défis
--   - aucun vote : personne ne gagne, chacun récupère son droit d'entrée ;
--   - Battle sans adversaire, ou égalité : chacun récupère sa mise ;
--   - sinon le plus de votes gagne toute la cagnotte + 100 Stars.
-- -------------------------------------------------------------------------
create or replace function private.refund_participants(p_challenge_id uuid, p_reason text)
returns void as $$
declare
  v_challenge record;
  v_participation record;
  v_new_balance integer;
begin
  select * into v_challenge from challenges where id = p_challenge_id;
  if v_challenge.entry_cost <= 0 or v_challenge.prize_currency != 'coins' then
    return;
  end if;

  for v_participation in
    select user_id from challenge_participations where challenge_id = p_challenge_id
  loop
    update profiles set coins = coins + v_challenge.entry_cost
    where id = v_participation.user_id
    returning coins into v_new_balance;

    if v_new_balance is null then
      continue;
    end if;

    insert into transactions (
      user_id, type, amount, currency, balance_after, reason, reference_type, reference_id
    ) values (
      v_participation.user_id, 'earn', v_challenge.entry_cost, 'coins', v_new_balance,
      p_reason, 'challenge', p_challenge_id
    );

    insert into notifications (user_id, type, title, body, reference_type, reference_id)
    values (
      v_participation.user_id,
      case when v_challenge.type = 'battle' then 'battle_result' else 'challenge_won' end,
      'Mise remboursée',
      '« ' || v_challenge.title || ' » se termine sans vainqueur : tes '
        || v_challenge.entry_cost || ' Ballons te sont rendus.',
      'challenge', p_challenge_id
    );
  end loop;
end;
$$ language plpgsql security definer set search_path = public;

revoke execute on function private.refund_participants(uuid, text) from public, anon, authenticated;

create or replace function resolve_expired_challenges()
returns integer as $$
declare
  v_challenge record;
  v_winner_user_id uuid;
  v_top_votes integer;
  v_second_votes integer;
  v_new_balance integer;
  v_new_stars integer;
  v_resolved_count integer := 0;
  v_rank integer;
  v_participation record;
begin
  for v_challenge in
    select * from challenges
    where status = 'active' and end_date < now()
    for update
  loop
    v_winner_user_id := null;
    v_top_votes := null;
    v_second_votes := null;

    v_rank := 1;
    for v_participation in
      select id, user_id, votes_count from challenge_participations
      where challenge_id = v_challenge.id
      order by votes_count desc, created_at asc
    loop
      update challenge_participations set rank = v_rank where id = v_participation.id;
      if v_rank = 1 then
        v_winner_user_id := v_participation.user_id;
        v_top_votes := v_participation.votes_count;
      elsif v_rank = 2 then
        v_second_votes := v_participation.votes_count;
      end if;
      v_rank := v_rank + 1;
    end loop;

    if v_challenge.type = 'king' then
      v_winner_user_id := v_challenge.record_holder_id;
    elsif coalesce(v_top_votes, 0) = 0 then
      -- Aucun vote (ou aucun participant) : pas de vainqueur.
      v_winner_user_id := null;
    elsif v_challenge.type = 'battle'
          and (v_challenge.participants_count < 2 or v_top_votes = v_second_votes) then
      v_winner_user_id := null;
    end if;

    if v_winner_user_id is null and v_challenge.type != 'king' then
      perform private.refund_participants(v_challenge.id, 'challenge_refund');

      update challenges
      set status = case when v_challenge.type = 'battle' and v_challenge.participants_count < 2
                        then 'cancelled' else 'completed' end,
          winner_id = null,
          prize_pool = 0
      where id = v_challenge.id;

      v_resolved_count := v_resolved_count + 1;
      continue;
    end if;

    if v_winner_user_id is not null then
      if v_challenge.prize_pool > 0 and v_challenge.prize_currency = 'coins' then
        update profiles set coins = coins + v_challenge.prize_pool
        where id = v_winner_user_id
        returning coins into v_new_balance;

        insert into transactions (
          user_id, type, amount, currency, balance_after, reason,
          reference_type, reference_id
        ) values (
          v_winner_user_id, 'earn', v_challenge.prize_pool, 'coins', v_new_balance,
          'win_challenge', 'challenge', v_challenge.id
        );
      end if;

      update profiles
      set stars = stars + 100, challenges_won_count = challenges_won_count + 1
      where id = v_winner_user_id
      returning stars into v_new_stars;

      insert into transactions (
        user_id, type, amount, currency, balance_after, reason,
        reference_type, reference_id
      ) values (
        v_winner_user_id, 'earn', 100, 'stars', v_new_stars,
        'win_challenge', 'challenge', v_challenge.id
      );

      insert into notifications (user_id, type, title, body, reference_type, reference_id)
      values (
        v_winner_user_id,
        case when v_challenge.type = 'battle' then 'battle_result' else 'challenge_won' end,
        case when v_challenge.type = 'battle' then 'Battle gagnée ! ⚔️' else 'Défi remporté !' end,
        'Tu as remporté « ' || v_challenge.title || ' » 🏆',
        'challenge', v_challenge.id
      );
    end if;

    update challenges
    set status = 'completed', winner_id = v_winner_user_id
    where id = v_challenge.id;

    v_resolved_count := v_resolved_count + 1;
  end loop;

  return v_resolved_count;
end;
$$ language plpgsql security definer set search_path = public;

revoke execute on function resolve_expired_challenges() from public, anon, authenticated;


-- ===================== 20260101000025_welcome_bonus_100.sql =====================
-- Bonus de bienvenue : 100 Ballons au lieu de 500 (décision de Tom,
-- 15/10/2026 : les Ballons doivent rester rares pour que les joueurs aient
-- envie d'en acheter). Le montant est lu dans `app_config.economy`, il se
-- change désormais sans toucher au code. Les comptes existants gardent ce
-- qu'ils ont.

create schema if not exists private;

update app_config
set value = value || '{"welcome_bonus": 100}'::jsonb
where key = 'economy';

alter table profiles alter column coins set default 0;

create or replace function private.welcome_bonus()
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select (value ->> 'welcome_bonus')::integer from app_config where key = 'economy'), 100);
$$;

revoke execute on function private.welcome_bonus() from public, anon, authenticated;

create or replace function handle_new_user()
returns trigger as $$
declare
  v_role text := coalesce(new.raw_user_meta_data ->> 'role', 'player');
  v_already_confirmed boolean := new.email_confirmed_at is not null;
  v_initial_coins integer := case
    when v_role = 'player' and v_already_confirmed then private.welcome_bonus()
    else 0
  end;
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
    v_initial_coins
  );

  if v_initial_coins > 0 then
    insert into public.transactions (user_id, type, amount, currency, balance_after, reason)
    values (new.id, 'earn', v_initial_coins, 'coins', v_initial_coins, 'welcome_bonus');
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- Crédite le bonus de bienvenue au moment réel de la confirmation d'e-mail,
-- pour les comptes qui n'étaient pas déjà confirmés à l'inscription.
-- -------------------------------------------------------------------------
create or replace function handle_user_email_confirmed()
returns trigger as $$
declare
  v_new_balance integer;
  v_bonus integer := private.welcome_bonus();
begin
  update public.profiles
  set coins = coins + v_bonus
  where id = new.id and role = 'player'
  returning coins into v_new_balance;

  if v_new_balance is not null then
    insert into public.transactions (user_id, type, amount, currency, balance_after, reason)
    values (new.id, 'earn', v_bonus, 'coins', v_new_balance, 'welcome_bonus');
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;


revoke execute on function handle_new_user() from public, anon, authenticated;
revoke execute on function handle_user_email_confirmed() from public, anon, authenticated;


-- ===================== 20260101000027_battle_opponents.sql =====================
-- Battle : choisir son adversaire parmi les joueurs qu'on suit ou qui nous
-- suivent, ou laisser le hasard choisir.
--
-- Corrige aussi l'erreur « column "is_banned" does not exist » : les RPC
-- de la migration 0024 (create_battle, vote_for_participant) filtrent les
-- comptes bannis, mais la base de production n'avait pas reçu la colonne
-- (migration 0022 non appliquée). On l'ajoute ici si elle manque.

alter table profiles add column if not exists is_banned boolean not null default false;
alter table profiles add column if not exists banned_at timestamptz;
alter table profiles add column if not exists ban_reason text;

-- -------------------------------------------------------------------------
-- 1. Suggestions d'adversaires : abonnés et abonnements du joueur
-- -------------------------------------------------------------------------
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

-- -------------------------------------------------------------------------
-- 2. create_battle : nouvelle option « adversaire aléatoire »
-- -------------------------------------------------------------------------
drop function if exists create_battle(text, text, integer, uuid, timestamptz, text);

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
    -- Adversaire aléatoire : un vrai joueur (non banni) qui a au moins une
    -- vidéo publiée, pour qu'il puisse relever la Battle.
    select p.id into v_opponent_id
    from profiles p
    where p.id != v_user_id
      and p.role = 'player'
      and not p.is_banned
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

    if v_opponent_id is null then
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


-- ===================== Planification : résolution automatique des défis =====================
create extension if not exists pg_cron;
select cron.schedule(
  'resolve-expired-challenges',
  '*/15 * * * *',
  'select public.resolve_expired_challenges();'
);
