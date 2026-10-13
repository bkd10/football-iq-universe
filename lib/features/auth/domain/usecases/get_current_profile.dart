import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/profile.dart';
import '../repositories/auth_repository.dart';

class GetCurrentProfile {
  const GetCurrentProfile(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Profile>> call() => _repository.getCurrentProfile();
}
