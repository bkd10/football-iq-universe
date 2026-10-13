import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/notifications_repository.dart';

class MarkNotificationRead {
  const MarkNotificationRead(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, void>> call(String notificationId) =>
      _repository.markAsRead(notificationId);
}
