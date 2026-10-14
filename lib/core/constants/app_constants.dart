/// Constantes globales de l'application (hors valeurs économiques,
/// voir [EconomyConstants]).
class AppConstants {
  const AppConstants._();

  static const String appName = 'Football IQ Universe';

  // Vidéo
  static const int minVideoDurationSeconds = 5;
  static const int maxVideoDurationSeconds = 60;

  // Pagination
  static const int feedPageSize = 10;
  static const int rankingsPageSize = 50;
  static const int commentsPageSize = 20;

  // Vue comptabilisée après ce délai réel de visionnage (anti-triche).
  static const Duration minWatchTimeForView = Duration(seconds: 3);

  static const List<String> videoCategories = [
    'dribble',
    'shot',
    'pass',
    'control',
    'freestyle',
    'celebration',
    'defense',
    'goalkeeper',
  ];

  static const List<String> playerPositions = [
    'attaquant',
    'milieu',
    'defenseur',
    'gardien',
  ];

  static const List<String> preferredFeet = ['gauche', 'droit', 'les_deux'];

  static const List<String> userLevels = [
    'rookie',
    'rising_star',
    'prodigy',
    'legend',
  ];
}
