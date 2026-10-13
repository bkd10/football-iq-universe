import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/social_repository.dart';

class IsFollowing {
  const IsFollowing(this._repository);

  final SocialRepository _repository;

  Future<Either<Failure, bool>> call(String userId) {
    return _repository.isFollowing(userId);
  }
}
