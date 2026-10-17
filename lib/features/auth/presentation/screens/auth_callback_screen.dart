import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// Point de retour du lien de confirmation d'e-mail sur le web
/// (`RouteNames.authCallback`). Supabase (`authFlowType: pkce`, voir
/// `supabase_config.dart`) redirige ici avec soit `?code=...` (lien valide,
/// échangé automatiquement contre une session par `detectSessionInUri`
/// pendant `Supabase.initialize()` dans `main.dart`, avant que cet écran ne
/// s'affiche), soit `?error=...&error_description=...` (lien expiré ou déjà
/// utilisé).
///
/// Cet écran n'a lui-même AUCUNE logique de session : purement visuel, comme
/// `SplashScreen`. Toute la décision (entrer dans l'app une fois la session
/// établie, ou rester ici en cas d'erreur) est prise par le `redirect` de
/// GoRouter dans `app_router.dart`, qui réagit à `authStateProvider`.
class AuthCallbackScreen extends StatelessWidget {
  const AuthCallbackScreen({this.errorDescription, super.key});

  final String? errorDescription;

  @override
  Widget build(BuildContext context) {
    final hasError = errorDescription != null && errorDescription!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: hasError
                  ? [
                      const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Lien invalide ou expiré'.tr,
                        style: context.textTheme.displaySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        errorDescription!,
                        style: context.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TextButton(
                        onPressed: () => context.go(RouteNames.login),
                        child: Text('Retour à la connexion'.tr),
                      ),
                    ]
                  : [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Confirmation en cours…'.tr,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        AppConstants.appName,
                        textAlign: TextAlign.center,
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
