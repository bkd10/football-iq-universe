import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../providers/safety_providers.dart';

/// Lien que le parent ouvre pour répondre (routage par « # » sur le web).
String parentConsentLink(String token) => '${Uri.base.origin}/#/parent/$token';

/// Bandeau affiché en haut de l'appli tant qu'un compte sous l'âge de
/// consentement attend l'accord du parent : le joueur peut regarder, mais
/// le serveur refuse publications, commentaires, messages, votes et achats.
/// L'e-mail au parent part automatiquement une fois, puis sur demande.
class ParentPendingBanner extends ConsumerStatefulWidget {
  const ParentPendingBanner({super.key});

  @override
  ConsumerState<ParentPendingBanner> createState() => _ParentPendingBannerState();
}

class _ParentPendingBannerState extends ConsumerState<ParentPendingBanner> {
  static bool _autoSent = false;
  bool _busy = false;

  Future<void> _send({bool silent = false}) async {
    setState(() => _busy = true);
    try {
      final r = await ref.read(safetyDataSourceProvider).sendParentSignupEmail();
      if (!mounted) return;
      if (r.sent) {
        if (!silent) {
          context.showSnackBar('E-mail envoyé à ton parent ({email}).'.trArgs({'email': r.email ?? ''}));
        }
      } else if (r.link != null && !silent) {
        await Clipboard.setData(ClipboardData(text: r.link!));
        if (mounted) {
          context.showSnackBar('Lien copié. Envoie-le à ton parent : il reste valable quelques jours.'.tr);
        }
      }
    } on Failure catch (f) {
      if (mounted && !silent) context.showSnackBar(f.message, isError: true);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(mySafetyNowProvider);
    if (!s.parentPending) return const SizedBox.shrink();
    if (!_autoSent && !s.parentDeclined) {
      _autoSent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(silent: true));
    }
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        color: AppColors.primary.withValues(alpha: 0.15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.parentDeclined
                  ? 'Ton parent n\'a pas validé ton compte. Tu peux le supprimer dans Réglages.'.tr
                  : ('Ton compte attend l\'accord de ton parent. En attendant, tu peux '
                          'regarder les vidéos, mais pas publier, commenter, écrire, voter '
                          'ni acheter.')
                      .tr,
              style: context.textTheme.bodySmall,
            ),
            if (!s.parentDeclined)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _busy ? null : _send,
                  child: Text('Renvoyer l\'e-mail à mon parent'.tr),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
