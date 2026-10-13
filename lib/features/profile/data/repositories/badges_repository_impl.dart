import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_badge.dart';
import '../../domain/repositories/badges_repository.dart';
import '../datasources/badges_remote_datasource.dart';

class BadgesRepositoryImpl implements BadgesRepository {
  const BadgesRepositoryImpl(this._remoteDataSource);

  final BadgesRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<UserBadge>>> getUserBadges(String userId) async {
    try {
      final models = await _remoteDataSource.getUserBadges(userId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
