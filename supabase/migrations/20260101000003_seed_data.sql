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
