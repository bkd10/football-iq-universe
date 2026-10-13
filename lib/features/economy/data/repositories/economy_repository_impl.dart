import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/coin_transaction.dart';
import '../../domain/repositories/economy_repository.dart';
import '../datasources/economy_remote_datasource.dart';

class EconomyRepositoryImpl implements EconomyRepository {
  const EconomyRepositoryImpl(this._remoteDataSource);

  final EconomyRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, int>> awardCoins({
    required String reason,
    String? referenceId,
  }) async {
    try {
      final balance = await _remoteDataSource.awardCoins(
        reason: reason,
        referenceId: referenceId,
      );
      return Right(balance);
    } on DailyLimitException catch (e) {
      return Left(DailyLimitReachedFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, int>> spendCoins({
    required String reason,
    required int amount,
    String? referenceId,
  }) async {
    try {
      final balance = await _remoteDataSource.spendCoins(
        reason: reason,
        amount: amount,
        referenceId: referenceId,
      );
      return Right(balance);
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
  Future<Either<Failure, List<CoinTransaction>>> getTransactions({
    int limit = 30,
  }) async {
    try {
      final models = await _remoteDataSource.getTransactions(limit: limit);
      return Right(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
