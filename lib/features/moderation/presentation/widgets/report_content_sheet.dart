import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../safety/presentation/providers/safety_providers.dart';

const _reasons = [
  'Contenu inapproprié',
  'Harcèlement ou intimidation',
  'Fausse identité',
  'Spam',
  'Concerne un mineur en danger',
  'Autre',
];

/// Bouton "Signaler" réutilisable sur une vidéo, un commentaire, un profil
/// ou un message privé (`targetType` : video, comment, profile, message) —
/// ouvre une feuille de sélection de motif puis appelle `report_content`
/// (`20260101000037_minor_safety.sql`), qui vérifie que le contenu existe.
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
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _selectedReason;
    if (reason == null || _submitting) return;
    setState(() => _submitting = true);

    String? error;
    try {
      await ref.read(safetyDataSourceProvider).report(
            targetType: widget.targetType,
            targetId: widget.targetId,
            reason: reason,
            details: _details.text,
          );
    } on Failure catch (f) {
      error = f.message;
    } catch (_) {
      error = 'Échec du signalement.'.tr;
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error == null) {
      Navigator.of(context).pop();
      context.showSnackBar('Signalement envoyé — merci, on va vérifier.'.tr);
    } else {
      context.showSnackBar(error, isError: true);
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
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Signaler ce contenu'.tr, style: context.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Un modérateur va vérifier ce contenu — ton signalement reste confidentiel.'.tr,
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
                      title: Text(reason.tr),
                      value: reason,
                      activeColor: AppColors.primary,
                    ),
                  )
                  .toList(),
            ),
          ),
          TextField(
            controller: _details,
            maxLength: 1000,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(hintText: 'Précisions (facultatif)'.tr),
          ),
          Text(
            'En cas de danger immédiat, appelle le 999 (Royaume-Uni) ou le 112.'.tr,
            style: context.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: 'Envoyer le signalement'.tr,
            isLoading: _submitting,
            onPressed: _selectedReason == null ? null : _submit,
          ),
        ],
      ),
      ),
    );
  }
}
