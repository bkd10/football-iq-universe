import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../domain/entities/content_report.dart';
import '../providers/moderation_providers.dart';

/// Écran de résolution des signalements — réservé aux comptes
/// `role = 'admin'` par la RLS de `content_reports` (voir
/// `20260101000015_hardening.sql`) : pas de route publique dans le router,
/// accessible uniquement en tapant l'URL manuellement pour l'instant
/// (aucun rôle admin ne s'inscrit lui-même, attribué à la main via le
/// dashboard Supabase — voir HANDOFF.md).
class AdminModerationScreen extends ConsumerWidget {
  const AdminModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(pendingReportsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Modération — signalements')),
      body: reportsAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              error is Failure
                  ? error.message
                  : 'Impossible de charger les signalements (réservé aux admins).',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium,
            ),
          ),
        ),
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Text(
                'Aucun signalement en attente.',
                style: context.textTheme.bodyMedium,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pendingReportsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _ReportCard(report: reports[index]),
            ),
          );
        },
      ),
    );
  }
}

class _ReportCard extends ConsumerStatefulWidget {
  const _ReportCard({required this.report});

  final ContentReport report;

  @override
  ConsumerState<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends ConsumerState<_ReportCard> {
  bool _busy = false;

  Future<void> _resolve(String status) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await ref.read(moderationActionsControllerProvider.notifier).resolveReport(
          reportId: widget.report.id,
          status: status,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      final failure = ref.read(moderationActionsControllerProvider).error;
      context.showSnackBar(
        failure is Failure ? failure.message : 'Échec de la résolution.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TargetTypeBadge(targetType: report.targetType),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  report.reason,
                  style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Cible : ${report.targetId}\n'
            'Signalé par @${report.reporterUsername ?? 'compte supprimé'} · '
            '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
            style: context.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _resolve('dismissed'),
                  child: const Text('Ignorer'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : () => _resolve('actioned'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                  child: const Text('Agir (contenu retiré)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TargetTypeBadge extends StatelessWidget {
  const _TargetTypeBadge({required this.targetType});

  final String targetType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        targetType,
        style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
