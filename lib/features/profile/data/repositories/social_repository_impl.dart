import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/social_repository.dart';
import '../datasources/social_remote_datasource.dart';

class SocialRepositoryImpl implements SocialRepository {
  const SocialRepositoryImpl(this._remoteDataSource);

  final SocialRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, bool>> isFollowing(String userId) async {
    try {
      return Right(await _remoteDataSource.isFollowing(userId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> toggleFollow({
    required String userId,
    required bool currentlyFollowing,
  }) async {
    try {
      await _remoteDataSource.toggleFollow(
        userId: userId,
        currentlyFollowing: currentlyFollowing,
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
