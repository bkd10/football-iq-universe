import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/coin_transaction.dart';
import '../repositories/economy_repository.dart';

class GetTransactions {
  const GetTransactions(this._repository);

  final EconomyRepository _repository;

  Future<Either<Failure, List<CoinTransaction>>> call({int limit = 30}) {
    return _repository.getTransactions(limit: limit);
  }
}
