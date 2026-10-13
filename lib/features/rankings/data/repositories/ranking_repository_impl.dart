import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/ranking_entry.dart';
import '../../domain/repositories/ranking_repository.dart';
import '../datasources/ranking_remote_datasource.dart';

class RankingRepositoryImpl implements RankingRepository {
  const RankingRepositoryImpl(this._remoteDataSource);

  final RankingRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<RankingEntry>>> getRankings({
    required String category,
    String? country,
    String? city,
    int limit = 50,
  }) async {
    try {
      final models = await _remoteDataSource.getRankings(
        category: category,
        country: country,
        city: city,
        limit: limit,
      );
      final entries = <RankingEntry>[
        for (var i = 0; i < models.length; i++) models[i].toEntity(i + 1),
      ];
      return Right(entries);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
