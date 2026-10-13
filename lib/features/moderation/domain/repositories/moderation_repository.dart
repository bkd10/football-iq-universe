import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/content_report.dart';

abstract class ModerationRepository {
  Future<Either<Failure, void>> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
  });

  /// Réservé aux admins — voir `content_reports` RLS.
  Future<Either<Failure, List<ContentReport>>> getPendingReports();

  Future<Either<Failure, void>> resolveReport({
    required String reportId,
    required String status,
    String? resolutionNote,
  });
}
