import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/scout_subscription.dart';
import '../repositories/scouting_repository.dart';

class GetMyScoutSubscription {
  const GetMyScoutSubscription(this._repository);

  final ScoutingRepository _repository;

  Future<Either<Failure, ScoutSubscription?>> call() {
    return _repository.getMySubscription();
  }
}
