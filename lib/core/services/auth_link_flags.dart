import 'browser/browser.dart';

/// Repères lus dans l'adresse de la page au démarrage, AVANT l'initialisation
/// de Supabase : celle-ci consomme le `?code=...` du lien reçu par e-mail
/// puis nettoie l'adresse, ce qui effacerait aussi nos propres repères.
class AuthLinkFlags {
  AuthLinkFlags._();

  /// Paramètre ajouté au lien « mot de passe oublié » (voir
  /// `AuthRemoteDataSource.sendPasswordResetEmail`).
  static const resetParam = 'reset';

  /// La page a été ouverte depuis un lien « mot de passe oublié ».
  static bool resetRequested = false;

  static void capture([Uri? uri]) {
    final params = (uri ?? Uri.base).queryParameters;
    resetRequested = params[resetParam] == '1';
  }

  /// À appeler une fois Supabase initialisé : sans ça, recharger la page
  /// rouvrirait l'écran « Nouveau mot de passe ».
  static void clearUrl() => removeQueryParameter(resetParam);
}
