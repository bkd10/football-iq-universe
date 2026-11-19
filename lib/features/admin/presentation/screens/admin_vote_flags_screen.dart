import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../domain/admin_models.dart';
import '../providers/admin_providers.dart';

const _reasonLabels = {
  'same_device': 'Plusieurs comptes sur le même appareil',
  'same_network': 'Plusieurs comptes sur le même réseau',
  'new_account': 'Compte créé il y a quelques minutes',
  'burst': 'Beaucoup de votes en peu de temps',
};

/// Votes suspects repérés par le serveur. Le vote est compté tant que
/// l'admin ne l'annule pas.
class AdminVoteFlagsScreen extends ConsumerWidget {
  const AdminVoteFlagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(adminVoteFlagsStatusProvider);
    final flags = ref.watch(adminVoteFlagsProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Votes suspects'.tr)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'pending', label: Text('En attente'.tr)),
                ButtonSegment(value: 'all', label: Text('Tout'.tr)),
              ],
              selected: {status},
              onSelectionChanged: (s) => ref.read(adminVoteFlagsStatusProvider.notifier).state = s.first,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(adminVoteFlagsProvider),
              child: flags.when(
                loading: () => const Center(child: AppLoader()),
                error: (e, _) => ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(adminErrorText(e), style: const TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
                data: (list) => list.isEmpty
                    ? ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Text('Aucun vote suspect.'.tr, textAlign: TextAlign.center),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        itemCount: list.length,
                        itemBuilder: (context, i) => _FlagTile(flag: list[i]),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagTile extends ConsumerWidget {
  const _FlagTile({required this.flag});

  final AdminVoteFlag flag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = switch (flag.reason) {
      'same_device' || 'same_network' => '{n} comptes'.trArgs({'n': flag.details['accounts'] ?? '?'}),
      'new_account' => 'Compte de {n} min'.trArgs({'n': flag.details['account_age_minutes'] ?? '?'}),
      'burst' => '{n} votes en 10 min'.trArgs({'n': flag.details['votes'] ?? '?'}),
      _ => '',
    };
    final statusText = switch (flag.status) {
      'ignored' => 'Gardé'.tr,
      'vote_removed' => 'Vote annulé'.tr,
      _ => 'En attente'.tr,
    };
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text((_reasonLabels[flag.reason] ?? flag.reason).tr, style: context.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              '@{voter} → @{target} · {detail}'.trArgs({
                'voter': flag.voterUsername ?? '?',
                'target': flag.votedForUsername ?? '?',
                'detail': detail,
              }),
            ),
            InkWell(
              onTap: () => context.push(RouteNames.challengeDetailPath(flag.challengeId)),
              child: Text(flag.challengeTitle, style: const TextStyle(color: AppColors.primary)),
            ),
            Text(
              '{status} · {date}'.trArgs({'status': statusText, 'date': Formatters.shortDate(flag.createdAt)}),
              style: context.textTheme.bodySmall,
            ),
            if (flag.status == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _resolve(context, ref, removeVote: false),
                    child: Text('Garder le vote'.tr),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                    onPressed: () => _resolve(context, ref, removeVote: true),
                    child: Text('Annuler le vote'.tr),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref, {required bool removeVote}) async {
    try {
      await ref.read(adminDataSourceProvider).resolveVoteFlag(flag.id, removeVote: removeVote);
      ref
        ..invalidate(adminVoteFlagsProvider)
        ..invalidate(adminPendingVoteFlagsProvider);
      if (context.mounted) {
        context.showSnackBar(removeVote ? 'Vote annulé.'.tr : 'Vote gardé.'.tr);
      }
    } catch (e) {
      if (context.mounted) context.showSnackBar(adminErrorText(e), isError: true);
    }
  }
}
