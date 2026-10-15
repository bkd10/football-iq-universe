/// Valeurs par défaut de l'économie (Ballons/Stars).
///
/// Ces valeurs sont **indicatives côté client** (affichage uniquement).
/// La vérité vient toujours de `app_config.economy` côté serveur et de la
/// logique des Edge Functions — le client ne fait jamais confiance à ses
/// propres calculs pour créditer/débiter un solde.
class EconomyConstants {
  const EconomyConstants._();

  // Gains (Ballons)
  // Règles v2 (15/10/2026) : la connexion quotidienne et les Moves
  // reproduits ne rapportent plus rien.
  static const int welcomeBonus = 100;
  static const int postVideoReward = 5;
  static const int maxPostVideoRewardsPerDay = 3;
  static const int fullWatchTarget = 20;
  static const int fullWatchReward = 30;
  static const int adWatchedReward = 30;
  static const int maxAdWatchedPerDay = 5;
  static const int inviteFriendReward = 100;

  // Dépenses (Ballons)
  static const int joinChallengeCost = 20;
  static const int battleMinStake = 10;
  static const int battleMaxStake = 10000;
  static const int createChallengeCost = 200;
  static const int boostVideoCost = 100;
  static const int customBadgeCost = 300;
  static const int specialEffectCost = 50;

  // Seuils de niveau (Stars) — répliqués côté serveur par le trigger
  // `update_user_level`.
  static const int risingStarThreshold = 500;
  static const int prodigyThreshold = 5000;
  static const int legendThreshold = 25000;

  // 1 Star gagnée toutes les N vues (créateur).
  static const int viewsPerStar = 100;
}

/// Raisons acceptées par les RPC serveur `award_coins`/`spend_coins` (voir
/// `supabase/migrations/20260101000005_economy_rpc.sql`). Centralisées ici
/// pour éviter les fautes de frappe dans les chaînes littérales.
class EconomyReason {
  const EconomyReason._();

  // award_coins
  static const String dailyLogin = 'daily_login';
  static const String postVideo = 'post_video';
  static const String adWatched = 'ad_watched';

  // spend_coins
  static const String joinChallenge = 'join_challenge';
  static const String joinBattle = 'join_battle';
  static const String createChallenge = 'create_challenge';
  static const String boostVideo = 'boost_video';
  static const String customBadge = 'custom_badge';
  static const String specialEffect = 'special_effect';
}
