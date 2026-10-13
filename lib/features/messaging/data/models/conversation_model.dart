import '../../domain/entities/conversation.dart';

/// Contrairement aux autres modèles du projet, [fromRow] n'est pas un
/// simple `fromJson` généré : la ligne embarque à la fois le profil du
/// joueur et celui du recruteur (`player:profiles!player_id(...)`,
/// `scout:profiles!scout_id(...)`), et seul l'appelant sait qui, du joueur
/// ou du recruteur, correspond à l'utilisateur courant — donc lequel des
/// deux embeds représente "l'autre partie" à afficher.
class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.playerId,
    required this.scoutId,
    required this.status,
    required this.requestedAt,
    this.approvedAt,
    this.lastMessageAt,
    this.guardianApprovalToken,
    this.otherUserId,
    this.otherUsername,
    this.otherDisplayName,
    this.otherAvatarUrl,
    this.hasUnread = false,
  });

  factory ConversationModel.fromRow(
    Map<String, dynamic> row, {
    required String viewerId,
    bool hasUnread = false,
  }) {
    final playerId = row['player_id'] as String;
    final scoutId = row['scout_id'] as String;
    final isViewerPlayer = viewerId == playerId;
    final otherEmbed = (isViewerPlayer ? row['scout'] : row['player'])
        as Map<String, dynamic>?;

    return ConversationModel(
      id: row['id'] as String,
      playerId: playerId,
      scoutId: scoutId,
      status: row['status'] as String,
      requestedAt: DateTime.parse(row['requested_at'] as String),
      approvedAt: row['approved_at'] != null
          ? DateTime.parse(row['approved_at'] as String)
          : null,
      lastMessageAt: row['last_message_at'] != null
          ? DateTime.parse(row['last_message_at'] as String)
          : null,
      guardianApprovalToken: row['guardian_approval_token'] as String?,
      otherUserId: isViewerPlayer ? scoutId : playerId,
      otherUsername: otherEmbed?['username'] as String?,
      otherDisplayName: otherEmbed?['display_name'] as String?,
      otherAvatarUrl: otherEmbed?['avatar_url'] as String?,
      hasUnread: hasUnread,
    );
  }

  final String id;
  final String playerId;
  final String scoutId;
  final String status;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? lastMessageAt;
  final String? guardianApprovalToken;
  final String? otherUserId;
  final String? otherUsername;
  final String? otherDisplayName;
  final String? otherAvatarUrl;
  final bool hasUnread;

  Conversation toEntity() {
    return Conversation(
      id: id,
      playerId: playerId,
      scoutId: scoutId,
      status: status,
      requestedAt: requestedAt,
      approvedAt: approvedAt,
      lastMessageAt: lastMessageAt,
      guardianApprovalToken: guardianApprovalToken,
      otherUserId: otherUserId,
      otherUsername: otherUsername,
      otherDisplayName: otherDisplayName,
      otherAvatarUrl: otherAvatarUrl,
      hasUnread: hasUnread,
    );
  }
}
