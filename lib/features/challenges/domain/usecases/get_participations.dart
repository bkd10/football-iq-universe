import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/challenge_participation.dart';
import '../repositories/challenge_repository.dart';

class GetParticipations {
  const GetParticipations(this._repository);

  final ChallengeRepository _repository;

  Future<Either<Failure, List<ChallengeParticipation>>> call(
    String challengeId,
  ) {
    return _repository.getParticipations(challengeId);
  }
}
