import 'package:equatable/equatable.dart';

/// Représente un échec métier propagé jusqu'à la couche presentation via
/// `Either<Failure, T>` (dartz). Contrairement aux [Exception]s (couche
/// data), les [Failure]s sont ce que l'UI sait afficher.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Une erreur serveur est survenue.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Vérifie ta connexion internet.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Échec de l\'authentification.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Solde de Ballons insuffisant pour l'action demandée (spend-coins).
class InsufficientCoinsFailure extends Failure {
  const InsufficientCoinsFailure([
    super.message = 'Solde de Ballons insuffisant.',
  ]);
}

/// Limite quotidienne atteinte pour une action (ex : 3 vidéos/jour).
class DailyLimitReachedFailure extends Failure {
  const DailyLimitReachedFailure([
    super.message = 'Limite quotidienne atteinte pour cette action.',
  ]);
}

/// Connexion refusée parce que l'e-mail n'est pas encore confirmé — voir
/// `EmailNotConfirmedException`. L'écran de connexion s'en sert pour
/// rediriger vers `ConfirmEmailScreen` plutôt que d'afficher une erreur
/// générique.
class EmailNotConfirmedFailure extends Failure {
  const EmailNotConfirmedFailure([
    super.message = 'Confirme ton e-mail avant de te connecter.',
  ]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Une erreur inattendue est survenue.']);
}
