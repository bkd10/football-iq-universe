import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/messaging_repository.dart';

class GetGuardianApprovalToken {
  const GetGuardianApprovalToken(this._repository);

  final MessagingRepository _repository;

  Future<Either<Failure, String>> call(String conversationId) {
    return _repository.getGuardianApprovalToken(conversationId);
  }
}
