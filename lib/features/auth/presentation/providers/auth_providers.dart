import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_profile.dart';
import '../../domain/usecases/get_profile_by_id.dart';
import '../../domain/usecases/send_password_reset_email.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import '../../domain/usecases/watch_auth_state.dart';

// ---------------------------------------------------------------------------
// Câblage data -> domain (injection manuelle, sans code generation : ces
// providers restent utilisables même avant `dart run build_runner build`).
// ---------------------------------------------------------------------------

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(supabaseClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

final signInUseCaseProvider = Provider(
  (ref) => SignIn(ref.watch(authRepositoryProvider)),
);
final signUpUseCaseProvider = Provider(
  (ref) => SignUp(ref.watch(authRepositoryProvider)),
);
final signOutUseCaseProvider = Provider(
  (ref) => SignOut(ref.watch(authRepositoryProvider)),
);
final sendPasswordResetEmailUseCaseProvider = Provider(
  (ref) => SendPasswordResetEmail(ref.watch(authRepositoryProvider)),
);
final getCurrentProfileUseCaseProvider = Provider(
  (ref) => GetCurrentProfile(ref.watch(authRepositoryProvider)),
);
final getProfileByIdUseCaseProvider = Provider(
  (ref) => GetProfileById(ref.watch(authRepositoryProvider)),
);
final updateProfileUseCaseProvider = Provider(
  (ref) => UpdateProfile(ref.watch(authRepositoryProvider)),
);
final watchAuthStateUseCaseProvider = Provider(
  (ref) => WatchAuthState(ref.watch(authRepositoryProvider)),
);

/// État d'authentification réactif : `null` = déconnecté. Consommé par
/// `AppRouter` pour le redirect et par le splash screen. Ne sert QUE au
/// routage — pour afficher les données du profil (Ballons, Stars...),
/// utiliser [currentProfileProvider], qui reste à jour après une action
/// économie (voir `EconomyController`).
final authStateProvider = StreamProvider<Profile?>((ref) {
  return ref.watch(watchAuthStateUseCaseProvider)();
});

/// Profil courant, invalidable manuellement (`ref.invalidate`) pour forcer
/// un refetch après une mutation qui change `coins`/`stars` côté serveur —
/// contrairement à `authStateProvider`, qui ne réémet qu'aux événements
/// d'authentification (login/logout/refresh de token).
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final baseProfile = ref.watch(authStateProvider).valueOrNull;
  if (baseProfile == null) return null;

  final result = await ref.read(getCurrentProfileUseCaseProvider)();
  return result.fold((_) => baseProfile, (fresh) => fresh);
});

/// Football Passport public d'un autre joueur (écran "Other Profile").
final otherProfileProvider =
    FutureProvider.family<Profile?, String>((ref, userId) async {
  final result = await ref.watch(getProfileByIdUseCaseProvider)(userId);
  return result.fold((failure) => throw failure, (profile) => profile);
});

/// Contact d'un tuteur du joueur courant (`null` si rien renseigné) — jamais
/// exposé pour le profil d'un AUTRE joueur, `guardian_contacts` n'étant
/// lisible que par son propriétaire (voir la RLS de la migration
/// `20260101000013_scouting_messaging.sql`).
final myGuardianContactProvider =
    FutureProvider<({String? guardianName, String guardianEmail})?>((ref) async {
  ref.watch(authStateProvider);
  final result = await ref.watch(authRepositoryProvider).getMyGuardianContact();
  return result.fold((failure) => throw failure, (contact) => contact);
});

/// Résultat d'une inscription : `success` si une session a été créée tout
/// de suite (confirmation d'e-mail désactivée sur ce projet Supabase),
/// `needsEmailConfirmation` si `auth.signUp` a créé le compte mais aucune
/// session (cas normal, projet avec confirmation d'e-mail activée — le
/// plus courant en production), `failure` si l'inscription a été rejetée.
///
/// Distinguer ces trois cas est ce qui évite le bug historique : sans
/// cette distinction, un signUp qui réussit mais nécessite une
/// confirmation d'e-mail était traité comme un succès plein, l'écran
/// affichait "Bienvenue !" puis l'utilisateur restait bloqué sur
/// login/register car `authStateProvider` n'émettait jamais de session.
enum SignUpOutcome { success, needsEmailConfirmation, failure }

/// Contrôleur exposant les actions login/register/logout aux écrans, avec
/// un `AsyncValue` prêt à être affiché (loading / error / data).
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    final result = await ref.read(signInUseCaseProvider)(
      email: email,
      password: password,
    );
    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }

  Future<SignUpOutcome> signUp({
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
    state = const AsyncLoading();
    final result = await ref.read(signUpUseCaseProvider)(
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
    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return SignUpOutcome.failure;
      },
      (_) {
        state = const AsyncData(null);
        // `auth.signUp` a réussi (le compte existe), mais aucune session
        // n'est établie tant que le lien de confirmation n'a pas été
        // cliqué — `currentSession` reste alors `null` juste après l'appel.
        final hasSession =
            ref.read(supabaseClientProvider).auth.currentSession != null;
        return hasSession
            ? SignUpOutcome.success
            : SignUpOutcome.needsEmailConfirmation;
      },
    );
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    state = const AsyncLoading();
    final result = await ref.read(sendPasswordResetEmailUseCaseProvider)(email);
    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    final result = await ref.read(signOutUseCaseProvider)();
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  /// Suppression réelle et irréversible du compte (voir
  /// `20260101000020_account_deletion.sql`). Écran "Réglages" — demande
  /// une confirmation explicite avant d'appeler ceci, il n'y a pas de
  /// retour en arrière possible côté serveur.
  Future<bool> deleteAccount() async {
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).deleteAccount();
    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }

  /// Écran "Edit Profile" — invalide [currentProfileProvider] pour que le
  /// Football Passport et la barre de navigation reflètent immédiatement
  /// les changements.
  Future<bool> updateProfile({
    String? displayName,
    String? bio,
    String? country,
    String? city,
    String? position,
    String? preferredFoot,
    int? heightCm,
    int? weightKg,
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(updateProfileUseCaseProvider)(
      displayName: displayName,
      bio: bio,
      country: country,
      city: city,
      position: position,
      preferredFoot: preferredFoot,
      heightCm: heightCm,
      weightKg: weightKg,
    );
    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        ref.invalidate(currentProfileProvider);
        return true;
      },
    );
  }

  /// Renseigne/à jour le contact d'un tuteur — requis pour qu'un joueur
  /// mineur puisse recevoir un message de recruteur (voir
  /// `request_scout_contact`).
  Future<bool> updateGuardianContact({
    required String guardianName,
    required String guardianEmail,
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).updateMyGuardianContact(
          guardianName: guardianName,
          guardianEmail: guardianEmail,
        );
    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        ref.invalidate(myGuardianContactProvider);
        return true;
      },
    );
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
