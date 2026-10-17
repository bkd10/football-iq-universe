import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Écran temporaire pour les features pas encore implémentées
/// (Semaines 3 à 8 du planning — voir PARTIE 20 de la spécification).
/// Sert de destination valide pour le router en attendant le
/// développement de la feature correspondante.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    required this.icon,
    super.key,
    this.subtitle = 'Cette fonctionnalité arrive bientôt.',
  });

  final String title;
  final IconData icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.md),
              Text(
                subtitle.tr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
