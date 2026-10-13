import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/economy_repository.dart';

class AwardCoins {
  const AwardCoins(this._repository);

  final EconomyRepository _repository;

  Future<Either<Failure, int>> call({
    required String reason,
    String? referenceId,
  }) {
    return _repository.awardCoins(reason: reason, referenceId: referenceId);
  }
}
