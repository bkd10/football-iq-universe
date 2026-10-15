import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/challenge.dart';
import '../repositories/challenge_repository.dart';

class CreateChallenge {
  const CreateChallenge(this._repository);

  final ChallengeRepository _repository;

  Future<Either<Failure, Challenge>> call({
    required String title,
    required String description,
    required String type,
    String? category,
    required DateTime endDate,
    int prizePool = 0,
    int? maxParticipants,
    String? recordUnit,
    String? prizeDescription,
    DateTime? startDate,
  }) {
    return _repository.createChallenge(
      title: title,
      description: description,
      type: type,
      category: category,
      endDate: endDate,
      prizePool: prizePool,
      maxParticipants: maxParticipants,
      recordUnit: recordUnit,
      prizeDescription: prizeDescription,
      startDate: startDate,
    );
  }
}
