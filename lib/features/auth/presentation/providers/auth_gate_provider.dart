
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/services/auth_link_flags.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../data/services/account_security_service.dart';

/// Écran que l'appli doit imposer avant tout le reste.
enum AuthGate {
  /// Rien à imposer : navigation normale.
  open,

  /// Retour du lien « mot de passe oublié » : choisir un nouveau mot de passe.
  newPassword,

  /// Lien « mot de passe oublié » expiré ou ouvert ailleurs.
  resetLinkInvalid,

  /// Mot de passe accepté, code de double authentification attendu.
  mfaCode,
}

final accountSecurityServiceProvider = Provider<AccountSecurityService>(
  (ref) => AccountSecurityService(ref.watch(supabaseClientProvider)),
);

class AuthGateController extends Notifier<AuthGate> {
  @override
  AuthGate build() {
    final client = ref.watch(supabaseClientProvider);
    final sub = client.auth.onAuthStateChange.listen(
      (data) {
        if (data.event == supa.AuthChangeEvent.passwordRecovery) {
          AuthLinkFlags.resetRequested = true;
        } else if (data.event == supa.AuthChangeEvent.signedOut) {
          AuthLinkFlags.resetRequested = false;
        }
        state = _evaluate(client);
      },
      onError: (Object _) => state = _evaluate(client),
    );
    ref.onDispose(sub.cancel);
    return _evaluate(client);
  }

  /// Le code de double authentification passe avant le nouveau mot de
  /// passe : Supabase refuse de changer le mot de passe d'un compte protégé
  /// tant que le code n'a pas été saisi.
  AuthGate _evaluate(supa.SupabaseClient client) {
    if (client.auth.currentSession == null) {
      return AuthLinkFlags.resetRequested ? AuthGate.resetLinkInvalid : AuthGate.open;
    }
    if (needsMfaCode(client)) return AuthGate.mfaCode;
    if (AuthLinkFlags.resetRequested) return AuthGate.newPassword;
    return AuthGate.open;
  }

  /// Ré-évalue après une connexion (le code est-il demandé ?).
  void refresh() => state = _evaluate(ref.read(supabaseClientProvider));

  /// Nouveau mot de passe enregistré, ou lien abandonné.
  void finishReset() {
    AuthLinkFlags.resetRequested = false;
    refresh();
  }
}

final authGateProvider =
    NotifierProvider<AuthGateController, AuthGate>(AuthGateController.new);
