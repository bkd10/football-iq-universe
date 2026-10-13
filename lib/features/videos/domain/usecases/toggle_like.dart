import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/video_repository.dart';

class ToggleLike {
  const ToggleLike(this._repository);

  final VideoRepository _repository;

  Future<Either<Failure, void>> call({
    required String videoId,
    required bool currentlyLiked,
    bool isMasterclass = false,
  }) {
    return _repository.toggleLike(
      videoId: videoId,
      currentlyLiked: currentlyLiked,
      isMasterclass: isMasterclass,
    );
  }
}
