import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart' show XFile;

import '../../../../core/errors/failures.dart';
import '../entities/video.dart';
import '../entities/video_comment.dart';

/// Contrat du domaine pour tout ce qui touche aux vidéos : lecture du feed,
/// likes/Masterclass, commentaires, et publication. Aucune dépendance vers
/// Supabase — voir `data/repositories/video_repository_impl.dart`.
abstract class VideoRepository {
  /// Feed paginé, trié par `talent_score` (voir PARTIE 5 — algorithme
  /// Talent First). `beforeCreatedAt` permet la pagination par curseur.
  Future<Either<Failure, List<Video>>> getFeed({
    int limit = 10,
    DateTime? beforeCreatedAt,
  });

  Future<Either<Failure, List<Video>>> getVideosByUser(String userId);

  Future<Either<Failure, Video?>> getVideoById(String videoId);

  /// Vidéos ayant reproduit ce Move (`original_move_id = videoId`), triées
  /// par popularité — voir la fiche d'un Move (PARTIE 8.2).
  Future<Either<Failure, List<Video>>> getReproductions(String moveId);

  /// Moves du moment (PARTIE 9.2 — écran "Trending Moves"), triés par
  /// nombre de reproductions.
  Future<Either<Failure, List<Video>>> getTrendingMoves({int limit = 20});

  Future<Either<Failure, void>> toggleLike({
    required String videoId,
    required bool currentlyLiked,
    bool isMasterclass = false,
  });

  Future<Either<Failure, List<VideoComment>>> getComments(String videoId);

  Future<Either<Failure, VideoComment>> addComment({
    required String videoId,
    required String content,
    String? parentId,
  });

  Future<Either<Failure, void>> registerView(String videoId);

  Future<Either<Failure, Video>> uploadVideo({
    required XFile videoFile,
    required String caption,
    required String category,
    int? durationSeconds,
    bool isMove = false,
    String? moveName,
    String? originalMoveId,
    XFile? thumbnailFile,
  });
}
