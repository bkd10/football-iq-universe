import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/scouting_repository.dart';

class StartScoutTrial {
  const StartScoutTrial(this._repository);

  final ScoutingRepository _repository;

  Future<Either<Failure, void>> call() {
    return _repository.startTrial();
  }
}
