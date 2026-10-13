/// Exceptions de la couche `data` (datasources). Elles sont attrapées par
/// les repositories et converties en [Failure] pour la couche `domain`.
class ServerException implements Exception {
  const ServerException([this.message = 'Une erreur serveur est survenue.']);
  final String message;
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'Pas de connexion réseau.']);
  final String message;
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

class CacheException implements Exception {
  const CacheException([this.message = 'Erreur de cache local.']);
  final String message;
}

/// Levée par les datasources économie quand `spend_coins` rejette un débit
/// faute de solde suffisant (voir `EconomyRemoteDataSource._mapRpcError`).
class InsufficientCoinsException implements Exception {
  const InsufficientCoinsException([
    this.message = 'Solde de Ballons insuffisant.',
  ]);
  final String message;
}

/// Levée quand une action gratuite (`award_coins`) a déjà atteint sa
/// limite quotidienne (connexion déjà réclamée, 3 vidéos/jour, etc.).
class DailyLimitException implements Exception {
  const DailyLimitException([
    this.message = 'Limite quotidienne atteinte pour cette action.',
  ]);
  final String message;
}

/// Levée par `signIn` quand Supabase refuse la connexion parce que
/// l'adresse e-mail n'a pas encore été confirmée — distincte d'un
/// identifiant/mot de passe invalide, pour que l'écran de connexion puisse
/// rediriger vers l'écran "Confirme ton e-mail" plutôt que d'afficher une
/// simple erreur qui laisserait penser à un mauvais mot de passe.
class EmailNotConfirmedException implements Exception {
  const EmailNotConfirmedException(this.message);
  final String message;
}
