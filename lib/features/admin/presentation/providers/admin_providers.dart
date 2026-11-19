import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../data/admin_remote_datasource.dart';
import '../../domain/admin_models.dart';

final adminDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminRemoteDataSource(ref.watch(supabaseClientProvider));
});

final adminStatsProvider = FutureProvider.autoDispose<AdminStats>((ref) {
  return ref.watch(adminDataSourceProvider).getStats();
});

final adminReportsProvider = FutureProvider.autoDispose<List<AdminReport>>((ref) {
  return ref.watch(adminDataSourceProvider).getReports();
});

/// Signalements déjà traités (historique, avec date de traitement).
final adminHandledReportsProvider = FutureProvider.autoDispose<List<AdminReport>>((ref) {
  return ref.watch(adminDataSourceProvider).getReports(status: 'handled');
});

final adminUserSearchProvider = StateProvider.autoDispose<String>((ref) => '');

final adminUsersProvider = FutureProvider.autoDispose<List<AdminUser>>((ref) {
  final search = ref.watch(adminUserSearchProvider);
  return ref.watch(adminDataSourceProvider).getUsers(search: search.isEmpty ? null : search);
});

final adminSponsoredDraftsProvider = FutureProvider.autoDispose<List<AdminSponsoredDraft>>((ref) {
  return ref.watch(adminDataSourceProvider).getSponsoredDrafts();
});

final adminVoteFlagsStatusProvider = StateProvider.autoDispose<String>((ref) => 'pending');

final adminVoteFlagsProvider = FutureProvider.autoDispose<List<AdminVoteFlag>>((ref) {
  return ref.watch(adminDataSourceProvider).getVoteFlags(status: ref.watch(adminVoteFlagsStatusProvider));
});

final adminPendingVoteFlagsProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    return await ref.watch(adminDataSourceProvider).pendingVoteFlagsCount();
  } catch (_) {
    return 0;
  }
});

/// Texte lisible pour une erreur du panneau admin (message du serveur).
String adminErrorText(Object error) =>
    error is ServerException ? error.message.trServer : 'Une erreur est survenue.'.tr;
