import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../data/datasources/social_remote_datasource.dart';
import '../../data/repositories/social_repository_impl.dart';
import '../../domain/repositories/social_repository.dart';
import '../../domain/usecases/is_following.dart';
import '../../domain/usecases/toggle_follow.dart';

final socialRemoteDataSourceProvider = Provider<SocialRemoteDataSource>((ref) {
  return SocialRemoteDataSource(ref.watch(supabaseClientProvider));
});

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepositoryImpl(ref.watch(socialRemoteDataSourceProvider));
});

final isFollowingUseCaseProvider = Provider(
  (ref) => IsFollowing(ref.watch(socialRepositoryProvider)),
);
final toggleFollowUseCaseProvider = Provider(
  (ref) => ToggleFollow(ref.watch(socialRepositoryProvider)),
);

/// État de suivi d'un profil donné (`userId`), avec mise à jour optimiste.
/// Utilisé par le bouton "Suivre" du feed et du profil.
class FollowController extends FamilyAsyncNotifier<bool, String> {
  @override
  Future<bool> build(String arg) async {
    final result = await ref.read(isFollowingUseCaseProvider)(arg);
    return result.fold((_) => false, (isFollowing) => isFollowing);
  }

  Future<void> toggle() async {
    final userId = arg;
    final current = state.valueOrNull ?? false;
    state = AsyncData(!current);

    final result = await ref.read(toggleFollowUseCaseProvider)(
      userId: userId,
      currentlyFollowing: current,
    );
    result.fold((failure) => state = AsyncData(current), (_) {});
  }
}

final followControllerProvider =
    AsyncNotifierProvider.family<FollowController, bool, String>(
  FollowController.new,
);
