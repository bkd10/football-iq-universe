/// Modèles du panneau administrateur — lus depuis les RPC `admin_*`.
class AdminStats {
  const AdminStats({
    required this.playersTotal,
    required this.playersToday,
    required this.players7d,
    required this.videosTotal,
    required this.videosToday,
    required this.challengesActive,
    required this.reportsPending,
    required this.bannedTotal,
  });

  factory AdminStats.fromRow(Map<String, dynamic> row) {
    int n(String key) => (row[key] as num?)?.toInt() ?? 0;
    return AdminStats(
      playersTotal: n('players_total'),
      playersToday: n('players_today'),
      players7d: n('players_7d'),
      videosTotal: n('videos_total'),
      videosToday: n('videos_today'),
      challengesActive: n('challenges_active'),
      reportsPending: n('reports_pending'),
      bannedTotal: n('banned_total'),
    );
  }

  final int playersTotal;
  final int playersToday;
  final int players7d;
  final int videosTotal;
  final int videosToday;
  final int challengesActive;
  final int reportsPending;
  final int bannedTotal;
}

/// Un contenu signalé (tous ses signalements en attente regroupés).
class AdminReport {
  const AdminReport({
    required this.reportId,
    required this.targetType,
    required this.targetId,
    required this.reasons,
    required this.reportsCount,
    required this.createdAt,
    this.reporterUsername,
    this.authorId,
    this.authorUsername,
    this.previewText,
    this.videoUrl,
    this.thumbnailUrl,
    this.targetStatus,
    this.details,
    this.status = 'pending',
    this.resolvedAt,
    this.resolvedByUsername,
    this.resolutionNote,
    this.minorInvolved = false,
  });

  factory AdminReport.fromRow(Map<String, dynamic> row) {
    return AdminReport(
      reportId: row['report_id'] as String,
      targetType: row['target_type'] as String,
      targetId: row['target_id'] as String,
      reasons: ((row['reasons'] as List<dynamic>?) ?? [row['reason']]).whereType<String>().toList(),
      reportsCount: (row['reports_count'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      reporterUsername: row['reporter_username'] as String?,
      authorId: row['author_id'] as String?,
      authorUsername: row['author_username'] as String?,
      previewText: row['preview_text'] as String?,
      videoUrl: row['video_url'] as String?,
      thumbnailUrl: row['thumbnail_url'] as String?,
      targetStatus: row['target_status'] as String?,
      details: row['details'] as String?,
      status: row['status'] as String? ?? 'pending',
      resolvedAt: DateTime.tryParse(row['resolved_at'] as String? ?? '')?.toLocal(),
      resolvedByUsername: row['resolved_by_username'] as String?,
      resolutionNote: row['resolution_note'] as String?,
      minorInvolved: row['minor_involved'] as bool? ?? false,
    );
  }

  final String reportId;
  final String targetType;
  final String targetId;
  final List<String> reasons;
  final int reportsCount;
  final DateTime createdAt;
  final String? reporterUsername;
  final String? authorId;
  final String? authorUsername;
  final String? previewText;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? targetStatus;

  /// Précisions écrites par le signaleur.
  final String? details;

  /// pending, actioned (retiré), dismissed (gardé).
  final String status;
  final DateTime? resolvedAt;
  final String? resolvedByUsername;
  final String? resolutionNote;

  /// L'auteur ou un signaleur a moins de 18 ans : à traiter en premier.
  final bool minorInvolved;
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.username,
    required this.role,
    required this.createdAt,
    required this.videosCount,
    required this.followersCount,
    required this.isBanned,
    required this.reportsCount,
    this.displayName,
    this.avatarUrl,
    this.email,
    this.banReason,
  });

  factory AdminUser.fromRow(Map<String, dynamic> row) {
    return AdminUser(
      id: row['id'] as String,
      username: row['username'] as String,
      displayName: row['display_name'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      email: row['email'] as String?,
      role: row['role'] as String? ?? 'player',
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      videosCount: (row['videos_count'] as num?)?.toInt() ?? 0,
      followersCount: (row['followers_count'] as num?)?.toInt() ?? 0,
      isBanned: row['is_banned'] as bool? ?? false,
      banReason: row['ban_reason'] as String?,
      reportsCount: (row['reports_count'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? email;
  final String role;
  final DateTime createdAt;
  final int videosCount;
  final int followersCount;
  final bool isBanned;
  final String? banReason;
  final int reportsCount;
}
