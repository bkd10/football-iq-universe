import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/ranking_category.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/ranking_entry.dart';
import '../providers/ranking_providers.dart';

enum _Region { world, country, city }

/// Classements — voir PARTIE 8.6 : 5 catégories, filtre région (Mondial /
/// Pays / Ville, basé sur le profil de l'utilisateur). Le filtre de
/// période (Jour/Semaine/Mois) n'est pas encore implémenté : il
/// nécessite un historique des Stars que le schéma MVP ne conserve pas
/// encore (voir README).
class RankingsScreen extends ConsumerStatefulWidget {
  const RankingsScreen({super.key});

  @override
  ConsumerState<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends ConsumerState<RankingsScreen> {
  String _category = RankingCategory.footballIq;
  _Region _region = _Region.world;

  @override
  Widget build(BuildContext context) {
    final myProfile = ref.watch(currentProfileProvider).valueOrNull;

    final query = (
      category: _category,
      country: _region != _Region.world ? myProfile?.country : null,
      city: _region == _Region.city ? myProfile?.city : null,
    );
    final rankingsAsync = ref.watch(rankingsProvider(query));

    return Scaffold(
      appBar: AppBar(title: Text('Classements'.tr)),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              itemCount: RankingCategory.all.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final category = RankingCategory.all[index];
                final selected = category == _category;
                return ChoiceChip(
                  label: Text((RankingCategory.labels[category] ?? category).tr),
                  selected: selected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.surfaceLight,
                  ),
                  backgroundColor: AppColors.surface,
                  onSelected: (_) => setState(() => _category = category),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                _RegionTab(
                  label: '🌍 Mondial'.tr,
                  active: _region == _Region.world,
                  onTap: () => setState(() => _region = _Region.world),
                ),
                _RegionTab(
                  label: '🏳️ Mon pays'.tr,
                  active: _region == _Region.country,
                  onTap: myProfile?.country == null
                      ? null
                      : () => setState(() => _region = _Region.country),
                ),
                _RegionTab(
                  label: '📍 Ma ville'.tr,
                  active: _region == _Region.city,
                  onTap: myProfile?.city == null
                      ? null
                      : () => setState(() => _region = _Region.city),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: rankingsAsync.when(
              loading: () => const Center(child: AppLoader()),
              error: (error, _) => Center(
                child: Text(
                  error is Failure ? error.message : 'Erreur de chargement.'.tr,
                  style: context.textTheme.bodyMedium,
                ),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucun classement disponible pour l\'instant.'.tr,
                      style: context.textTheme.bodyMedium,
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) => _RankingRow(
                    entry: entries[index],
                    isMe: entries[index].userId == myProfile?.id,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionTab extends StatelessWidget {
  const _RegionTab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: active ? AppColors.primary : AppColors.textSecondary,
        ),
        child: Text(
          label,
          style: TextStyle(fontWeight: active ? FontWeight.w700 : FontWeight.w500),
        ),
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.entry, required this.isMe});

  final RankingEntry entry;
  final bool isMe;

  static const _medalColors = {1: AppColors.gold, 2: AppColors.silver, 3: AppColors.bronze};

  @override
  Widget build(BuildContext context) {
    final medalColor = _medalColors[entry.rank];
    final levelColor = AppColors.forLevel(entry.level);

    return GestureDetector(
      onTap: () => isMe
          ? context.go(RouteNames.profile)
          : context.push(RouteNames.otherProfilePath(entry.userId)),
      child: Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: isMe ? Border.all(color: AppColors.primary.withValues(alpha: 0.4)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${entry.rank}',
              style: AppTypography.stat(
                fontSize: 14,
                color: medalColor ?? AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.surfaceLight,
            child: Text(
              entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? 'Toi (@{username})'.trArgs({'username': entry.username}) : '@${entry.username}',
                  style: Theme.of(context).textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entry.city ?? entry.country ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsetsDirectional.only(end: 6),
            decoration: BoxDecoration(color: levelColor, shape: BoxShape.circle),
          ),
          Text(
            '${entry.score}',
            style: AppTypography.stat(fontSize: 15, color: AppColors.primary),
          ),
        ],
        ),
      ),
    );
  }
}
