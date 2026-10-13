import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/messaging_repository.dart';

class DeclineGuardianContact {
  const DeclineGuardianContact(this._repository);

  final MessagingRepository _repository;

  Future<Either<Failure, void>> call(String token) {
    return _repository.declineGuardianContact(token);
  }
}
