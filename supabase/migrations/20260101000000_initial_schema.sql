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
