import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../core/services/video_source/video_source_service.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../data/datasources/video_remote_datasource.dart';
import '../../data/repositories/video_repository_impl.dart';
import '../../domain/entities/video.dart';
import '../../domain/entities/video_comment.dart';
import '../../domain/repositories/video_repository.dart';
import '../../domain/usecases/add_comment.dart';
import '../../domain/usecases/get_comments.dart';
import '../../domain/usecases/get_feed.dart';
import '../../domain/usecases/get_reproductions.dart';
import '../../domain/usecases/get_trending_moves.dart';
import '../../domain/usecases/get_video_by_id.dart';
import '../../domain/usecases/get_videos_by_user.dart';
import '../../domain/usecases/register_view.dart';
import '../../domain/usecases/toggle_like.dart';
import '../../domain/usecases/upload_video.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(supabaseClientProvider));
});

/// Sélection caméra/galerie + compression, derrière une interface unique
/// (mobile/web) — voir `VideoSourceService`. Jamais `ImagePicker`/
/// `VideoCompress` appelés directement depuis un écran.
final videoSourceServiceProvider = Provider<VideoSourceService>((ref) {
  return VideoSourceService();
});

final videoRemoteDataSourceProvider = Provider<VideoRemoteDataSource>((ref) {
  return VideoRemoteDataSource(
    ref.watch(supabaseClientProvider),
    ref.watch(storageServiceProvider),
  );
});

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  return VideoRepositoryImpl(ref.watch(videoRemoteDataSourceProvider));
});

final getFeedUseCaseProvider = Provider(
  (ref) => GetFeed(ref.watch(videoRepositoryProvider)),
);
final getFollowingFeedUseCaseProvider = Provider(
  (ref) => GetFollowingFeed(ref.watch(videoRepositoryProvider)),
);
final toggleLikeUseCaseProvider = Provider(
  (ref) => ToggleLike(ref.watch(videoRepositoryProvider)),
);
final getCommentsUseCaseProvider = Provider(
  (ref) => GetComments(ref.watch(videoRepositoryProvider)),
);
final addCommentUseCaseProvider = Provider(
  (ref) => AddComment(ref.watch(videoRepositoryProvider)),
);
final registerViewUseCaseProvider = Provider(
  (ref) => RegisterView(ref.watch(videoRepositoryProvider)),
);
final uploadVideoUseCaseProvider = Provider(
  (ref) => UploadVideo(ref.watch(videoRepositoryProvider)),
);
final getVideosByUserUseCaseProvider = Provider(
  (ref) => GetVideosByUser(ref.watch(videoRepositoryProvider)),
);

/// Vidéos d'un profil donné — grille "Mes vidéos" / "Mes Moves" du Football
/// Passport (filtrées côté widget par `isMove`).
final userVideosProvider =
    FutureProvider.family<List<Video>, String>((ref, userId) async {
  final result = await ref.watch(getVideosByUserUseCaseProvider)(userId);
  return result.fold((failure) => throw failure, (videos) => videos);
});

final getVideoByIdUseCaseProvider = Provider(
  (ref) => GetVideoById(ref.watch(videoRepositoryProvider)),
);
final getReproductionsUseCaseProvider = Provider(
  (ref) => GetReproductions(ref.watch(videoRepositoryProvider)),
);
final getTrendingMovesUseCaseProvider = Provider(
  (ref) => GetTrendingMoves(ref.watch(videoRepositoryProvider)),
);

/// Un Move ou une vidéo par id — fiche d'un Move et bannière "Tu reproduis
/// ce Move" de l'écran de création.
final videoByIdProvider =
    FutureProvider.family<Video?, String>((ref, videoId) async {
  final result = await ref.watch(getVideoByIdUseCaseProvider)(videoId);
  return result.fold((failure) => throw failure, (video) => video);
});

final moveReproductionsProvider =
    FutureProvider.family<List<Video>, String>((ref, moveId) async {
  final result = await ref.watch(getReproductionsUseCaseProvider)(moveId);
  return result.fold((failure) => throw failure, (videos) => videos);
});

final trendingMovesProvider = FutureProvider<List<Video>>((ref) async {
  final result = await ref.watch(getTrendingMovesUseCaseProvider)();
  return result.fold((failure) => throw failure, (videos) => videos);
});

/// Feed paginé avec mise à jour optimiste des likes/Masterclass : le
/// compteur et le flag `hasLiked` changent à l'écran avant même la réponse
/// serveur, puis sont annulés silencieusement en cas d'échec.
class FeedController extends AsyncNotifier<List<Video>> {
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  Future<List<Video>> build() => _fetchPage();

  Future<List<Video>> _fetchPage({DateTime? before}) async {
    final result = await fetch(before);
    return result.fold((failure) => throw failure, (videos) => videos);
  }

  /// La source du feed : « Ouverture » par défaut, le Vestiaire dans
  /// [FollowingFeedController].
  Future<Either<Failure, List<Video>>> fetch(DateTime? before) {
    return ref.read(getFeedUseCaseProvider)(beforeCreatedAt: before);
  }

  Future<void> refresh() async {
    _hasMore = true;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchPage);
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final current = state.valueOrNull;
    if (current == null || current.isEmpty) return;

