import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/missions_repository.dart';

class IncrementVideosWatched {
  const IncrementVideosWatched(this._repository);

  final MissionsRepository _repository;

  Future<Either<Failure, void>> call() => _repository.incrementVideosWatched();
}
