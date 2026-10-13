import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_badge.dart';
import '../repositories/badges_repository.dart';

class GetUserBadges {
  const GetUserBadges(this._repository);

  final BadgesRepository _repository;

  Future<Either<Failure, List<UserBadge>>> call(String userId) {
    return _repository.getUserBadges(userId);
  }
}
