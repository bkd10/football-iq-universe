import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/notifications_repository.dart';

class GetUnreadNotificationsCount {
  const GetUnreadNotificationsCount(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, int>> call() => _repository.getUnreadCount();
}
