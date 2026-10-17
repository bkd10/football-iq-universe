import 'package:equatable/equatable.dart';

import '../l10n/l10n.dart';

/// Représente un échec métier propagé jusqu'à la couche presentation via
/// `Either<Failure, T>` (dartz). Contrairement aux [Exception]s (couche
/// data), les [Failure]s sont ce que l'UI sait afficher.
sealed class Failure extends Equatable {
  const Failure(this.rawMessage);

  /// Message d'origine, en français (code ou serveur).
  final String rawMessage;

  /// Message affiché, dans la langue du téléphone.
  String get message => rawMessage.trServer;

  @override
  List<Object?> get props => [rawMessage];
}

class ServerFailure extends Failure {
  const ServerFailure([super.rawMessage = 'Une erreur serveur est survenue.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.rawMessage = 'Vérifie ta connexion internet.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.rawMessage = 'Échec de l\'authentification.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.rawMessage);
}

/// Solde de Ballons insuffisant pour l'action demandée (spend-coins).
class InsufficientCoinsFailure extends Failure {
  const InsufficientCoinsFailure([
    super.rawMessage = 'Solde de Ballons insuffisant.',
  ]);
}

/// Limite quotidienne atteinte pour une action (ex : 3 vidéos/jour).
class DailyLimitReachedFailure extends Failure {
  const DailyLimitReachedFailure([
    super.rawMessage = 'Limite quotidienne atteinte pour cette action.',
  ]);
}

/// Connexion refusée parce que l'e-mail n'est pas encore confirmé — voir
/// `EmailNotConfirmedException`. L'écran de connexion s'en sert pour
/// rediriger vers `ConfirmEmailScreen` plutôt que d'afficher une erreur
/// générique.
class EmailNotConfirmedFailure extends Failure {
  const EmailNotConfirmedFailure([
    super.rawMessage = 'Confirme ton e-mail avant de te connecter.',
  ]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.rawMessage = 'Une erreur inattendue est survenue.']);
}
