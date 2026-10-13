import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation.freezed.dart';

/// Une conversation joueur ↔ recruteur — voir PARTIE 8.4/8.5. Le contact
/// avec un mineur n'est jamais direct : [status] reste
/// `pending_guardian_approval` tant qu'un tuteur n'a pas validé via le lien
/// à usage unique ([guardianApprovalToken]), et aucun message ne peut être
/// envoyé avant (voir `send_message` côté serveur).
@freezed
class Conversation with _$Conversation {
  const factory Conversation({
    required String id,
    required String playerId,
    required String scoutId,
    required String status,
    required DateTime requestedAt,
    DateTime? approvedAt,
    DateTime? lastMessageAt,
    String? guardianApprovalToken,
    String? otherUserId,
    String? otherUsername,
    String? otherDisplayName,
    String? otherAvatarUrl,
    @Default(false) bool hasUnread,
  }) = _Conversation;

  const Conversation._();

  bool get isActive => status == 'active';
  bool get isPendingGuardianApproval => status == 'pending_guardian_approval';
  bool get isDeclined => status == 'declined';
}
