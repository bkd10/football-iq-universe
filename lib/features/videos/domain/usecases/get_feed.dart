import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/video.dart';
import '../repositories/video_repository.dart';

class GetFeed {
  const GetFeed(this._repository);

  final VideoRepository _repository;

  Future<Either<Failure, List<Video>>> call({
    int limit = 10,
    DateTime? beforeCreatedAt,
  }) {
    return _repository.getFeed(limit: limit, beforeCreatedAt: beforeCreatedAt);
  }
}

/// Vestiaire : le feed des joueurs suivis.
class GetFollowingFeed {
  const GetFollowingFeed(this._repository);

  final VideoRepository _repository;

  Future<Either<Failure, List<Video>>> call({
    int limit = 10,
    DateTime? beforeCreatedAt,
  }) {
    return _repository.getFollowingFeed(limit: limit, beforeCreatedAt: beforeCreatedAt);
  }
}
