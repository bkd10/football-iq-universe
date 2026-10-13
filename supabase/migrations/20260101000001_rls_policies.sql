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
