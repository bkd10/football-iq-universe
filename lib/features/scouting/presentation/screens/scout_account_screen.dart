import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/scouting_providers.dart';

/// Compte recruteur : statut d'abonnement + activation de l'essai gratuit
/// (aucun paiement réel branché, voir `start_scout_trial`) + déconnexion.
class ScoutAccountScreen extends ConsumerWidget {
  const ScoutAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final subscriptionAsync = ref.watch(myScoutSubscriptionProvider);
    final isTrialLoading = ref.watch(scoutTrialControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: Text('Compte recruteur'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: Text(
              profileAsync.valueOrNull?.username != null
                  ? '@${profileAsync.valueOrNull!.username}'
                  : 'Recruteur'.tr,
            ),
          ),
          const Divider(),
          Text('ABONNEMENT'.tr, style: context.textTheme.bodySmall?.copyWith(letterSpacing: 1)),
          const SizedBox(height: AppSpacing.sm),
          subscriptionAsync.when(
            loading: () => const AppLoader(),
            error: (error, _) => Text(
              error is Failure ? error.message : 'Erreur de chargement.'.tr,
            ),
            data: (subscription) {
              if (subscription == null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      ('Aucun abonnement actif. Contacter un joueur nécessite '
                      'un abonnement — active ton essai gratuit de 14 jours '
                      'pour commencer (aucun paiement requis, aucune carte '
                      'bancaire demandée).').tr,
                      style: context.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppPrimaryButton(
                      label: 'Activer l\'essai gratuit (14 jours)'.tr,
                      isLoading: isTrialLoading,
                      onPressed: () async {
                        final success =
                            await ref.read(scoutTrialControllerProvider.notifier).start();
                        if (!context.mounted) return;
                        if (success) {
                          context.showSnackBar('Essai gratuit activé !'.tr);
                        } else {
                          final failure = ref.read(scoutTrialControllerProvider).error;
                          context.showSnackBar(
                            failure is Failure ? failure.message : 'Échec de l\'activation.'.tr,
                            isError: true,
                          );
                        }
                      },
                    ),
                  ],
                );
              }
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(
                      subscription.isActive ? Icons.check_circle : Icons.error_outline,
                      color: subscription.isActive ? AppColors.primary : AppColors.error,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        !subscription.isActive
                            ? 'Abonnement expiré.'.tr
                            : subscription.expiresAt != null
                                ? 'Plan {plan} actif jusqu\'au {date}.'.trArgs({
                                    'plan': subscription.plan,
                                    'date': '${subscription.expiresAt!.day}/${subscription.expiresAt!.month}/${subscription.expiresAt!.year}',
                                  })
                                : 'Plan {plan} actif.'.trArgs({'plan': subscription.plan}),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: Text('Se déconnecter'.tr, style: const TextStyle(color: AppColors.error)),
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
