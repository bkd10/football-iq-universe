import 'package:flutter/material.dart';

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
      appBar: AppBar(title: const Text('Comment gagner des Ballons')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Les Ballons se gagnent uniquement en jouant — aucune de ces '
            'méthodes ne coûte rien.',
            style: context.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _EarnTile(
            icon: Icons.celebration_outlined,
            title: 'Inscription',
            detail: 'Une seule fois, à la création de ton compte.',
            amountLabel: '+${EconomyConstants.welcomeBonus}',
          ),
          const _EarnTile(
            icon: Icons.today_outlined,
            title: 'Connexion quotidienne',
            detail: 'Ouvre l\'app chaque jour. Le montant grandit avec ta '
                'série de connexions.',
            amountLabel:
                '+${EconomyConstants.dailyLoginMin} à '
                '${EconomyConstants.dailyLoginMax}/jour',
          ),
          const _EarnTile(
            icon: Icons.local_fire_department_outlined,
            title: 'Série de 7 jours',
            detail: 'Connecte-toi 7 jours d\'affilée sans interruption.',
            amountLabel: '+${EconomyConstants.streak7DaysBonus} bonus',
          ),
          const _EarnTile(
            icon: Icons.military_tech_outlined,
            title: 'Série de 30 jours',
            detail: 'Connecte-toi 30 jours d\'affilée sans interruption.',
            amountLabel: '+${EconomyConstants.streak30DaysBonus} bonus',
          ),
          const _EarnTile(
            icon: Icons.videocam_outlined,
            title: 'Publier une vidéo',
            detail: 'Jusqu\'à ${EconomyConstants.maxPostVideoRewardsPerDay} '
                'vidéos récompensées par jour.',
            amountLabel: '+${EconomyConstants.postVideoReward}/vidéo',
          ),
          const _EarnTile(
            icon: Icons.play_circle_outline,
            title: 'Regarder 3 vidéos dans la journée',
            detail: 'Mission quotidienne, à réclamer depuis l\'onglet '
                'Missions.',
            amountLabel: '+5',
          ),
          const _EarnTile(
            icon: Icons.refresh,
            title: 'Un joueur reproduit ton Move',
            detail: 'Tu restes l\'inventeur affiché à vie sur ce Move — '
                'chaque reproduction (hors la tienne) te rapporte.',
            amountLabel: '+${EconomyConstants.moveReproducedReward}',
          ),
          const _EarnTile(
            icon: Icons.emoji_events_outlined,
            title: 'Gagner un Défi, une Battle ou un King',
            detail: 'La cagnotte est constituée des droits d\'entrée payés '
                'par tous les participants — le vainqueur la remporte '
                'intégralement, plus 100 Stars.',
            amountLabel: 'Cagnotte + 100 ★',
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Bientôt disponible', style: context.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Ces méthodes sont prévues mais pas encore actives dans '
            'l\'app.',
            style: context.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          const _EarnTile(
            icon: Icons.smart_display_outlined,
            title: 'Regarder une publicité',
            detail: 'Jusqu\'à ${EconomyConstants.maxAdWatchedPerDay} '
                'publicités par jour.',
            amountLabel: '+${EconomyConstants.adWatchedReward}',
            comingSoon: true,
          ),
          const _EarnTile(
            icon: Icons.person_add_alt_outlined,
            title: 'Inviter un ami',
            detail: 'Quand ton ami rejoint Football IQ Universe.',
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
                          child: const Text(
                            'Bientôt',
                            style: TextStyle(
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
