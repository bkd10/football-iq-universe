import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implémentation concrète de [AuthRepository] : traduit les [Exception]s
/// levées par [AuthRemoteDataSource] en [Failure]s consommables par la
/// couche presentation, sans jamais laisser fuiter de détail Supabase.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<Profile?> watchAuthState() {
    return _remoteDataSource.watchAuthState().map((model) => model?.toEntity());
  }

  @override
  Future<Either<Failure, Profile>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final model = await _remoteDataSource.signIn(
        email: email,
        password: password,
      );
      return Right(model.toEntity());
    } on EmailNotConfirmedException catch (e) {
      return Left(EmailNotConfirmedFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> resendConfirmationEmail(String email) async {
    try {
      await _remoteDataSource.resendConfirmationEmail(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Profile>> signUp({
    required String email,
    required String password,
    required String username,
    String? country,
    String? position,
    String? preferredFoot,
    DateTime? birthDate,
    bool asScout = false,
    bool asBrand = false,
  }) async {
    try {
      final model = await _remoteDataSource.signUp(
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
      return Right(model.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await _remoteDataSource.deleteAccount();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await _remoteDataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Profile>> getCurrentProfile() async {
    try {
      final model = await _remoteDataSource.getCurrentProfile();
      return Right(model.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Profile?>> getProfileById(String userId) async {
    try {
      final model = await _remoteDataSource.getProfileById(userId);
      return Right(model?.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Profile>> updateProfile({
    String? displayName,
    String? bio,
    String? country,
    String? city,
    String? position,
    String? preferredFoot,
    int? heightCm,
    int? weightKg,
  }) async {
    try {
      final changes = <String, dynamic>{
        if (displayName != null) 'display_name': displayName,
        if (bio != null) 'bio': bio,
        if (country != null) 'country': country,
        if (city != null) 'city': city,
        if (position != null) 'position': position,
        if (preferredFoot != null) 'preferred_foot': preferredFoot,
        if (heightCm != null) 'height_cm': heightCm,
        if (weightKg != null) 'weight_kg': weightKg,
      };
      final model = await _remoteDataSource.updateProfile(changes);
      return Right(model.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, ({String? guardianName, String guardianEmail})?>>
      getMyGuardianContact() async {
    try {
      final json = await _remoteDataSource.getMyGuardianContact();
      if (json == null) return const Right(null);
      final contact = (
        guardianName: json['guardian_name'] as String?,
        guardianEmail: json['guardian_email'] as String,
      );
      return Right(contact);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateMyGuardianContact({
    required String guardianName,
    required String guardianEmail,
  }) async {
    try {
      await _remoteDataSource.updateMyGuardianContact(
        guardianName: guardianName,
        guardianEmail: guardianEmail,
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
