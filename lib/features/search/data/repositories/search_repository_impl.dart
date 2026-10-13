import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/search_results.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_datasource.dart';

class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl(this._remoteDataSource);

  final SearchRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, SearchResults>> search(String query) async {
    try {
      final players = await _remoteDataSource.searchPlayers(query);
      final moves = await _remoteDataSource.searchMoves(query);
      return Right(
        SearchResults(
          players: players.map((m) => m.toEntity()).toList(),
          moves: moves.map((m) => m.toEntity()).toList(),
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
