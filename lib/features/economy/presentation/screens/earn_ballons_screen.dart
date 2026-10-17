import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/constants/economy_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// Récapitule clairement TOUTES les façons de gagner des Ballons.
///
/// N'affiche que des méthodes réellement fonctionnelles aujourd'hui. Les
/// raisons de gain configurées côté serveur mais sans parcours utilisateur
/// réel (`ad_watched`, `invite_friend`) sont listées à part sous "Bientôt
/// disponible" — jamais mélangées aux méthodes actives, pour ne jamais
/// laisser croire qu'un bouton existe alors qu'il n'existe pas.
class EarnBallonsScreen extends StatelessWidget {
  const EarnBallonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Comment gagner des Ballons'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            ('Les Ballons se gagnent uniquement en jouant — aucune de ces '
                    'méthodes ne coûte rien.')
                .tr,
            style: context.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          _EarnTile(
            icon: Icons.celebration_outlined,
            title: 'Inscription'.tr,
            detail: 'Une seule fois, à la création de ton compte.'.tr,
            amountLabel: '+${EconomyConstants.welcomeBonus}',
          ),
          _EarnTile(
            icon: Icons.videocam_outlined,
            title: 'Publier une vidéo'.tr,
            detail: 'Jusqu\'à {n} vidéos récompensées par jour.'
                .trArgs({'n': EconomyConstants.maxPostVideoRewardsPerDay}),
            amountLabel: '+{n}/vidéo'.trArgs({'n': EconomyConstants.postVideoReward}),
          ),
          _EarnTile(
            icon: Icons.play_circle_outline,
            title: 'Regarder {n} vidéos en entier'
                .trArgs({'n': EconomyConstants.fullWatchTarget}),
            detail: 'Dans la journée, jusqu\'au bout. Une fois par jour.'.tr,
            amountLabel: '+${EconomyConstants.fullWatchReward}',
          ),
          _EarnTile(
            icon: Icons.emoji_events_outlined,
            title: 'Gagner un Défi ou une Battle'.tr,
            detail: ('Le joueur avec le plus de votes remporte toute la '
                    'cagnotte (droits d\'entrée ou mises de la Battle), plus '
                    '100 Stars.')
                .tr,
            amountLabel: 'Cagnotte + 100 ★'.tr,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Bientôt disponible'.tr, style: context.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            ('Ces méthodes sont prévues mais pas encore actives dans '
                    'l\'app.')
                .tr,
            style: context.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          _EarnTile(
            icon: Icons.smart_display_outlined,
            title: 'Regarder une publicité'.tr,
            detail: 'Jusqu\'à {n} publicités par jour.'
                .trArgs({'n': EconomyConstants.maxAdWatchedPerDay}),
            amountLabel: '+${EconomyConstants.adWatchedReward}',
            comingSoon: true,
          ),
          _EarnTile(
            icon: Icons.person_add_alt_outlined,
            title: 'Inviter un ami'.tr,
            detail: 'Quand ton ami rejoint Football IQ Universe.'.tr,
            amountLabel: '+${EconomyConstants.inviteFriendReward}',
            comingSoon: true,
          ),
        ],
      ),
    );
  }
}

class _EarnTile extends StatelessWidget {
  const _EarnTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.amountLabel,
    this.comingSoon = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String amountLabel;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: comingSoon ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: context.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (comingSoon)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'Bientôt'.tr,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: context.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              amountLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
