import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/profile.dart';
import '../repositories/auth_repository.dart';

class UpdateProfile {
  const UpdateProfile(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Profile>> call({
    String? displayName,
    String? bio,
    String? country,
    String? city,
    String? position,
    String? preferredFoot,
    int? heightCm,
    int? weightKg,
  }) {
    return _repository.updateProfile(
      displayName: displayName,
      bio: bio,
      country: country,
      city: city,
      position: position,
      preferredFoot: preferredFoot,
      heightCm: heightCm,
      weightKg: weightKg,
    );
  }
}
