import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/ranking_entry.dart';
import '../repositories/ranking_repository.dart';

class GetRankings {
  const GetRankings(this._repository);

  final RankingRepository _repository;

  Future<Either<Failure, List<RankingEntry>>> call({
    required String category,
    String? country,
    String? city,
    int limit = 50,
  }) {
    return _repository.getRankings(
      category: category,
      country: country,
      city: city,
      limit: limit,
    );
  }
}
