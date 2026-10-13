import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/video.dart';
import '../repositories/video_repository.dart';

class GetTrendingMoves {
  const GetTrendingMoves(this._repository);

  final VideoRepository _repository;

  Future<Either<Failure, List<Video>>> call({int limit = 20}) {
    return _repository.getTrendingMoves(limit: limit);
  }
}
