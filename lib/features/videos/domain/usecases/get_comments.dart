import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/video_comment.dart';
import '../repositories/video_repository.dart';

class GetComments {
  const GetComments(this._repository);

  final VideoRepository _repository;

  Future<Either<Failure, List<VideoComment>>> call(String videoId) {
    return _repository.getComments(videoId);
  }
}
