import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/challenge.dart';
import '../repositories/challenge_repository.dart';

class GetChallengeById {
  const GetChallengeById(this._repository);

  final ChallengeRepository _repository;

  Future<Either<Failure, Challenge?>> call(String challengeId) {
    return _repository.getChallengeById(challengeId);
  }
}
