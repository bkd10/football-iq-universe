import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../data/datasources/moderation_remote_datasource.dart';
import '../../data/repositories/moderation_repository_impl.dart';
import '../../domain/entities/content_report.dart';
import '../../domain/repositories/moderation_repository.dart';

final moderationRemoteDataSourceProvider = Provider<ModerationRemoteDataSource>((ref) {
  return ModerationRemoteDataSource(ref.watch(supabaseClientProvider));
});

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return ModerationRepositoryImpl(ref.watch(moderationRemoteDataSourceProvider));
});

/// Liste des signalements en attente — vide (jamais une erreur visible)
/// pour un non-admin, la RLS ne renvoyant simplement aucune ligne.
final pendingReportsProvider = FutureProvider.autoDispose<List<ContentReport>>((ref) async {
  final result = await ref.watch(moderationRepositoryProvider).getPendingReports();
  return result.fold((failure) => throw failure, (reports) => reports);
});

class ModerationActionsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(moderationRepositoryProvider).reportContent(
          targetType: targetType,
          targetId: targetId,
          reason: reason,
        );
    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }

  Future<bool> resolveReport({
    required String reportId,
    required String status,
    String? resolutionNote,
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(moderationRepositoryProvider).resolveReport(
          reportId: reportId,
          status: status,
          resolutionNote: resolutionNote,
        );
    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        ref.invalidate(pendingReportsProvider);
        return true;
      },
    );
  }
}

final moderationActionsControllerProvider =
    AsyncNotifierProvider<ModerationActionsController, void>(
  ModerationActionsController.new,
);
