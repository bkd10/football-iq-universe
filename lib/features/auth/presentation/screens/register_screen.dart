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
import '../../../legal/presentation/screens/legal_screen.dart';
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
  final _guardianController = TextEditingController();

  DateTime? _birthDate;
  bool _parentalAttestation = false;
  bool _termsAccepted = false;

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
    _guardianController.dispose();
    super.dispose();
  }

  /// Âge en années révolues (null tant que la date n'est pas choisie).
  int? get _age {
    final birth = _birthDate;
    if (birth == null) return null;
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  bool get _isMinor => (_age ?? 99) < AppConstants.parentalConsentUnderAge;

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 16, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Ta date de naissance'.tr,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  /// Règles d'âge, mêmes que le serveur (`handle_new_user`). Renvoie le
  /// message à afficher, ou `null` si tout est bon.
  String? _ageProblem() {
    final age = _age;
    if (age == null) return 'Indique ta date de naissance.'.tr;
    if (age < AppConstants.minimumAge) {
      return 'Il faut avoir au moins 13 ans pour s\'inscrire.'.tr;
    }
    if (_accountType != 'player' && age < 18) {
      return 'Les comptes recruteur et marque sont réservés aux majeurs.'.tr;
    }
    if (_isMinor && !_parentalAttestation) {
      return 'Coche l\'attestation d\'accord parental pour continuer.'.tr;
    }
    if (!_termsAccepted) {
      return 'Accepte les conditions d\'utilisation pour continuer.'.tr;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final problem = _ageProblem();
    if (problem != null) {
      context.showSnackBar(problem, isError: true);
      return;
    }

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
          birthDate: _birthDate,
          guardianEmail: _isMinor ? _guardianController.text.trim() : null,
          parentalAttestation: _isMinor && _parentalAttestation,
          termsAccepted: _termsAccepted,
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
                _BirthDateField(
                  value: _birthDate,
                  onTap: _pickBirthDate,
                  error: (_age != null && _age! < AppConstants.minimumAge)
                      ? 'Il faut avoir au moins 13 ans pour s\'inscrire.'.tr
                      : null,
                ),
                if (_isMinor && (_age ?? 0) >= AppConstants.minimumAge) ...[
                  const SizedBox(height: AppSpacing.md),
                  _MinorNotice(
                    guardianController: _guardianController,
                    ownEmail: () => _emailController.text.trim(),
                    attested: _parentalAttestation,
                    onAttestedChanged: (v) => setState(() => _parentalAttestation = v),
                  ),
                ],
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
                const SizedBox(height: AppSpacing.md),
                _TermsCheckbox(
                  value: _termsAccepted,
                  onChanged: (v) => setState(() => _termsAccepted = v),
                ),
                const SizedBox(height: AppSpacing.md),
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

class _BirthDateField extends StatelessWidget {
  const _BirthDateField({required this.value, required this.onTap, this.error});

  final DateTime? value;
  final VoidCallback onTap;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final v = value;
    String two(int n) => n.toString().padLeft(2, '0');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date de naissance'.tr,
          prefixIcon: const Icon(Icons.cake_outlined),
          errorText: error,
        ),
        isEmpty: v == null,
        child: Text(v == null ? '' : '${two(v.day)}/${two(v.month)}/${v.year}'),
      ),
    );
  }
}

/// Message d'ouverture pour les moins de 18 ans : accord des parents
/// obligatoire, e-mail d'un parent.
class _MinorNotice extends StatelessWidget {
  const _MinorNotice({
    required this.guardianController,
    required this.ownEmail,
    required this.attested,
    required this.onAttestedChanged,
  });

  final TextEditingController guardianController;
  final String Function() ownEmail;
  final bool attested;
  final ValueChanged<bool> onAttestedChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.family_restroom, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Tu as moins de 18 ans'.tr,
                  style: context.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            ('Pour utiliser Football IQ, tu dois avoir l\'autorisation de tes '
                    'parents (ou de ton tuteur légal). Montre-leur les conditions '
                    'd\'utilisation. Ils seront toujours prévenus avant qu\'un '
                    'recruteur te contacte, et les achats demandent aussi leur '
                    'accord.')
                .tr,
            style: context.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'E-mail d\'un parent'.tr,
            controller: guardianController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.alternate_email,
            validator: (value) {
              final base = Validators.email(value);
              if (base != null) return base;
              if (value!.trim().toLowerCase() == ownEmail().toLowerCase()) {
                return 'Mets l\'e-mail de ton parent, pas le tien.'.tr;
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: attested,
            onChanged: (v) => onAttestedChanged(v ?? false),
            title: Text(
              ('J\'atteste que mes parents (ou mon tuteur légal) m\'autorisent '
                      'à utiliser Football IQ et ont lu les conditions.')
                  .tr,
              style: context.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          title: Text(
            ('J\'accepte les conditions d\'utilisation et les règles des '
                    'Ballons, et j\'ai lu la politique de confidentialité.')
                .tr,
            style: context.textTheme.bodyMedium,
          ),
        ),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final doc in LegalDoc.values)
              TextButton(
                onPressed: () => context.push(RouteNames.legalPath(doc.slug)),
                child: Text(doc.title),
              ),
          ],
        ),
      ],
    );
  }
}
