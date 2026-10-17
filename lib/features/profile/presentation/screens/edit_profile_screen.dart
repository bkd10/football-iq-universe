import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/string_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Écran "Edit Profile" (PARTIE 9.2, écran 24) — seuls les champs
/// d'identité déclarative sont modifiables ici ; Ballons/Stars/Football IQ
/// restent en lecture seule partout (voir `UpdateProfile`).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _countryController;
  late final TextEditingController _cityController;
  late final TextEditingController _guardianNameController;
  late final TextEditingController _guardianEmailController;
  String? _position;
  String _preferredFoot = 'droit';
  bool _initialized = false;
  bool _guardianInitialized = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _countryController = TextEditingController();
    _cityController = TextEditingController();
    _guardianNameController = TextEditingController();
    _guardianEmailController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _guardianNameController.dispose();
    _guardianEmailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authControllerProvider.notifier).updateProfile(
          displayName: _displayNameController.text.trim(),
          bio: _bioController.text.trim(),
          country: _countryController.text.trim(),
          city: _cityController.text.trim(),
          position: _position,
          preferredFoot: _preferredFoot,
        );
    if (!mounted) return;
    if (!success) {
      context.showSnackBar('Échec de la mise à jour.'.tr, isError: true);
      return;
    }

    final guardianEmail = _guardianEmailController.text.trim();
    if (guardianEmail.isNotEmpty) {
      final guardianSuccess =
          await ref.read(authControllerProvider.notifier).updateGuardianContact(
                guardianName: _guardianNameController.text.trim(),
                guardianEmail: guardianEmail,
              );
      if (!mounted) return;
      if (!guardianSuccess) {
        context.showSnackBar(
          'Profil mis à jour, mais échec de l\'enregistrement du contact tuteur.'.tr,
          isError: true,
        );
        return;
      }
    }

    context.showSnackBar('Profil mis à jour.'.tr);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final isLoading = ref.watch(authControllerProvider).isLoading;

    ref.listen(currentProfileProvider, (previous, next) {
      final profile = next.valueOrNull;
      if (profile == null || _initialized) return;
      _initialized = true;
      _displayNameController.text = profile.displayName ?? '';
      _bioController.text = profile.bio;
      _countryController.text = profile.country ?? '';
      _cityController.text = profile.city ?? '';
      _position = profile.position;
      _preferredFoot = profile.preferredFoot;
    });
    ref.listen(myGuardianContactProvider, (previous, next) {
      final contact = next.valueOrNull;
      if (contact == null || _guardianInitialized) return;
      _guardianInitialized = true;
      _guardianNameController.text = contact.guardianName ?? '';
      _guardianEmailController.text = contact.guardianEmail;
    });

    return Scaffold(
      appBar: AppBar(title: Text('Modifier le profil'.tr)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: 'Nom affiché'.tr,
                      controller: _displayNameController,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Bio'.tr,
                      controller: _bioController,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Pays'.tr,
                      controller: _countryController,
                      prefixIcon: Icons.public,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Ville'.tr,
                      controller: _cityController,
                      prefixIcon: Icons.location_city,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: _position,
                      decoration: InputDecoration(labelText: 'Poste'.tr),
                      items: AppConstants.playerPositions
                          .map((p) => DropdownMenuItem(value: p, child: Text(p.capitalize.tr)))
                          .toList(),
                      onChanged: (value) => setState(() => _position = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: _preferredFoot,
                      decoration: InputDecoration(labelText: 'Pied fort'.tr),
                      items: AppConstants.preferredFeet
                          .map((f) => DropdownMenuItem(value: f, child: Text(f.fromSnakeCaseToTitle.tr)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _preferredFoot = value);
                      },
                    ),
                    if (profile.isMinor) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'CONTACT D\'UN TUTEUR'.tr,
                        style: context.textTheme.bodySmall?.copyWith(letterSpacing: 1),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        ('Un recruteur vérifié ne peut te contacter qu\'après '
                                'approbation d\'un tuteur — renseigne son contact pour '
                                'pouvoir être approché.')
                            .tr,
                        style: context.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Nom du tuteur (optionnel)'.tr,
                        controller: _guardianNameController,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Email du tuteur'.tr,
                        controller: _guardianEmailController,
                        prefixIcon: Icons.alternate_email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? null
                                : Validators.email(value),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    AppPrimaryButton(
                      label: 'Enregistrer'.tr,
                      isLoading: isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
