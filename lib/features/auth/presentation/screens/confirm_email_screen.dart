import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../providers/auth_providers.dart';

/// Écran affiché juste après l'inscription quand Supabase exige une
/// confirmation d'e-mail (aucune session créée tant que le lien n'est pas
/// cliqué), et depuis l'écran de connexion si un compte existant n'est
/// toujours pas confirmé.
///
/// Volontairement affiché plutôt qu'un simple retour silencieux à l'écran
/// de connexion : sans cet écran, l'inscription semblait échouer alors
/// qu'elle avait réussi — il ne manquait que la confirmation.
///
/// Aucune navigation manuelle n'est nécessaire une fois le lien cliqué : le
/// `redirect` de GoRouter réagit déjà à `authStateProvider` et fait entrer
/// l'utilisateur dans l'app dès qu'une session existe (voir `app_router.dart`).
class ConfirmEmailScreen extends ConsumerStatefulWidget {
  const ConfirmEmailScreen({required this.email, super.key});

  final String email;

  @override
  ConsumerState<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends ConsumerState<ConfirmEmailScreen> {
  bool _resending = false;

  Future<void> _resend() async {
    setState(() => _resending = true);
    final result =
        await ref.read(authRepositoryProvider).resendConfirmationEmail(widget.email);
    if (!mounted) return;
    setState(() => _resending = false);
    result.fold(
      (failure) => context.showSnackBar(failure.message, isError: true),
      (_) => context.showSnackBar('E-mail renvoyé — vérifie ta boîte de réception.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 72,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Confirme ton e-mail',
                  style: context.textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'On a envoyé un lien de confirmation à ${widget.email}. '
                  'Clique dessus pour activer ton compte — cette page passera '
                  'automatiquement à l\'app une fois confirmé.',
                  style: context.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: 'Renvoyer l\'e-mail',
                  isLoading: _resending,
                  onPressed: _resend,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => context.go(RouteNames.login),
                  child: const Text('Retour à la connexion'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
