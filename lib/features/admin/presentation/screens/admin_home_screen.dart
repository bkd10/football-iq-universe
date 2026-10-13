import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../domain/admin_models.dart';
import '../providers/admin_providers.dart';

/// Tableau de bord administrateur : chiffres clés et accès aux outils.
/// Visible dans les Réglages uniquement pour `role = 'admin'` ; les données
/// sont de toute façon refusées par le serveur à tout autre compte.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminStatsProvider),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            statsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: AppLoader()),
              ),
              error: (error, _) => Text(
                adminErrorText(error),
                style: context.textTheme.bodyMedium?.copyWith(color: AppColors.error),
              ),
              data: (stats) => _StatsGrid(stats: stats),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ToolTile(
              icon: Icons.flag_outlined,
              title: 'Signalements',
              subtitle: 'Retirer ou garder un contenu signalé, avec un message.',
              badge: statsAsync.valueOrNull?.reportsPending ?? 0,
              onTap: () async {
                await context.push(RouteNames.adminModeration);
                ref.invalidate(adminStatsProvider);
              },
            ),
            _ToolTile(
              icon: Icons.people_alt_outlined,
              title: 'Joueurs',
              subtitle: 'Rechercher, voir les signalements, bannir.',
              onTap: () async {
                await context.push(RouteNames.adminUsers);
                ref.invalidate(adminStatsProvider);
              },
            ),
            _ToolTile(
              icon: Icons.emoji_events_outlined,
              title: 'Créer un défi officiel',
              subtitle: 'Gratuit pour les joueurs, mis en avant comme officiel.',
              onTap: () => context.push(RouteNames.adminOfficialChallenge),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Joueurs', '${stats.playersTotal}', '+${stats.playersToday} aujourd\'hui · +${stats.players7d} en 7 j'),
      ('Vidéos en ligne', '${stats.videosTotal}', '+${stats.videosToday} aujourd\'hui'),
      ('Défis en cours', '${stats.challengesActive}', null),
      ('Signalements', '${stats.reportsPending}', 'en attente'),
      ('Bannis', '${stats.bannedTotal}', null),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (label, value, detail) in items)
          FractionallySizedBox(
            widthFactor: 0.48,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    style: context.textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (detail != null)
                    Text(detail, style: context.textTheme.bodySmall?.copyWith(fontSize: 11)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: badge > 0
            ? Badge(label: Text('$badge'), backgroundColor: AppColors.error)
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
