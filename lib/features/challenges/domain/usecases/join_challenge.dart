import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/challenge_repository.dart';

class JoinChallenge {
  const JoinChallenge(this._repository);

  final ChallengeRepository _repository;

  Future<Either<Failure, void>> call({
    required String challengeId,
    required String videoId,
  }) {
    return _repository.joinChallenge(challengeId: challengeId, videoId: videoId);
  }
}
