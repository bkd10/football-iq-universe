import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Échelle typographique de l'app.
///
/// - Montserrat (Bold/SemiBold) pour les titres
/// - Inter (Regular/Medium) pour le corps de texte
/// - Space Mono pour les chiffres/stats (compteurs, classements)
///
/// Chargées via `google_fonts` plutôt que des assets embarqués : pas de
/// binaires de police à maintenir dans le repo.
class AppTypography {
  const AppTypography._();

  static TextTheme get textTheme => TextTheme(
        displayLarge: GoogleFonts.montserrat(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.montserrat(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        displaySmall: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.montserrat(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );

  /// Style "data/tech" pour les chiffres — Stars, Ballons, classements.
  static TextStyle stat({
    double fontSize = 20,
    Color color = AppColors.textPrimary,
    FontWeight fontWeight = FontWeight.w700,
  }) =>
      GoogleFonts.spaceMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
}
