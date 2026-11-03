import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/errors/failures.dart';

/// `true` quand la session existe mais que le code de double
/// authentification n'a pas encore été saisi (session « aal1 » d'un compte
/// qui a un facteur vérifié). Le serveur refuse alors toute lecture (voir
/// `20260101000028_account_security.sql`).
bool needsMfaCode(supa.SupabaseClient client) {
  if (client.auth.currentSession == null) return false;
  final aal = client.auth.mfa.getAuthenticatorAssuranceLevel();
  return aal.currentLevel == supa.AuthenticatorAssuranceLevels.aal1 &&
      aal.nextLevel == supa.AuthenticatorAssuranceLevels.aal2;
}

/// Facteur TOTP en cours d'ajout : la clé à recopier dans l'appli
/// d'authentification, et le lien `otpauth://` qui l'ouvre directement.
class TotpEnrollment {
  const TotpEnrollment({
    required this.factorId,
    required this.secret,
    required this.uri,
  });

  final String factorId;
  final String secret;
  final String uri;
}

/// Mot de passe et double authentification (appli de codes : Google
/// Authenticator, Microsoft Authenticator, 1Password...). Les erreurs sont
/// rendues sous forme de [Failure] prête à afficher.
class AccountSecurityService {
  const AccountSecurityService(this._client);

  final supa.SupabaseClient _client;

  bool get hasSession => _client.auth.currentSession != null;

  /// Nouveau mot de passe, après le lien « mot de passe oublié » (ou depuis
  /// les Réglages).
  Future<Failure?> updatePassword(String password) => _guard(() async {
        await _client.auth.updateUser(supa.UserAttributes(password: password));
      });

  /// Facteur TOTP vérifié du compte, s'il y en a un.
  Future<supa.Factor?> verifiedTotpFactor() async {
    final factors = await _client.auth.mfa.listFactors();
    for (final f in factors.totp) {
      if (f.status == supa.FactorStatus.verified) return f;
    }
    return null;
  }

  /// Commence l'ajout d'une appli de codes. Supprime d'abord un ajout
  /// précédent jamais terminé (Supabase en refuse sinon un second).
  Future<(TotpEnrollment?, Failure?)> startTotpEnrollment() async {
    try {
      final factors = await _client.auth.mfa.listFactors();
      for (final f in factors.all) {
        if (f.status == supa.FactorStatus.unverified) {
          await _client.auth.mfa.unenroll(f.id);
        }
      }
      final res = await _client.auth.mfa.enroll(
        issuer: 'Football IQ',
        friendlyName: 'Appli de codes ${DateTime.now().millisecondsSinceEpoch}',
      );
      final totp = res.totp;
      if (totp == null) return (null, const ServerFailure());
      return (
        TotpEnrollment(factorId: res.id, secret: totp.secret, uri: totp.uri),
        null,
      );
    } catch (e) {
      return (null, _toFailure(e));
    }
  }

  /// Vérifie un code à 6 chiffres : termine l'ajout de l'appli, ou valide la
  /// connexion (la session passe alors en « aal2 »).
  Future<Failure?> verifyCode({required String factorId, required String code}) =>
      _guard(() async {
        await _client.auth.mfa.challengeAndVerify(factorId: factorId, code: code);
      });

  /// Code de connexion : retrouve tout seul le facteur du compte.
  Future<Failure?> verifyLoginCode(String code) async {
    try {
      final factor = await verifiedTotpFactor();
      if (factor == null) return const AuthFailure();
      return verifyCode(factorId: factor.id, code: code);
    } catch (e) {
      return _toFailure(e);
    }
  }

  /// Désactive la double authentification. Supabase l'exige depuis une
  /// session déjà validée par un code (« aal2 »).
  Future<Failure?> disableTotp(String factorId) => _guard(() async {
        await _client.auth.mfa.unenroll(factorId);
      });

  Future<Failure?> _guard(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } catch (e) {
      return _toFailure(e);
    }
  }

  Failure _toFailure(Object e) {
    if (e is supa.AuthException) {
      final m = e.message.toLowerCase();
      if (e.code == 'mfa_verification_failed' ||
          m.contains('invalid totp') ||
          m.contains('invalid code')) {
        return const AuthFailure('Code incorrect. Réessaie avec le code affiché maintenant.');
      }
      if (e.code == 'same_password' || m.contains('different from the old')) {
        return const AuthFailure('Choisis un mot de passe différent de l\'ancien.');
      }
      if (e.code == 'weak_password' || m.contains('password should be')) {
        return const AuthFailure('Mot de passe trop faible : 8 caractères minimum.');
      }
      if (e.code == 'insufficient_aal' || m.contains('aal2')) {
        return const AuthFailure('Déconnecte-toi puis reconnecte-toi avec ton code avant de faire ça.');
      }
      if (m.contains('rate limit') || e.statusCode == '429') {
        return const AuthFailure('Trop de tentatives. Réessaie dans quelques minutes.');
      }
      if (e is supa.AuthSessionMissingException) {
        return const AuthFailure('Lien expiré. Redemande un e-mail.');
      }
      return AuthFailure(e.message);
    }
    return const ServerFailure();
  }
}
