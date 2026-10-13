import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/scout_player_result.dart';
import '../repositories/scouting_repository.dart';

class SearchPlayers {
  const SearchPlayers(this._repository);

  final ScoutingRepository _repository;

  Future<Either<Failure, List<ScoutPlayerResult>>> call({
    String? query,
    String? position,
    String? country,
  }) {
    return _repository.searchPlayers(query: query, position: position, country: country);
  }
}
