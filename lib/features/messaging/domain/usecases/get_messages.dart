import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/message.dart';
import '../repositories/messaging_repository.dart';

class GetMessages {
  const GetMessages(this._repository);

  final MessagingRepository _repository;

  Future<Either<Failure, List<Message>>> call(String conversationId) {
    return _repository.getMessages(conversationId);
  }
}
