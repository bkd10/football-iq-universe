import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/video.dart';
import '../repositories/video_repository.dart';

class GetVideoById {
  const GetVideoById(this._repository);

  final VideoRepository _repository;

  Future<Either<Failure, Video?>> call(String videoId) {
    return _repository.getVideoById(videoId);
  }
}
