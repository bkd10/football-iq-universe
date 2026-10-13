import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/notifications_repository.dart';

class MarkAllNotificationsRead {
  const MarkAllNotificationsRead(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, void>> call() => _repository.markAllAsRead();
}
