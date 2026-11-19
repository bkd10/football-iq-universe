import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/safety_remote_datasource.dart';
import '../../domain/safety_models.dart';

final safetyDataSourceProvider = Provider<SafetyRemoteDataSource>(
  (ref) => SafetyRemoteDataSource(ref.watch(supabaseClientProvider)),
);

/// Règles d'âge du serveur (écran d'inscription). Serveur injoignable :
/// valeurs par défaut, le serveur refusera de toute façon.
final ageRulesProvider = FutureProvider<AgeRules>((ref) async {
  try {
    return await ref.watch(safetyDataSourceProvider).getAgeRules();
  } catch (_) {
    return const AgeRules();
  }
});

/// Réglages de l'utilisateur connecté. Pas encore chargés ou erreur :
/// réglages prudents ([MySafety.fallback]).
final mySafetyProvider = FutureProvider<MySafety>((ref) async {
  final profile = ref.watch(authStateProvider).valueOrNull;
  if (profile == null) return MySafety.fallback;
  try {
    return await ref.watch(safetyDataSourceProvider).getMySafety();
  } catch (_) {
    return MySafety.fallback;
  }
});

/// Valeur immédiate (prudente tant que le serveur n'a pas répondu).
final mySafetyNowProvider = Provider<MySafety>(
  (ref) => ref.watch(mySafetyProvider).valueOrNull ?? MySafety.fallback,
);

final publicProfileProvider = FutureProvider.autoDispose
    .family<({Profile? profile, PublicProfileFlags flags}), String>((ref, userId) async {
  final r = await ref.watch(safetyDataSourceProvider).getPublicProfile(userId);
  return (profile: r.profile?.toEntity(), flags: r.flags);
});

final myBlocksProvider = FutureProvider.autoDispose<List<BlockedUser>>(
  (ref) => ref.watch(safetyDataSourceProvider).listBlocks(),
);
