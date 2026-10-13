import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Indicateur de chargement circulaire aux couleurs de l'app.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.size = 32, this.color = AppColors.primary});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

/// Loader plein écran centré, pour les états de chargement bloquants.
class AppFullScreenLoader extends StatelessWidget {
  const AppFullScreenLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.background,
      child: Center(child: AppLoader()),
    );
  }
}
