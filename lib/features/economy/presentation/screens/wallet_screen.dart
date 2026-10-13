import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/string_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/coin_transaction.dart';
import '../providers/economy_providers.dart';

const _reasonLabels = {
  'welcome_bonus': 'Bonus de bienvenue',
  'daily_login': 'Connexion quotidienne',
  'post_video': 'Vidéo publiée',
  'ad_watched': 'Publicité regardée',
  'move_reproduced': 'Move reproduit',
  'masterclass_received': 'Masterclass reçue',
  'video_views_milestone': 'Palier de vues',
  'daily_videos_watched': 'Mission : 3 vidéos regardées',
  'join_challenge': 'Participation à un défi',
  'join_battle': 'Participation à une Battle',
  'win_challenge': 'Défi remporté',
  'create_challenge': 'Création d\'un défi',
  'boost_video': 'Boost de vidéo',
  'custom_badge': 'Badge personnalisé',
  'special_effect': 'Effet spécial',
};

/// Solde de Ballons + historique des transactions — voir PARTIE 9.2
/// (écran "Wallet").
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final coins = profileAsync.valueOrNull?.coins;

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(currentProfileProvider);
          ref.invalidate(transactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _BalanceCard(coins: coins),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.emoji_events_outlined, size: 18),
                    label: const Text('Comment gagner'),
                    onPressed: () => context.push(RouteNames.earnBallons),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.storefront_outlined, size: 18),
                    label: const Text('Boutique'),
                    onPressed: () => context.push(RouteNames.shop),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Historique', style: context.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            transactionsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: AppLoader()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  error is Failure ? error.message : 'Erreur de chargement.',
                  style: context.textTheme.bodyMedium,
                ),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'Aucune transaction pour l\'instant.',
                      style: context.textTheme.bodyMedium,
                    ),
                  );
                }
                return Column(
                  children: transactions
                      .map((t) => _TransactionTile(transaction: t))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.coins});

  final int? coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.surface, AppColors.surfaceLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.paid_outlined, color: AppColors.gold, size: 36),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Solde de Ballons',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                coins != null ? Formatters.compactCount(coins!) : '—',
                style: AppTypography.stat(fontSize: 26, color: AppColors.gold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final CoinTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.amount >= 0;
    final label = _reasonLabels[transaction.reason] ??
        transaction.reason.fromSnakeCaseToTitle;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: isPositive ? AppColors.primary : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  Formatters.relativeTime(transaction.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${transaction.amount}',
            style: AppTypography.stat(
              fontSize: 15,
              color: isPositive ? AppColors.primary : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
