import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/economy_repository.dart';

class SpendCoins {
  const SpendCoins(this._repository);

  final EconomyRepository _repository;

  Future<Either<Failure, int>> call({
    required String reason,
    required int amount,
    String? referenceId,
  }) {
    return _repository.spendCoins(
      reason: reason,
      amount: amount,
      referenceId: referenceId,
    );
  }
}
