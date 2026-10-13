import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/profile.dart';
import '../repositories/auth_repository.dart';

class GetProfileById {
  const GetProfileById(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Profile?>> call(String userId) {
    return _repository.getProfileById(userId);
  }
}
