import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';

/// Un message dans une conversation joueur ↔ recruteur (PARTIE 8.4/8.5).
@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    required String conversationId,
    required String senderId,
    required String body,
    required DateTime createdAt,
    DateTime? readAt,
  }) = _Message;
}
