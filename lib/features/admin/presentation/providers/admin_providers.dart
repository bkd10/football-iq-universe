import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final adminUserSearchProvider = StateProvider.autoDispose<String>((ref) => '');

final adminUsersProvider = FutureProvider.autoDispose<List<AdminUser>>((ref) {
  final search = ref.watch(adminUserSearchProvider);
  return ref.watch(adminDataSourceProvider).getUsers(search: search.isEmpty ? null : search);
});

/// Texte lisible pour une erreur du panneau admin (message du serveur).
String adminErrorText(Object error) =>
    error is ServerException ? error.message : 'Une erreur est survenue.';
