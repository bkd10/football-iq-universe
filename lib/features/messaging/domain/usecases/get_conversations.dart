import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/conversation.dart';
import '../repositories/messaging_repository.dart';

class GetConversations {
  const GetConversations(this._repository);

  final MessagingRepository _repository;

  Future<Either<Failure, List<Conversation>>> call() {
    return _repository.getConversations();
  }
}
