import '../../domain/entities/content_report.dart';

class ContentReportModel {
  const ContentReportModel({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reporterUsername,
    this.resolutionNote,
  });

  factory ContentReportModel.fromRow(Map<String, dynamic> row) {
    final reporter = row['reporter'] as Map<String, dynamic>?;
    return ContentReportModel(
      id: row['id'] as String,
      targetType: row['target_type'] as String,
      targetId: row['target_id'] as String,
      reason: row['reason'] as String,
      status: row['status'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      reporterUsername: reporter?['username'] as String?,
      resolutionNote: row['resolution_note'] as String?,
    );
  }

  final String id;
  final String targetType;
  final String targetId;
  final String reason;
  final String status;
  final DateTime createdAt;
  final String? reporterUsername;
  final String? resolutionNote;

  ContentReport toEntity() {
    return ContentReport(
      id: id,
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      status: status,
      createdAt: createdAt,
      reporterUsername: reporterUsername,
      resolutionNote: resolutionNote,
    );
  }
}
