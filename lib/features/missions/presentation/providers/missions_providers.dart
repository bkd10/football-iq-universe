import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/missions_remote_datasource.dart';
import '../../data/repositories/missions_repository_impl.dart';
import '../../domain/entities/daily_mission.dart';
import '../../domain/repositories/missions_repository.dart';
import '../../domain/usecases/get_today_mission.dart';
import '../../domain/usecases/increment_videos_watched.dart';

final missionsRemoteDataSourceProvider = Provider<MissionsRemoteDataSource>((ref) {
  return MissionsRemoteDataSource(ref.watch(supabaseClientProvider));
});

final missionsRepositoryProvider = Provider<MissionsRepository>((ref) {
  return MissionsRepositoryImpl(ref.watch(missionsRemoteDataSourceProvider));
});

final getTodayMissionUseCaseProvider = Provider(
  (ref) => GetTodayMission(ref.watch(missionsRepositoryProvider)),
);
final incrementVideosWatchedUseCaseProvider = Provider(
  (ref) => IncrementVideosWatched(ref.watch(missionsRepositoryProvider)),
);

final todayMissionProvider = FutureProvider<DailyMission>((ref) async {
  final result = await ref.watch(getTodayMissionUseCaseProvider)();
  return result.fold((failure) => throw failure, (mission) => mission);
});

/// Contrôleur pour incrémenter "vidéos regardées" depuis le feed, en
/// rafraîchissant `todayMissionProvider` et le profil (le bonus de palier
/// modifie `coins`) après succès.
class MissionsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> registerVideoWatched() async {
    final result = await ref.read(incrementVideosWatchedUseCaseProvider)();
    result.fold((_) {}, (_) {
      ref.invalidate(todayMissionProvider);
      ref.invalidate(currentProfileProvider);
    });
  }
}

final missionsControllerProvider =
    AsyncNotifierProvider<MissionsController, void>(MissionsController.new);
