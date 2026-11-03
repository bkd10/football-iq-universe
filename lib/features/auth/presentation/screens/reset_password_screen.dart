import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../providers/auth_gate_provider.dart';

/// Retour du lien « mot de passe oublié » : choisir un nouveau mot de passe.
/// Affiché d'office par le routeur tant que `AuthGate` le demande.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final failure = await ref
        .read(accountSecurityServiceProvider)
        .updatePassword(_password.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure != null) {
      context.showSnackBar(failure.message, isError: true);
      return;
    }
    context.showSnackBar('Mot de passe changé !'.tr);
    ref.read(authGateProvider.notifier).finishReset();
  }

  @override
  Widget build(BuildContext context) {
    final gate = ref.watch(authGateProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: gate == AuthGate.resetLinkInvalid
                  ? _buildInvalid(context)
                  : _buildForm(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nouveau mot de passe'.tr, style: context.textTheme.displaySmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choisis ton nouveau mot de passe (8 caractères minimum).'.tr,
              style: context.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: 'Nouveau mot de passe'.tr,
              controller: _password,
              obscureText: true,
              prefixIcon: Icons.lock_outline,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: Validators.password,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Confirme le mot de passe'.tr,
              controller: _confirm,
              obscureText: true,
              prefixIcon: Icons.lock_outline,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              validator: (v) => Validators.confirmPassword(v, _password.text),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Enregistrer'.tr,
              isLoading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvalid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.link_off, size: 72),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Ce lien ne marche plus'.tr,
          style: context.textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          ('Le lien a expiré, a déjà servi, ou a été ouvert dans un autre '
                  'navigateur que celui de la demande. Sur iPhone, refais la '
                  'demande dans Safari puis ouvre le lien reçu.')
              .tr,
          style: context.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppPrimaryButton(
          label: 'Redemander un e-mail'.tr,
          onPressed: () {
            ref.read(authGateProvider.notifier).finishReset();
            context.go(RouteNames.forgotPassword);
          },
        ),
      ],
    );
  }
}
