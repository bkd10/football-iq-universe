import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/messaging_repository.dart';

class MarkConversationRead {
  const MarkConversationRead(this._repository);

  final MessagingRepository _repository;

  Future<Either<Failure, void>> call(String conversationId) {
    return _repository.markConversationRead(conversationId);
  }
}
