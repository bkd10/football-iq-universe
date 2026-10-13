import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart' show XFile;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/video.dart';
import '../../domain/entities/video_comment.dart';
import '../../domain/repositories/video_repository.dart';
import '../datasources/video_remote_datasource.dart';
import '../models/video_model.dart';

class VideoRepositoryImpl implements VideoRepository {
  const VideoRepositoryImpl(this._remoteDataSource);

  final VideoRemoteDataSource _remoteDataSource;

  Future<List<Video>> _withReactions(List<VideoModel> models) async {
    if (models.isEmpty) return const [];
    final reactions = await _remoteDataSource.getMyReactions(
      models.map((m) => m.id).toList(),
    );
    return models
        .map(
          (m) => m.toEntity(
            hasLiked: reactions.liked.contains(m.id),
            hasMasterclassed: reactions.masterclassed.contains(m.id),
          ),
        )
        .toList();
  }

  @override
  Future<Either<Failure, List<Video>>> getFeed({
    int limit = 10,
    DateTime? beforeCreatedAt,
  }) async {
    try {
      final models = await _remoteDataSource.getFeed(
        limit: limit,
        beforeCreatedAt: beforeCreatedAt,
      );
      return Right(await _withReactions(models));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<Video>>> getVideosByUser(String userId) async {
    try {
      final models = await _remoteDataSource.getVideosByUser(userId);
      return Right(await _withReactions(models));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Video?>> getVideoById(String videoId) async {
    try {
      final model = await _remoteDataSource.getVideoById(videoId);
      if (model == null) return const Right(null);
      final withReactions = await _withReactions([model]);
      return Right(withReactions.first);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<Video>>> getReproductions(String moveId) async {
    try {
      final models = await _remoteDataSource.getReproductions(moveId);
      return Right(await _withReactions(models));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<Video>>> getTrendingMoves({int limit = 20}) async {
    try {
      final models = await _remoteDataSource.getTrendingMoves(limit: limit);
      return Right(await _withReactions(models));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> toggleLike({
    required String videoId,
    required bool currentlyLiked,
    bool isMasterclass = false,
  }) async {
    try {
      await _remoteDataSource.toggleLike(
        videoId: videoId,
        currentlyLiked: currentlyLiked,
        isMasterclass: isMasterclass,
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<VideoComment>>> getComments(
    String videoId,
  ) async {
    try {
      final models = await _remoteDataSource.getComments(videoId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, VideoComment>> addComment({
    required String videoId,
    required String content,
    String? parentId,
  }) async {
    try {
      final model = await _remoteDataSource.addComment(
        videoId: videoId,
        content: content,
        parentId: parentId,
      );
      return Right(model.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> registerView(String videoId) async {
    try {
      await _remoteDataSource.registerView(videoId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Video>> uploadVideo({
    required XFile videoFile,
    required String caption,
    required String category,
    int? durationSeconds,
    bool isMove = false,
    String? moveName,
    String? originalMoveId,
    XFile? thumbnailFile,
  }) async {
    try {
      final model = await _remoteDataSource.uploadVideo(
        videoFile: videoFile,
        caption: caption,
        category: category,
        durationSeconds: durationSeconds,
        isMove: isMove,
        moveName: moveName,
        originalMoveId: originalMoveId,
        thumbnailFile: thumbnailFile,
      );
      return Right(model.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
