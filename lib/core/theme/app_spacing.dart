/// Système d'espacement en base 4, utilisé partout à la place de valeurs
/// en dur pour garantir la cohérence visuelle.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Rayon de bordure standard des cards, bottom sheets (top), etc.
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusButton = 12;
  static const double radiusInput = 12;
}
