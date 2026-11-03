import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/browser/browser.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../data/services/account_security_service.dart';
import '../providers/auth_gate_provider.dart';
import 'mfa_verify_screen.dart';

/// Facteur TOTP vérifié du compte (`null` = double authentification
/// désactivée).
final _totpFactorProvider = FutureProvider.autoDispose<supa.Factor?>(
  (ref) => ref.watch(accountSecurityServiceProvider).verifiedTotpFactor(),
);

/// Réglages > Mot de passe et double authentification.
class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factor = ref.watch(_totpFactorProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Sécurité du compte'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('DOUBLE AUTHENTIFICATION'.tr, style: _sectionStyle(context)),
          const SizedBox(height: AppSpacing.sm),
          factor.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Text('Une erreur inattendue est survenue.'.tr),
            data: (f) => f == null
                ? const _EnableTotp()
                : _TotpEnabled(factorId: f.id),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Text('MOT DE PASSE'.tr, style: _sectionStyle(context)),
          const SizedBox(height: AppSpacing.sm),
          const _ChangePassword(),
        ],
      ),
    );
  }
}

TextStyle? _sectionStyle(BuildContext context) =>
    context.textTheme.bodySmall?.copyWith(letterSpacing: 1);

class _TotpEnabled extends ConsumerStatefulWidget {
  const _TotpEnabled({required this.factorId});

  final String factorId;

  @override
  ConsumerState<_TotpEnabled> createState() => _TotpEnabledState();
}

class _TotpEnabledState extends ConsumerState<_TotpEnabled> {
  bool _busy = false;

  Future<void> _disable() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Désactiver la double authentification ?'.tr),
        content: Text('Ton compte sera protégé seulement par ton mot de passe.'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Désactiver'.tr),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final failure = await ref.read(accountSecurityServiceProvider).disableTotp(widget.factorId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) {
      context.showSnackBar(failure.message, isError: true);
      return;
    }
    context.showSnackBar('Double authentification désactivée.'.tr);
    ref.invalidate(_totpFactorProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.verified_user, color: Colors.green),
          title: Text('Activée'.tr),
          subtitle: Text('Un code de ton appli est demandé à chaque connexion.'.tr),
        ),
        OutlinedButton(
          onPressed: _busy ? null : _disable,
          child: Text('Désactiver'.tr),
        ),
      ],
    );
  }
}

class _EnableTotp extends ConsumerStatefulWidget {
  const _EnableTotp();

  @override
  ConsumerState<_EnableTotp> createState() => _EnableTotpState();
}

class _EnableTotpState extends ConsumerState<_EnableTotp> {
  TotpEnrollment? _enrollment;
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    final (enrollment, failure) =
        await ref.read(accountSecurityServiceProvider).startTotpEnrollment();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _enrollment = enrollment;
    });
    if (failure != null) context.showSnackBar(failure.message, isError: true);
  }

  Future<void> _verify() async {
    final enrollment = _enrollment;
    if (enrollment == null) return;
    final code = _code.text.trim();
    if (code.length != 6) {
      context.showSnackBar('Entre les 6 chiffres du code.'.tr, isError: true);
      return;
    }
    setState(() => _busy = true);
    final failure = await ref
        .read(accountSecurityServiceProvider)
        .verifyCode(factorId: enrollment.factorId, code: code);
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) {
      _code.clear();
      context.showSnackBar(failure.message, isError: true);
      return;
    }
    context.showSnackBar('Double authentification activée !'.tr);
    ref.invalidate(_totpFactorProvider);
  }

  @override
  Widget build(BuildContext context) {
    final enrollment = _enrollment;
    if (enrollment == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ('Protège ton compte : en plus du mot de passe, un code à 6 '
                    'chiffres de ton appli d\'authentification (Google '
                    'Authenticator, Microsoft Authenticator…) sera demandé à '
                    'chaque connexion.')
                .tr,
            style: context.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: 'Activer'.tr,
            isLoading: _busy,
            onPressed: _start,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '1. Installe Google Authenticator (ou une autre appli de codes).'.tr,
          style: context.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '2. Ajoute Football IQ : touche « Ouvrir l\'appli de codes », ou copie la clé et colle-la dans l\'appli.'.tr,
          style: context.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          icon: const Icon(Icons.open_in_new),
          label: Text('Ouvrir l\'appli de codes'.tr),
          onPressed: () {
            if (!openExternalLink(enrollment.uri)) {
              context.showSnackBar('Copie la clé à la place.'.tr, isError: true);
            }
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  enrollment.secret,
                  style: const TextStyle(fontFamily: 'monospace', letterSpacing: 1),
                ),
              ),
              IconButton(
                tooltip: 'Copier la clé'.tr,
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: enrollment.secret));
                  context.showSnackBar('Clé copiée.'.tr);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '3. Entre le code à 6 chiffres affiché par l\'appli.'.tr,
          style: context.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        MfaCodeField(controller: _code, onSubmitted: _verify),
        const SizedBox(height: AppSpacing.md),
        AppPrimaryButton(
          label: 'Valider'.tr,
          isLoading: _busy,
          onPressed: _verify,
        ),
      ],
    );
  }
}

class _ChangePassword extends ConsumerStatefulWidget {
  const _ChangePassword();

  @override
  ConsumerState<_ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends ConsumerState<_ChangePassword> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final failure = await ref.read(accountSecurityServiceProvider).updatePassword(_password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) {
      context.showSnackBar(failure.message, isError: true);
      return;
    }
    _password.clear();
    _confirm.clear();
    context.showSnackBar('Mot de passe changé !'.tr);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Nouveau mot de passe'.tr,
            controller: _password,
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            autofillHints: const [AutofillHints.newPassword],
            validator: Validators.password,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Confirme le mot de passe'.tr,
            controller: _confirm,
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            autofillHints: const [AutofillHints.newPassword],
            validator: (v) => Validators.confirmPassword(v, _password.text),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: 'Changer le mot de passe'.tr,
            isLoading: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
