import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/profile.dart';
import '../repositories/auth_repository.dart';

/// Un usecase = une responsabilité. Encapsule la connexion par email/mot de
/// passe pour ne pas exposer le repository directement à la presentation.
class SignIn {
  const SignIn(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Profile>> call({
    required String email,
    required String password,
  }) {
    return _repository.signIn(email: email, password: password);
  }
}
