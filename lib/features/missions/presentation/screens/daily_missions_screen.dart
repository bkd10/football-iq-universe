import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/daily_mission.dart';
import '../providers/missions_providers.dart';

/// Carrière quotidienne — voir PARTIE 8.5. Les missions se complètent en
/// utilisant l'app normalement (se connecter, publier, regarder des
/// vidéos) : cet écran est un tableau de bord de la progression du jour,
/// pas un écran d'action.
class DailyMissionsScreen extends ConsumerWidget {
  const DailyMissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionAsync = ref.watch(todayMissionProvider);
    final streakDays = ref.watch(currentProfileProvider).valueOrNull?.streakDays ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text('Missions du jour'.tr)),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(todayMissionProvider),
        child: missionAsync.when(
          loading: () => const Center(child: AppLoader()),
          error: (error, _) => Center(
            child: Text(
              error is Failure ? error.message : 'Erreur de chargement.'.tr,
              style: context.textTheme.bodyMedium,
            ),
          ),
          data: (mission) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _StreakCard(streakDays: streakDays),
              const SizedBox(height: AppSpacing.lg),
              _ProgressHeader(mission: mission),
              const SizedBox(height: AppSpacing.md),
              _MissionTile(
                icon: Icons.videocam_outlined,
                label: 'Publier une vidéo'.tr,
                reward: '+5 Ballons'.tr,
                done: mission.videoPosted,
              ),
              _MissionTile(
                icon: Icons.play_circle_outline,
                label: 'Regarder {n} vidéos en entier'.trArgs({'n': DailyMission.fullWatchTarget}),
                reward: '+{n} Ballons'.trArgs({'n': DailyMission.fullWatchReward}),
                done: mission.fullWatchRewarded,
                progressLabel:
                    '${mission.fullVideosWatched.clamp(0, DailyMission.fullWatchTarget)}/${DailyMission.fullWatchTarget}',
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  '{n} Ballons gagnés aujourd\'hui'.trArgs({'n': mission.coinsEarned}),
                  style: AppTypography.stat(color: AppColors.gold, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: AppColors.gold, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Série en cours'.tr, style: context.textTheme.bodyMedium),
                Text(
                  (streakDays > 1 ? '{n} jours' : '{n} jour').trArgs({'n': streakDays}),
                  style: context.textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          if (streakDays >= 7)
            const Icon(Icons.emoji_events, color: AppColors.gold)
          else
            Text('7j : badge'.tr, style: context.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.mission});

  final DailyMission mission;

  @override
  Widget build(BuildContext context) {
    final progress = mission.completedCount / DailyMission.totalMissions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progression'.tr, style: context.textTheme.titleLarge),
            Text(
              '${mission.completedCount}/${DailyMission.totalMissions}',
              style: context.textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.surfaceLight,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({
    required this.icon,
    required this.label,
    required this.reward,
    required this.done,
    this.progressLabel,
  });

  final IconData icon;
  final String label;
  final String reward;
  final bool done;
  final String? progressLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle : icon,
              color: done ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.textTheme.bodyLarge?.copyWith(
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? AppColors.textSecondary : null,
                    ),
                  ),
                  if (progressLabel != null)
                    Text(progressLabel!, style: context.textTheme.bodySmall),
                ],
              ),
            ),
            Text(
              reward,
              style: context.textTheme.bodyMedium?.copyWith(color: AppColors.gold),
            ),
          ],
        ),
      ),
    );
  }
}
