import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/exceptions.dart' as core_errors;
import '../models/profile_model.dart';

/// Accès direct à Supabase Auth + table `profiles`. Toute erreur réseau ou
/// applicative est convertie en [Exception] typée (`core/errors/exceptions`)
/// pour que le repository puisse la traduire en `Failure`.
///
/// Le SDK Supabase expose lui-même une classe `AuthException` : le préfixe
/// `supa.` évite toute ambiguïté avec la nôtre.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final supa.SupabaseClient _client;

  Stream<ProfileModel?> watchAuthState() {
    return _client.auth.onAuthStateChange.asyncMap((state) async {
      final user = state.session?.user;
      if (user == null) return null;
      return _fetchProfile(user.id);
    });
  }

  Future<ProfileModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const core_errors.AuthException('Connexion impossible.');
      }
      return _fetchProfile(user.id);
    } on core_errors.AuthException {
      rethrow;
    } on supa.AuthException catch (e) {
      if (e.code == 'email_not_confirmed' ||
          e.message.toLowerCase().contains('email not confirmed') ||
          e.message.toLowerCase().contains('email link is invalid')) {
        throw const core_errors.EmailNotConfirmedException(
          'Confirme ton e-mail avant de te connecter — vérifie ta boîte de réception.',
        );
      }
      throw core_errors.AuthException(e.message);
    } catch (e) {
      throw core_errors.ServerException(e.toString());
    }
  }

  Future<ProfileModel> signUp({
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
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        // Sur mobile, `emailRedirectTo` reste `null` : sans deep link natif
        // configuré (custom URL scheme), Supabase retombe sur la Site URL
        // par défaut du projet — le lien confirme quand même le compte,
        // seul le retour automatique dans l'app ne fonctionne pas encore
        // (voir HANDOFF.md, à faire une fois les cibles mobiles activées).
        emailRedirectTo:
            kIsWeb ? '${Uri.base.origin}${RouteNames.authCallback}' : null,
        data: {
          'username': username,
          if (asScout) 'role': 'scout',
          if (asBrand) 'role': 'brand',
          if (country != null) 'country': country,
          if (position != null) 'position': position,
          if (preferredFoot != null) 'preferred_foot': preferredFoot,
          if (birthDate != null)
            'birth_date': birthDate.toIso8601String().split('T').first,
        },
      );
      final user = response.user;
      if (user == null) {
        throw const core_errors.AuthException('Inscription impossible.');
      }
      // Le trigger `handle_new_user` crée la ligne `profiles` de manière
      // asynchrone à l'insertion dans `auth.users` ; un court instant peut
      // être nécessaire avant qu'elle soit lisible.
      return _fetchProfile(user.id, retryOnMissing: true);
    } on core_errors.AuthException {
      rethrow;
    } on supa.AuthException catch (e) {
      throw core_errors.AuthException(e.message);
    } catch (e) {
      throw core_errors.ServerException(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw core_errors.ServerException(e.toString());
    }
  }

  /// Supprime réellement le compte (voir
  /// `20260101000020_account_deletion.sql`) : la RPC supprime la ligne
  /// `auth.users`, qui cascade vers `profiles` et tout ce qui en dépend.
  /// Aucun retour en arrière possible — pas de simple flag "supprimé".
  Future<void> deleteAccount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const core_errors.AuthException('Aucune session active.');
    }
    try {
      // Supabase interdit de supprimer des fichiers directement en SQL : on
      // vide d'abord les dossiers `<bucket>/<userId>/` via l'API Storage
      // (autorisé par les policies de storage.objects), puis on supprime le
      // compte. Sans ça, vidéos et avatars resteraient accessibles par URL.
      for (final bucket in const ['videos', 'thumbnails', 'avatars']) {
        final files = await _client.storage.from(bucket).list(path: userId);
        if (files.isEmpty) continue;
        await _client.storage
            .from(bucket)
            .remove(files.map((f) => '$userId/${f.name}').toList());
      }
      await _client.rpc<void>('delete_my_account');
      await _client.auth.signOut();
    } on supa.PostgrestException catch (e) {
      throw core_errors.ServerException(e.message);
    } catch (e) {
      throw core_errors.ServerException(e.toString());
    }
  }

  /// Renvoie l'e-mail de confirmation d'inscription — écran "Confirme ton
  /// e-mail" (voir `ConfirmEmailScreen`), pour l'utilisateur qui n'a pas
  /// reçu ou a perdu le premier envoi.
  Future<void> resendConfirmationEmail(String email) async {
    try {
      await _client.auth.resend(type: supa.OtpType.signup, email: email);
    } on supa.AuthException catch (e) {
      throw core_errors.AuthException(e.message);
    } catch (e) {
      throw core_errors.ServerException(e.toString());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on supa.AuthException catch (e) {
      throw core_errors.AuthException(e.message);
    } catch (e) {
      throw core_errors.ServerException(e.toString());
    }
  }

  Future<ProfileModel> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const core_errors.AuthException('Aucune session active.');
    }
    return _fetchProfile(user.id);
  }

  Future<ProfileModel?> getProfileById(String userId) async {
    try {
      return await _readProfile(userId);
    } catch (e) {
      throw core_errors.ServerException(e.toString());
    }
  }

  Future<ProfileModel> updateProfile(Map<String, dynamic> changes) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const core_errors.AuthException('Aucune session active.');
    }
    try {
      await _client.from('profiles').update(changes).eq('id', user.id);
      return _fetchProfile(user.id);
    } catch (e) {
      throw core_errors.ServerException(e.toString());
    }
  }

  /// Contact d'un tuteur (uniquement pertinent pour un mineur) — stocké dans
  /// `guardian_contacts`, une table à part de `profiles` volontairement (voir
  /// `20260101000013_scouting_messaging.sql` : `profiles` est publiquement
  /// lisible, cette table ne l'est jamais).
  Future<Map<String, dynamic>?> getMyGuardianContact() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const core_errors.AuthException('Aucune session active.');
    }
    try {
      return await _client
          .from('guardian_contacts')
          .select()
          .eq('player_id', user.id)
          .maybeSingle();
    } catch (e) {
      throw core_errors.ServerException(e.toString());
    }
  }

  Future<void> updateMyGuardianContact({
    required String guardianName,
    required String guardianEmail,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const core_errors.AuthException('Aucune session active.');
    }
    try {
      await _client.from('guardian_contacts').upsert({
        'player_id': user.id,
        'guardian_name': guardianName,
        'guardian_email': guardianEmail,
      });
    } catch (e) {
      throw core_errors.ServerException(e.toString());
    }
  }

  /// Profil complet (date de naissance comprise) de l'utilisateur connecté,
  /// via la RPC `get_my_profile` — seul chemin qui renvoie `birth_date`.
  Future<ProfileModel?> _readOwnProfile() async {
    final rows = await _client.rpc<List<dynamic>>('get_my_profile');
    if (rows.isEmpty) return null;
    return ProfileModel.fromJson(rows.first as Map<String, dynamic>);
  }

  Future<ProfileModel?> _readProfile(String userId) async {
    // Juste après une inscription avec confirmation d'e-mail, il n'y a pas
    // encore de session : on lit alors les colonnes publiques seulement.
    if (userId == _client.auth.currentUser?.id) {
      return _readOwnProfile();
    }
    final json = await _client
        .from('profiles')
        .select(kPublicProfileColumns)
        .eq('id', userId)
        .maybeSingle();
    return json != null ? ProfileModel.fromJson(json) : null;
  }

  Future<ProfileModel> _fetchProfile(
    String userId, {
    bool retryOnMissing = false,
  }) async {
    final profile = await _readProfile(userId);

    if (profile == null) {
      if (retryOnMissing) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        final retried = await _readProfile(userId);
        if (retried != null) return retried;
      }
      throw const core_errors.ServerException('Profil introuvable.');
    }

    return profile;
  }
}
