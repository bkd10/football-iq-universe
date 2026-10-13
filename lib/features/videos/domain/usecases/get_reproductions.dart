import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/video.dart';
import '../repositories/video_repository.dart';

class GetReproductions {
  const GetReproductions(this._repository);

  final VideoRepository _repository;

  Future<Either<Failure, List<Video>>> call(String moveId) {
    return _repository.getReproductions(moveId);
  }
}
