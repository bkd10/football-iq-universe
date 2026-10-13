import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../providers/moderation_providers.dart';

const _reasons = [
  'Contenu inapproprié',
  'Harcèlement ou intimidation',
  'Fausse identité',
  'Spam',
  'Concerne un mineur en danger',
  'Autre',
];

/// Bouton "Signaler" réutilisable sur une vidéo/un profil — ouvre une
/// feuille de sélection de motif puis insère dans `content_reports`. Voir
/// `20260101000015_hardening.sql`.
Future<void> showReportContentSheet(
  BuildContext context, {
  required String targetType,
  required String targetId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
    ),
    builder: (_) => _ReportContentSheet(targetType: targetType, targetId: targetId),
  );
}

class _ReportContentSheet extends ConsumerStatefulWidget {
  const _ReportContentSheet({required this.targetType, required this.targetId});

  final String targetType;
  final String targetId;

  @override
  ConsumerState<_ReportContentSheet> createState() => _ReportContentSheetState();
}

class _ReportContentSheetState extends ConsumerState<_ReportContentSheet> {
  String? _selectedReason;
  bool _submitting = false;

  Future<void> _submit() async {
    final reason = _selectedReason;
    if (reason == null || _submitting) return;
    setState(() => _submitting = true);

    final ok = await ref.read(moderationActionsControllerProvider.notifier).reportContent(
          targetType: widget.targetType,
          targetId: widget.targetId,
          reason: reason,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.of(context).pop();
      context.showSnackBar('Signalement envoyé — merci, on va vérifier.');
    } else {
      final failure = ref.read(moderationActionsControllerProvider).error;
      context.showSnackBar(
        failure is Failure ? failure.message : 'Échec du signalement.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Signaler ce contenu', style: context.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Un modérateur va vérifier ce contenu — ton signalement reste confidentiel.',
            style: context.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          RadioGroup<String>(
            groupValue: _selectedReason,
            onChanged: (value) => setState(() => _selectedReason = value),
            child: Column(
              children: _reasons
                  .map(
                    (reason) => RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(reason),
                      value: reason,
                      activeColor: AppColors.primary,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: 'Envoyer le signalement',
            isLoading: _submitting,
            onPressed: _selectedReason == null ? null : _submit,
          ),
        ],
      ),
    );
  }
}
