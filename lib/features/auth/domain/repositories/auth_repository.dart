import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/profile.dart';

/// Contrat du domaine pour l'authentification. N'a aucune dépendance vers
/// Supabase ou tout autre détail d'implémentation — voir
/// `data/repositories/auth_repository_impl.dart` pour l'implémentation
/// concrète.
abstract class AuthRepository {
  /// Émet le profil courant à chaque changement de session (connexion,
  /// déconnexion, refresh de token), ou `null` si déconnecté.
  Stream<Profile?> watchAuthState();

  Future<Either<Failure, Profile>> signIn({
    required String email,
    required String password,
  });

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
  });

  Future<Either<Failure, void>> signOut();

  /// Supprime réellement le compte et toutes les données qui en dépendent
  /// (voir `20260101000020_account_deletion.sql`). Irréversible.
  Future<Either<Failure, void>> deleteAccount();

  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  /// Renvoie l'e-mail de confirmation d'inscription (écran "Confirme ton
  /// e-mail").
  Future<Either<Failure, void>> resendConfirmationEmail(String email);

  Future<Either<Failure, Profile>> getCurrentProfile();

  /// Football Passport public d'un autre joueur (écran "Other Profile",
  /// PARTIE 9.2, écran 23) — lecture seule, aucune donnée sensible propre
  /// au compte (email...) n'est exposée par [Profile].
  Future<Either<Failure, Profile?>> getProfileById(String userId);

  /// Écran "Edit Profile" (PARTIE 9.2, écran 24). Seules les colonnes
  /// autorisées par le `GRANT UPDATE` de la migration
  /// `protect_profile_columns` sont modifiables ici — `coins`/`stars`/
  /// `level`/`iq_*` restent hors de portée du client.
  Future<Either<Failure, Profile>> updateProfile({
    String? displayName,
    String? bio,
    String? country,
    String? city,
    String? position,
    String? preferredFoot,
    int? heightCm,
    int? weightKg,
  });

  /// Contact d'un tuteur, requis pour qu'un mineur puisse recevoir un
  /// message de recruteur (contact toujours médié, jamais direct — voir
  /// `request_scout_contact`). `null` si rien n'a encore été renseigné.
  Future<Either<Failure, ({String? guardianName, String guardianEmail})?>>
      getMyGuardianContact();

  Future<Either<Failure, void>> updateMyGuardianContact({
    required String guardianName,
    required String guardianEmail,
  });
}
