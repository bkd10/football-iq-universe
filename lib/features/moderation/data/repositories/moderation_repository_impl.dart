import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/content_report.dart';
import '../../domain/repositories/moderation_repository.dart';
import '../datasources/moderation_remote_datasource.dart';

class ModerationRepositoryImpl implements ModerationRepository {
  const ModerationRepositoryImpl(this._remoteDataSource);

  final ModerationRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, void>> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    try {
      await _remoteDataSource.reportContent(
        targetType: targetType,
        targetId: targetId,
        reason: reason,
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<ContentReport>>> getPendingReports() async {
    try {
      final models = await _remoteDataSource.getPendingReports();
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> resolveReport({
    required String reportId,
    required String status,
    String? resolutionNote,
  }) async {
    try {
      await _remoteDataSource.resolveReport(
        reportId: reportId,
        status: status,
        resolutionNote: resolutionNote,
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
