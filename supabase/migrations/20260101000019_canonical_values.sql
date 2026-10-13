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
