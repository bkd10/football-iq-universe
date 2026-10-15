import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/challenge_participation.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../datasources/challenge_remote_datasource.dart';

class ChallengeRepositoryImpl implements ChallengeRepository {
  const ChallengeRepositoryImpl(this._remoteDataSource);

  final ChallengeRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<Challenge>>> getChallenges({String? type}) async {
    try {
      final models = await _remoteDataSource.getChallenges(type: type);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Challenge?>> getChallengeById(String challengeId) async {
    try {
      final model = await _remoteDataSource.getChallengeById(challengeId);
      return Right(model?.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<ChallengeParticipation>>> getParticipations(
    String challengeId,
  ) async {
    try {
      final models = await _remoteDataSource.getParticipations(challengeId);
      final myVotes = await _remoteDataSource.getMyVotes(challengeId);
      return Right(
        models
            .map((m) => m.toEntity(hasVoted: myVotes.contains(m.userId)))
            .toList(),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> joinChallenge({
    required String challengeId,
    required String videoId,
  }) async {
    try {
      await _remoteDataSource.joinChallenge(
        challengeId: challengeId,
        videoId: videoId,
      );
      return const Right(null);
    } on InsufficientCoinsException catch (e) {
      return Left(InsufficientCoinsFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> voteForParticipant({
    required String challengeId,
    required String participantUserId,
  }) async {
    try {
      await _remoteDataSource.voteForParticipant(
        challengeId: challengeId,
        participantUserId: participantUserId,
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
  Future<Either<Failure, Challenge>> createChallenge({
    required String title,
    required String description,
    required String type,
    String? category,
    required DateTime endDate,
    int prizePool = 0,
    int? maxParticipants,
    String? recordUnit,
    String? prizeDescription,
    DateTime? startDate,
  }) async {
    try {
      final model = await _remoteDataSource.createChallenge(
        title: title,
        description: description,
        type: type,
        category: category,
        endDate: endDate,
        prizePool: prizePool,
        maxParticipants: maxParticipants,
        recordUnit: recordUnit,
        prizeDescription: prizeDescription,
        startDate: startDate,
      );
      return Right(model.toEntity());
    } on InsufficientCoinsException catch (e) {
      return Left(InsufficientCoinsFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Challenge>> createBattle({
    required String title,
    required String rules,
    required int stake,
    required String videoId,
    required DateTime endDate,
    String? opponentUsername,
  }) async {
    try {
      final model = await _remoteDataSource.createBattle(
        title: title,
        rules: rules,
        stake: stake,
        videoId: videoId,
        endDate: endDate,
        opponentUsername: opponentUsername,
      );
      return Right(model.toEntity());
    } on InsufficientCoinsException catch (e) {
      return Left(InsufficientCoinsFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
