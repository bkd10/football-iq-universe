import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/ranking_entry.dart';

abstract class RankingRepository {
  /// Classement pour une catégorie (voir `RankingCategory`), filtré par
  /// pays/ville si renseignés (région "Mondial" = aucun filtre).
  Future<Either<Failure, List<RankingEntry>>> getRankings({
    required String category,
    String? country,
    String? city,
    int limit = 50,
  });
}
