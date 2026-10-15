import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/profile.dart';
import '../repositories/auth_repository.dart';

/// Inscription d'un nouveau joueur. Le bonus de bienvenue (100 Ballons) et
/// la création de la ligne `profiles` sont gérés côté serveur par le
/// trigger `handle_new_user` — voir
/// `supabase/migrations/20260101000002_triggers.sql`.
class SignUp {
  const SignUp(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Profile>> call({
    required String email,
    required String password,
    required String username,
    String? country,
    String? position,
    String? preferredFoot,
    DateTime? birthDate,
    bool asScout = false,
    bool asBrand = false,
  }) {
    return _repository.signUp(
      email: email,
      password: password,
      username: username,
      country: country,
      position: position,
      preferredFoot: preferredFoot,
      birthDate: birthDate,
      asScout: asScout,
      asBrand: asBrand,
    );
  }
}
