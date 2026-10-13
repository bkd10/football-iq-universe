import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Compte marque : statut de vérification (activé manuellement par un
/// admin — voir `is_verified`, même principe que `organizations.is_verified`,
/// aucun flux de vérification automatique n'existe encore) + déconnexion.
class BrandAccountScreen extends ConsumerWidget {
  const BrandAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final isVerified = profileAsync.valueOrNull?.isVerified ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Compte marque')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: Text(
              profileAsync.valueOrNull?.displayName?.isNotEmpty == true
                  ? profileAsync.valueOrNull!.displayName!
                  : '@${profileAsync.valueOrNull?.username ?? ''}',
            ),
          ),
          const Divider(),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  isVerified ? Icons.verified : Icons.hourglass_top,
                  color: isVerified ? AppColors.primary : AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    isVerified
                        ? 'Compte vérifié — tu peux publier des Défis Sponsorisés.'
                        : 'Compte en attente de vérification manuelle avant de '
                            'pouvoir publier un Défi Sponsorisé. Contacte '
                            'l\'équipe Football IQ Universe pour la demander.',
                    style: context.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: const Text('Se déconnecter', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: AppColors.error),
            ),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}
