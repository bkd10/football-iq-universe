import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/challenge_repository.dart';

class VoteForParticipant {
  const VoteForParticipant(this._repository);

  final ChallengeRepository _repository;

  Future<Either<Failure, void>> call({
    required String challengeId,
    required String participantUserId,
  }) {
    return _repository.voteForParticipant(
      challengeId: challengeId,
      participantUserId: participantUserId,
    );
  }
}
