import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_badge.dart';

abstract class BadgesRepository {
  Future<Either<Failure, List<UserBadge>>> getUserBadges(String userId);
}
