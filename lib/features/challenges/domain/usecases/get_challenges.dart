import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/challenge.dart';
import '../repositories/challenge_repository.dart';

class GetChallenges {
  const GetChallenges(this._repository);

  final ChallengeRepository _repository;

  Future<Either<Failure, List<Challenge>>> call({String? type}) {
    return _repository.getChallenges(type: type);
  }
}
