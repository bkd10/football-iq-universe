import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../providers/auth_gate_provider.dart';
import '../providers/auth_providers.dart';

/// Champ « code à 6 chiffres » partagé par la connexion et l'activation.
class MfaCodeField extends StatelessWidget {
  const MfaCodeField({required this.controller, this.onSubmitted, super.key});

  final TextEditingController controller;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: context.textTheme.headlineMedium?.copyWith(letterSpacing: 8),
      decoration: InputDecoration(labelText: 'Code à 6 chiffres'.tr, counterText: ''),
      onSubmitted: (_) => onSubmitted?.call(),
    );
  }
}

/// Connexion d'un compte protégé : le mot de passe est bon, il reste le
/// code de l'appli d'authentification. Imposé par le routeur (`AuthGate`).
class MfaVerifyScreen extends ConsumerStatefulWidget {
  const MfaVerifyScreen({super.key});

  @override
  ConsumerState<MfaVerifyScreen> createState() => _MfaVerifyScreenState();
}

class _MfaVerifyScreenState extends ConsumerState<MfaVerifyScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code.text.trim();
    if (code.length != 6) {
      context.showSnackBar('Entre les 6 chiffres du code.'.tr, isError: true);
      return;
    }
    setState(() => _busy = true);
    final failure = await ref.read(accountSecurityServiceProvider).verifyLoginCode(code);
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) {
      _code.clear();
      context.showSnackBar(failure.message, isError: true);
      return;
    }
    ref.read(authGateProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.shield_outlined, size: 64),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Double authentification'.tr,
                    style: context.textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Ouvre ton appli d\'authentification et entre le code affiché pour Football IQ.'.tr,
                    style: context.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  MfaCodeField(controller: _code, onSubmitted: _submit),
                  const SizedBox(height: AppSpacing.lg),
                  AppPrimaryButton(
                    label: 'Valider'.tr,
                    isLoading: _busy,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => ref.read(authControllerProvider.notifier).signOut(),
                    child: Text('Se déconnecter'.tr),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
