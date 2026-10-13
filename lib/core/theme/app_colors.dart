import 'package:flutter/material.dart';

/// Palette de couleurs officielle de Football IQ Universe.
///
/// Ambiance : futuriste, sportive, premium — néon sur fond sombre.
/// Dark mode uniquement en MVP (voir [AppTheme]).
class AppColors {
  const AppColors._();

  // Primary — vert néon
  static const Color primary = Color(0xFF00FF87);
  static const Color primaryDark = Color(0xFF00CC6A);
  static const Color primaryLight = Color(0xFF66FFAD);

  // Backgrounds
  static const Color background = Color(0xFF0F0F1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF252540);

  // Accents — niveaux et récompenses
  static const Color gold = Color(0xFFFFD700);
  static const Color diamond = Color(0xFF00D4FF);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  // Semantic
  static const Color success = Color(0xFF00FF87);
  static const Color error = Color(0xFFFF4757);
  static const Color warning = Color(0xFFFFBE0B);
  static const Color info = Color(0xFF3A86FF);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B8B9A);
  static const Color textTertiary = Color(0xFF5A5A6E);

  /// Couleur associée à chaque niveau de joueur (bordure d'avatar, badges).
  static Color forLevel(String level) {
    switch (level) {
      case 'legend':
        return diamond;
      case 'prodigy':
        return gold;
      case 'rising_star':
        return silver;
      case 'rookie':
      default:
        return bronze;
    }
  }
}
