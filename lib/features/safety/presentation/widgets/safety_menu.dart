import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../videos/presentation/providers/video_providers.dart';
import '../../../moderation/presentation/widgets/report_content_sheet.dart';
import '../providers/safety_providers.dart';

/// Menu « Signaler / Bloquer », le même partout : vidéo, commentaire,
/// profil, message privé. [authorId] est la personne à bloquer (auteur du
/// contenu) ; rien à bloquer si c'est soi-même.
Future<void> showSafetyMenu(
  BuildContext context,
  WidgetRef ref, {
  required String targetType,
  required String targetId,
  required String? authorId,
  String? authorName,
}) async {
  final myId = ref.read(supabaseClientProvider).auth.currentUser?.id;
  final canBlock = authorId != null && authorId != myId;
  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: AppColors.warning),
            title: Text('Signaler'.tr),
            subtitle: Text('Un modérateur vérifie chaque signalement.'.tr),
            onTap: () => Navigator.of(sheetContext).pop('report'),
          ),
          if (canBlock)
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.error),
              title: Text(
                authorName != null ? 'Bloquer @{name}'.trArgs({'name': authorName}) : 'Bloquer ce joueur'.tr,
              ),
              subtitle: Text('Il ne pourra plus voir tes vidéos, te commenter ni t\'écrire.'.tr),
              onTap: () => Navigator.of(sheetContext).pop('block'),
            ),
        ],
      ),
    ),
  );
  if (!context.mounted || choice == null) return;
  if (choice == 'report') {
    await showReportContentSheet(context, targetType: targetType, targetId: targetId);
  } else if (choice == 'block' && authorId != null) {
    await confirmBlock(context, ref, userId: authorId, username: authorName);
  }
}

/// Demande confirmation puis bloque. Renvoie vrai si le joueur est bloqué.
Future<bool> confirmBlock(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  String? username,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(username != null ? 'Bloquer @{name} ?'.trArgs({'name': username}) : 'Bloquer ce joueur ?'.tr),
      content: Text(
        ('Il ne verra plus tes vidéos ni ton profil, ne pourra plus te '
                'commenter, te suivre ni t\'écrire. Il n\'est pas prévenu. Tu peux '
                'le débloquer dans Réglages > Sécurité et confidentialité.')
            .tr,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text('Annuler'.tr)),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text('Bloquer'.tr, style: const TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return false;
  try {
    await ref.read(safetyDataSourceProvider).block(userId);
  } on Failure catch (f) {
    if (context.mounted) context.showSnackBar(f.message, isError: true);
    return false;
  }
  ref
    ..invalidate(myBlocksProvider)
    ..invalidate(publicProfileProvider(userId))
    ..invalidate(feedControllerProvider);
  if (context.mounted) context.showSnackBar('Joueur bloqué.'.tr);
  return true;
}
