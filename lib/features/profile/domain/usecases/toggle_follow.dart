import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/social_repository.dart';

class ToggleFollow {
  const ToggleFollow(this._repository);

  final SocialRepository _repository;

  Future<Either<Failure, void>> call({
    required String userId,
    required bool currentlyFollowing,
  }) {
    return _repository.toggleFollow(
      userId: userId,
      currentlyFollowing: currentlyFollowing,
    );
  }
}
