import 'package:freezed_annotation/freezed_annotation.dart';

part 'content_report.freezed.dart';

/// Un signalement de contenu (vidéo/commentaire/profil) — voir
/// `content_reports` (`20260101000015_hardening.sql`). [status] : pending,
/// reviewed, actioned, dismissed. Traité depuis `AdminModerationScreen`,
/// réservé à `profiles.role = 'admin'`.
@freezed
class ContentReport with _$ContentReport {
  const factory ContentReport({
    required String id,
    required String targetType,
    required String targetId,
    required String reason,
    required String status,
    required DateTime createdAt,
    String? reporterUsername,
    String? resolutionNote,
  }) = _ContentReport;

  const ContentReport._();

  bool get isPending => status == 'pending';
}