    _isLoadingMore = true;
    try {
      final more = await _fetchPage(before: current.last.createdAt);
      if (more.isEmpty) _hasMore = false;
      state = AsyncData([...current, ...more]);
    } catch (_) {
      // Le feed existant reste affiché ; l'utilisateur peut re-scroller.
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> toggleLike(String videoId, {required bool isMasterclass}) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final index = current.indexWhere((v) => v.id == videoId);
    if (index == -1) return;

    final video = current[index];
    final currentlyActive = isMasterclass ? video.hasMasterclassed : video.hasLiked;

    final optimistic = [...current];
    optimistic[index] = _applyReactionLocally(
      video,
      isMasterclass: isMasterclass,
      currentlyActive: currentlyActive,
    );
    state = AsyncData(optimistic);

    final result = await ref.read(toggleLikeUseCaseProvider)(
      videoId: videoId,
      currentlyLiked: currentlyActive,
      isMasterclass: isMasterclass,
    );

    result.fold(
      (failure) {
        final rolledBack = [...optimistic];
        rolledBack[index] = video;
        state = AsyncData(rolledBack);
      },
      (_) {},
    );
  }

  Video _applyReactionLocally(
    Video video, {
    required bool isMasterclass,
    required bool currentlyActive,
  }) {
    if (isMasterclass) {
      final wasLiked = !currentlyActive && video.hasLiked;
      return video.copyWith(
        hasMasterclassed: !currentlyActive,
        hasLiked: currentlyActive ? video.hasLiked : false,
        masterclassCount: video.masterclassCount + (currentlyActive ? -1 : 1),
        likesCount: wasLiked ? video.likesCount - 1 : video.likesCount,
      );
    }
    final wasMasterclassed = !currentlyActive && video.hasMasterclassed;
    return video.copyWith(
      hasLiked: !currentlyActive,
      hasMasterclassed: currentlyActive ? video.hasMasterclassed : false,
      likesCount: video.likesCount + (currentlyActive ? -1 : 1),
      masterclassCount:
          wasMasterclassed ? video.masterclassCount - 1 : video.masterclassCount,
    );
  }

  Future<void> registerView(String videoId) async {
    final result = await ref.read(registerViewUseCaseProvider)(videoId);
    final succeeded = result.isRight();
    if (!succeeded) return;

    final current = state.valueOrNull;
    if (current == null) return;
    final index = current.indexWhere((v) => v.id == videoId);
    if (index == -1) return;
    final updated = [...current];
    updated[index] = updated[index].copyWith(
      viewsCount: updated[index].viewsCount + 1,
    );
    state = AsyncData(updated);
  }
}

final feedControllerProvider =
    AsyncNotifierProvider<FeedController, List<Video>>(FeedController.new);

/// Vestiaire : mêmes interactions que le feed, vidéos des joueurs suivis.
class FollowingFeedController extends FeedController {
  @override
  Future<Either<Failure, List<Video>>> fetch(DateTime? before) {
    return ref.read(getFollowingFeedUseCaseProvider)(beforeCreatedAt: before);
  }
}

final followingFeedControllerProvider =
    AsyncNotifierProvider<FeedController, List<Video>>(FollowingFeedController.new);

/// Commentaires d'une vidéo, invalidés (`ref.invalidate`) après l'ajout
/// d'un nouveau commentaire pour rafraîchir la liste.
final videoCommentsProvider =
    FutureProvider.family<List<VideoComment>, String>((ref, videoId) async {
  final result = await ref.watch(getCommentsUseCaseProvider)(videoId);
  return result.fold((failure) => throw failure, (comments) => comments);
});

/// Équivalent de [FeedController] mais pour une vidéo consultée hors du
/// fil principal (grille du profil, fiche Move, recherche...) — écran
/// "Video Detail" (PARTIE 9.2, écran 8). Même logique de mise à jour
/// optimiste du like/Masterclass, sans dépendre de l'état de la liste feed.
class VideoDetailController extends FamilyAsyncNotifier<Video?, String> {
  @override
  Future<Video?> build(String videoId) async {
    final result = await ref.watch(getVideoByIdUseCaseProvider)(videoId);
    return result.fold((failure) => throw failure, (video) => video);
  }

  Future<void> toggleLike({required bool isMasterclass}) async {
    final video = state.valueOrNull;
    if (video == null) return;
    final currentlyActive = isMasterclass ? video.hasMasterclassed : video.hasLiked;

    state = AsyncData(_applyReactionLocally(video, isMasterclass: isMasterclass, currentlyActive: currentlyActive));

    final result = await ref.read(toggleLikeUseCaseProvider)(
      videoId: arg,
      currentlyLiked: currentlyActive,
      isMasterclass: isMasterclass,
    );

    result.fold((failure) => state = AsyncData(video), (_) {});
  }

  Future<void> registerView() async {
    final result = await ref.read(registerViewUseCaseProvider)(arg);
    if (result.isLeft()) return;
    final video = state.valueOrNull;
    if (video == null) return;
    state = AsyncData(video.copyWith(viewsCount: video.viewsCount + 1));
  }

  Video _applyReactionLocally(
    Video video, {
    required bool isMasterclass,
    required bool currentlyActive,
  }) {
    if (isMasterclass) {
      final wasLiked = !currentlyActive && video.hasLiked;
      return video.copyWith(
        hasMasterclassed: !currentlyActive,
        hasLiked: currentlyActive ? video.hasLiked : false,
        masterclassCount: video.masterclassCount + (currentlyActive ? -1 : 1),
        likesCount: wasLiked ? video.likesCount - 1 : video.likesCount,
      );
    }
    final wasMasterclassed = !currentlyActive && video.hasMasterclassed;
    return video.copyWith(
      hasLiked: !currentlyActive,
      hasMasterclassed: currentlyActive ? video.hasMasterclassed : false,
      likesCount: video.likesCount + (currentlyActive ? -1 : 1),
      masterclassCount:
          wasMasterclassed ? video.masterclassCount - 1 : video.masterclassCount,
    );
  }
}

final videoDetailControllerProvider = AsyncNotifierProvider.family<
    VideoDetailController, Video?, String>(VideoDetailController.new);
