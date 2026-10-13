import 'supabase_config.dart';

/// Feature flags chargés depuis la table Supabase `app_config` (clé
/// `feature_flags`) et rafraîchis au lancement de l'app.
///
/// Permet d'activer/désactiver des rôles et fonctionnalités (scouting,
/// paiements, clubs, IA...) sans redéploiement, pour un lancement progressif.
class FeatureFlags {
  const FeatureFlags._();

  static Map<String, bool> _flags = const {};

  static bool get scoutingEnabled => _flags['scouting'] ?? false;
  static bool get paymentsEnabled => _flags['payments'] ?? false;
  static bool get clubAccountsEnabled => _flags['club_accounts'] ?? false;
  static bool get academyAccountsEnabled => _flags['academy_accounts'] ?? false;
  static bool get aiVideoAnalysisEnabled => _flags['ai_analysis'] ?? false;
  static bool get liveBattlesEnabled => _flags['live_battles'] ?? false;
  static bool get worldChallengesEnabled => _flags['world_challenges'] ?? false;
  static bool get sponsoredChallengesEnabled =>
      _flags['sponsored_challenges'] ?? false;

  /// Récupère les flags depuis Supabase. À appeler au démarrage (splash).
  /// En cas d'échec réseau, conserve les valeurs par défaut (tout désactivé
  /// sauf ce qui est jugé sûr), pour ne jamais bloquer le lancement.
  static Future<void> load() async {
    try {
      final response = await SupabaseConfig.client
          .from('app_config')
          .select('value')
          .eq('key', 'feature_flags')
          .maybeSingle();

      final value = response?['value'] as Map<String, dynamic>?;
      if (value == null) return;

      _flags = value.map((key, dynamic v) => MapEntry(key, v == true));
    } catch (_) {
      // Réseau indisponible : on démarre avec les flags par défaut (désactivés).
    }
  }
}
