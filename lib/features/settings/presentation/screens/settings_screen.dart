import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../shared/providers/supabase_provider.dart';

/// Écran "Settings" (PARTIE 9.2, écran 33). Volontairement minimal pour le
/// MVP — pas de liens vers des CGU/politique de confidentialité qui
/// n'existent pas encore, pour ne rien afficher qui ne fonctionne pas
/// réellement.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final email = ref.watch(supabaseClientProvider).auth.currentUser?.email;

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
            child: Text(
              'COMPTE',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: Text(
              profileAsync.valueOrNull?.username != null
                  ? '@${profileAsync.valueOrNull!.username}'
                  : 'Nom d\'utilisateur',
            ),
            subtitle: email != null ? Text(email) : null,
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Modifier le profil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.editProfile),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('Messages'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.inbox),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
            child: Text(
              'PROTECTION',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('Protection des mineurs'),
            subtitle: Text(
              'Aucune géolocalisation précise publique. Le contact par un '
              'recruteur vérifié est toujours médié pour les moins de 18 ans.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('J\'ai un code tuteur'),
            subtitle: const Text('Pour approuver ou refuser un contact recruteur.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.guardianApprovalEntry),
          ),
          if (profileAsync.valueOrNull?.role == 'admin') ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Administration'),
              subtitle: const Text('Statistiques, signalements, joueurs, défis officiels.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RouteNames.adminHome),
            ),
          ],
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Se déconnecter', style: TextStyle(color: AppColors.error)),
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
              child: const Text(
                'Supprimer mon compte',
                style: TextStyle(color: AppColors.error, decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ton compte ?'),
        content: const Text(
          'Cette action est définitive. Ton profil, tes vidéos, tes défis et '
          'ton historique seront supprimés pour de bon — impossible de '
          'revenir en arrière.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
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
        const SnackBar(content: Text('La suppression a échoué. Réessaie plus tard.')),
      );
    }
  }
}
