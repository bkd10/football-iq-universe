import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/messaging_repository.dart';

class ApproveGuardianContact {
  const ApproveGuardianContact(this._repository);

  final MessagingRepository _repository;

  Future<Either<Failure, void>> call(String token) {
    return _repository.approveGuardianContact(token);
  }
}
