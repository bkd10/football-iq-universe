import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/string_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../providers/auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _countryController = TextEditingController();

  String? _position;
  String _preferredFoot = 'droit';
  // player, scout, brand
  String _accountType = 'player';

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final isPlayer = _accountType == 'player';
    final email = _emailController.text.trim();
    final outcome = await ref.read(authControllerProvider.notifier).signUp(
          email: email,
          password: _passwordController.text,
          username: _usernameController.text.trim(),
          country: _countryController.text.trim().isEmpty
              ? null
              : _countryController.text.trim(),
          position: isPlayer ? _position : null,
          preferredFoot: isPlayer ? _preferredFoot : null,
          asScout: _accountType == 'scout',
          asBrand: _accountType == 'brand',
        );

    if (!mounted) return;
    switch (outcome) {
      case SignUpOutcome.success:
        context.showSnackBar(
          'Bienvenue sur {app} !'.trArgs({'app': AppConstants.appName}),
        );
      case SignUpOutcome.needsEmailConfirmation:
        // Aucune session n'existe encore : ne JAMAIS compter sur le
        // `redirect` de GoRouter ici (il n'a rien à voir avec une
        // navigation "logged out" par défaut), on pousse explicitement
        // vers l'écran d'attente de confirmation.
        context.go(RouteNames.confirmEmail, extra: email);
      case SignUpOutcome.failure:
        break; // déjà affiché via ref.listen (voir build()).
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          final message = error is Failure ? error.message : 'Erreur inconnue.'.tr;
          context.showSnackBar(message, isError: true);
        },
      );
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Crée ton profil'.tr, style: context.textTheme.displaySmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Gratuit, sans engagement. Le talent parle, pas les followers.'.tr,
                  style: context.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: 'Pseudo'.tr,
                  controller: _usernameController,
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: Validators.username,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Email'.tr,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.alternate_email,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Mot de passe'.tr,
                  controller: _passwordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Confirme le mot de passe'.tr,
                  controller: _confirmPasswordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  textInputAction: TextInputAction.next,
                  validator: (value) => Validators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Pays (optionnel)'.tr,
                  controller: _countryController,
                  prefixIcon: Icons.public,
                  textInputAction: TextInputAction.next,
                ),
                if (_accountType == 'player') ...[
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _position,
                    decoration: InputDecoration(labelText: 'Poste'.tr),
                    items: AppConstants.playerPositions
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.capitalize.tr),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _position = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _preferredFoot,
                    decoration: InputDecoration(labelText: 'Pied fort'.tr),
                    items: AppConstants.preferredFeet
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(f.fromSnakeCaseToTitle.tr),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _preferredFoot = value);
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Type de compte'.tr,
                  style: context.textTheme.bodySmall?.copyWith(letterSpacing: 1),
                ),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'player', label: Text('Joueur'.tr)),
                    ButtonSegment(value: 'scout', label: Text('Recruteur'.tr)),
                    ButtonSegment(value: 'brand', label: Text('Marque'.tr)),
                  ],
                  selected: {_accountType},
                  onSelectionChanged: (value) =>
                      setState(() => _accountType = value.first),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  switch (_accountType) {
                    'scout' => ('Compte pro pour repérer des joueurs et les '
                            'contacter (abonnement requis).')
                        .tr,
                    'brand' => ('Compte marque pour publier des Défis '
                            'Sponsorisés avec un vrai prix (vérification '
                            'manuelle requise avant publication).')
                        .tr,
                    _ => ('Compte joueur classique : vidéos, défis, '
                            'classement.')
                        .tr,
                  },
                  style: context.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppPrimaryButton(
                  label: switch (_accountType) {
                    'scout' => 'Créer mon compte recruteur'.tr,
                    'brand' => 'Créer mon compte marque'.tr,
                    _ => 'Créer mon compte'.tr,
                  },
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
