import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/daily_mission.dart';
import '../../domain/repositories/missions_repository.dart';
import '../datasources/missions_remote_datasource.dart';

class MissionsRepositoryImpl implements MissionsRepository {
  const MissionsRepositoryImpl(this._remoteDataSource);

  final MissionsRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, DailyMission>> getTodayMission() async {
    try {
      final model = await _remoteDataSource.getTodayMission();
      return Right(model.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> incrementVideosWatched() async {
    try {
      await _remoteDataSource.incrementVideosWatched();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
