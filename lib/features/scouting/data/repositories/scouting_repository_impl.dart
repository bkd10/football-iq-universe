import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/scout_player_result.dart';
import '../../domain/entities/scout_subscription.dart';
import '../../domain/repositories/scouting_repository.dart';
import '../datasources/scouting_remote_datasource.dart';

class ScoutingRepositoryImpl implements ScoutingRepository {
  const ScoutingRepositoryImpl(this._remoteDataSource);

  final ScoutingRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<ScoutPlayerResult>>> searchPlayers({
    String? query,
    String? position,
    String? country,
  }) async {
    try {
      final models = await _remoteDataSource.searchPlayers(
        query: query,
        position: position,
        country: country,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> startTrial() async {
    try {
      await _remoteDataSource.startTrial();
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
  Future<Either<Failure, ScoutSubscription?>> getMySubscription() async {
    try {
      final json = await _remoteDataSource.getMySubscription();
      if (json == null) return const Right(null);
      return Right(
        ScoutSubscription(
          plan: json['plan'] as String,
          status: json['status'] as String,
          expiresAt: json['expires_at'] != null
              ? DateTime.parse(json['expires_at'] as String)
              : null,
        ),
      );
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
