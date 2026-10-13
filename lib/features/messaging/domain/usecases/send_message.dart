import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/messaging_repository.dart';

class SendMessage {
  const SendMessage(this._repository);

  final MessagingRepository _repository;

  Future<Either<Failure, void>> call({
    required String conversationId,
    required String body,
  }) {
    return _repository.sendMessage(conversationId: conversationId, body: body);
  }
}
