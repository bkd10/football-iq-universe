import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../../admin/domain/admin_messages.dart';
import '../../../admin/domain/admin_models.dart';
import '../../../admin/presentation/providers/admin_providers.dart';

const _targetLabels = {'video': 'Vidéo', 'comment': 'Commentaire', 'profile': 'Profil'};

/// Signalements en attente, un par contenu (les signalements multiples sur
/// un même contenu sont regroupés). L'admin voit le contenu, puis décide de
/// le garder ou de le retirer (bannir pour un profil), avec un message
/// pré-écrit et modifiable envoyé à l'auteur et aux signaleurs.
class AdminModerationScreen extends ConsumerWidget {
  const AdminModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(adminReportsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Signalements'.tr)),
      body: reportsAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(adminErrorText(error), textAlign: TextAlign.center),
          ),
        ),
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Text('Aucun signalement en attente.'.tr, style: context.textTheme.bodyMedium),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminReportsProvider),
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

class _ReportCard extends ConsumerWidget {
  const _ReportCard({required this.report});

  final AdminReport report;

  Future<void> _decide(BuildContext context, WidgetRef ref, {required bool remove}) async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _DecisionSheet(report: report, remove: remove),
    );
    if (done ?? false) {
      ref
        ..invalidate(adminReportsProvider)
        ..invalidate(adminStatsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVideo = report.targetType == 'video';
    final isProfile = report.targetType == 'profile';
    final canOpen = (isVideo || isProfile) && report.targetStatus == 'active';

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
              _Badge(text: _targetLabels[report.targetType]?.tr ?? report.targetType),
              const SizedBox(width: AppSpacing.sm),
              if (report.reportsCount > 1)
                _Badge(text: '{n} signalements'.trArgs({'n': report.reportsCount}), color: AppColors.error),
              const Spacer(),
              Text(
                '${report.createdAt.day}/${report.createdAt.month}',
                style: context.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            report.reasons.map((r) => r.trServer).join(' · '),
            style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: !canOpen
                ? null
                : () => context.push(
                      isVideo
                          ? RouteNames.videoDetailPath(report.targetId)
                          : RouteNames.otherProfilePath(report.targetId),
                    ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
              ),
              child: Row(
                children: [
                  if (report.thumbnailUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          report.thumbnailUrl!,
                          width: 48,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(width: 48, height: 64),
                        ),
                      ),
                    )
                  else if (isVideo)
                    const Padding(
                      padding: EdgeInsets.only(right: AppSpacing.sm),
                      child: Icon(Icons.play_circle_outline, size: 40, color: AppColors.primary),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@${report.authorUsername ?? 'compte supprimé'.tr}',
                          style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if ((report.previewText ?? '').isNotEmpty)
                          Text(
                            report.previewText!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodySmall,
                          ),
                        if (canOpen)
                          Text(
                            isVideo ? 'Toucher pour voir la vidéo'.tr : 'Toucher pour voir le profil'.tr,
                            style: context.textTheme.bodySmall?.copyWith(color: AppColors.primary),
                          ),
                        if (report.targetStatus == 'deleted')
                          Text(
                            'Contenu supprimé par son auteur'.tr,
                            style: context.textTheme.bodySmall?.copyWith(color: AppColors.warning),
                          ),
                        if (report.targetStatus == 'removed' || report.targetStatus == 'banned')
                          Text(
                            'Déjà retiré'.tr,
                            style: context.textTheme.bodySmall?.copyWith(color: AppColors.warning),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Signalé par @{name}'.trArgs({'name': report.reporterUsername ?? 'compte supprimé'.tr}),
            style: context.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _decide(context, ref, remove: false),
                  child: Text('Garder'.tr),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: () => _decide(context, ref, remove: true),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                  child: Text(isProfile ? 'Bannir'.tr : 'Retirer'.tr),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecisionSheet extends ConsumerStatefulWidget {
  const _DecisionSheet({required this.report, required this.remove});

  final AdminReport report;
  final bool remove;

  @override
  ConsumerState<_DecisionSheet> createState() => _DecisionSheetState();
}

class _DecisionSheetState extends ConsumerState<_DecisionSheet> {
  late final TextEditingController _authorController;
  late final TextEditingController _reporterController;
  late bool _sendToAuthor;
  bool _sendToReporters = true;
  bool _busy = false;

  List<String> get _authorPresets {
    if (widget.report.targetType == 'profile') return AdminMessages.banReasons;
    if (!widget.remove) return AdminMessages.authorKept;
    return widget.report.targetType == 'comment'
        ? AdminMessages.authorRemovedComment
        : AdminMessages.authorRemovedVideo;
  }

  List<String> get _reporterPresets =>
      widget.remove ? AdminMessages.reporterRemoved : AdminMessages.reporterKept;

  @override
  void initState() {
    super.initState();
    _authorController = TextEditingController(text: _authorPresets.first);
    _reporterController = TextEditingController(text: _reporterPresets.first);
    // Contenu gardé : par défaut on ne dérange pas l'auteur.
    _sendToAuthor = widget.remove;
  }

  @override
  void dispose() {
    _authorController.dispose();
    _reporterController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final isBan = widget.remove && widget.report.targetType == 'profile';
    if (isBan && _authorController.text.trim().isEmpty) {
      context.showSnackBar('Indique la raison du bannissement.'.tr, isError: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(adminDataSourceProvider).resolveReport(
            reportId: widget.report.reportId,
            removeContent: widget.remove,
            // Pour un bannissement, le texte sert de raison (non envoyé).
            authorMessage: (_sendToAuthor || isBan) ? _authorController.text.trim() : null,
            reporterMessage: _sendToReporters ? _reporterController.text.trim() : null,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      context.showSnackBar(widget.remove ? 'Contenu retiré.'.tr : 'Contenu gardé.'.tr);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      context.showSnackBar(adminErrorText(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProfile = widget.report.targetType == 'profile';
    final title = widget.remove
        ? (isProfile ? 'Bannir ce joueur'.tr : 'Retirer ce contenu'.tr)
        : 'Garder ce contenu'.tr;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: context.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              _MessageBlock(
                label: isProfile && widget.remove
                    ? 'Raison du bannissement'.tr
                    : widget.report.authorUsername != null
                        ? 'Message à @{name}'.trArgs({'name': widget.report.authorUsername})
                        : 'Message à @l\'auteur'.tr,
                enabled: _sendToAuthor || (isProfile && widget.remove),
                showSwitch: !(isProfile && widget.remove),
                onEnabledChanged: (v) => setState(() => _sendToAuthor = v),
                presets: _authorPresets,
                controller: _authorController,
              ),
              const SizedBox(height: AppSpacing.md),
              _MessageBlock(
                label: widget.report.reportsCount > 1
                    ? 'Message aux {n} joueurs qui ont signalé'
                        .trArgs({'n': widget.report.reportsCount})
                    : 'Message au joueur qui a signalé'.tr,
                enabled: _sendToReporters,
                onEnabledChanged: (v) => setState(() => _sendToReporters = v),
                presets: _reporterPresets,
                controller: _reporterController,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _confirm,
                  style: widget.remove
                      ? FilledButton.styleFrom(backgroundColor: AppColors.error)
                      : null,
                  child: _busy
                      ? const SizedBox(width: 20, height: 20, child: AppLoader())
                      : Text(widget.remove ? (isProfile ? 'Bannir'.tr : 'Retirer'.tr) : 'Garder'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBlock extends StatelessWidget {
  const _MessageBlock({
    required this.label,
    required this.enabled,
    required this.onEnabledChanged,
    required this.presets,
    required this.controller,
    this.showSwitch = true,
  });

  final String label;
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final List<String> presets;
  final TextEditingController controller;
  final bool showSwitch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            ),
            if (showSwitch) Switch(value: enabled, onChanged: onEnabledChanged),
          ],
        ),
        if (enabled) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final preset in presets)
                ActionChip(
                  label: SizedBox(
                    width: 260,
                    child: Text(preset, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  onPressed: () => controller.text = preset,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(hintText: 'Message (modifiable)'.tr),
          ),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.color = AppColors.primary});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
