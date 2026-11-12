import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/services/browser/browser.dart';
import '../../../legal/data/legal_info.dart';
import '../../../legal/presentation/screens/legal_screen.dart';
import '../../../../shared/providers/supabase_provider.dart';

/// Écran "Settings" (PARTIE 9.2, écran 33) : compte, sécurité, protection
/// des mineurs, documents légaux.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final email = ref.watch(supabaseClientProvider).auth.currentUser?.email;

    return Scaffold(
      appBar: AppBar(title: Text('Réglages'.tr)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
            child: Text(
              'COMPTE'.tr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: Text(
              profileAsync.valueOrNull?.username != null
                  ? '@${profileAsync.valueOrNull!.username}'
                  : 'Nom d\'utilisateur'.tr,
            ),
            subtitle: email != null ? Text(email) : null,
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text('Modifier le profil'.tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.editProfile),
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text('Mot de passe et double authentification'.tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.securitySettings),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text('Messages'.tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.inbox),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
            child: Text(
              'PROTECTION'.tr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text('Protection des mineurs'.tr),
            subtitle: Text(
              ('Aucune géolocalisation précise publique. Le contact par un '
                      'recruteur est toujours médié pour les moins de 18 ans.')
                  .tr,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: Text('J\'ai un code tuteur'.tr),
            subtitle: Text('Pour approuver ou refuser un contact recruteur.'.tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.guardianApprovalEntry),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
            child: Text(
              'INFORMATIONS LÉGALES'.tr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1),
            ),
          ),
          for (final doc in LegalDoc.values)
            ListTile(
              leading: Icon(doc.icon),
              title: Text(doc.title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RouteNames.legalPath(doc.slug)),
            ),
          ListTile(
            leading: const Icon(Icons.folder_shared_outlined),
            title: Text('Mes données'.tr),
            subtitle: Text('Demander une copie, une correction ou la suppression.'.tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showMyData(context, email),
          ),
          ListTile(
            leading: const Icon(Icons.copyright_outlined),
            title: Text('Licences'.tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Football IQ Universe',
            ),
          ),
          if (profileAsync.valueOrNull?.role == 'admin') ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: Text('Administration'.tr),
              subtitle: Text('Statistiques, signalements, joueurs, défis officiels.'.tr),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RouteNames.adminHome),
            ),
          ],
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: Text('Se déconnecter'.tr, style: const TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.error),
              ),
              onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: TextButton(
              onPressed: () => _confirmDeleteAccount(context, ref),
              child: Text(
                'Supprimer mon compte'.tr,
                style: const TextStyle(color: AppColors.error, decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Exercice des droits RGPD : suppression directe dans l'appli, le reste
  /// par e-mail (réponse sous un mois).
  Future<void> _showMyData(BuildContext context, String? accountEmail) {
    const contact = LegalInfo.contactEmail;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Mes données'.tr),
        content: Text(
          ('Pour supprimer ton compte et toutes tes données, utilise « Supprimer '
                  'mon compte » en bas de cette page. Pour recevoir une copie de tes '
                  'données, en corriger ou t\'opposer à leur utilisation, écris-nous '
                  'depuis l\'adresse de ton compte : nous répondons sous un mois.')
              .tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Fermer'.tr),
          ),
          if (contact != null)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                final subject = Uri.encodeComponent('Mes données – Football IQ');
                final body = Uri.encodeComponent(accountEmail ?? '');
                openExternalLink('mailto:$contact?subject=$subject&body=$body');
              },
              child: Text('Écrire un e-mail'.tr),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Supprimer ton compte ?'.tr),
        content: Text(
          ('Cette action est définitive. Ton profil, tes vidéos, tes défis et '
                  'ton historique seront supprimés pour de bon — impossible de '
                  'revenir en arrière.')
              .tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Annuler'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Supprimer'.tr, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final ok = await ref.read(authControllerProvider.notifier).deleteAccount();
    if (!context.mounted) return;

    if (ok) {
      context.go(RouteNames.login);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La suppression a échoué. Réessaie plus tard.'.tr)),
      );
    }
  }
}
