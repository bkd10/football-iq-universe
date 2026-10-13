import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/messaging_repository.dart';

class RequestScoutContact {
  const RequestScoutContact(this._repository);

  final MessagingRepository _repository;

  Future<Either<Failure, String>> call(String playerId) {
    return _repository.requestScoutContact(playerId);
  }
}
