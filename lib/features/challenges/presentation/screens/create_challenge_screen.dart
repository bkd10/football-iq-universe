import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/economy_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/challenge_providers.dart';
import '../widgets/challenge_card.dart';

const _creatableTypes = ['battle', 'challenge', 'king'];

/// Formulaire de création — voir PARTIE 9.2. Seuls Battle/Challenge/King
/// sont créables par un joueur (Monde reste officiel, piloté par un admin
/// hors de cette RPC) ; Sponsorisé est réservé à un compte marque vérifié
/// (`role == 'brand'`, voir `20260101000014_sponsored_challenges.sql`) —
/// ce même écran s'adapte selon le rôle du compte connecté plutôt que d'en
/// dupliquer un second pour une différence somme toute limitée (pas de
/// coût de création, un prix décrit en texte au lieu d'une cagnotte de
/// Ballons).
///
/// Pas de champ "prize_pool" pour un joueur : impossible d'émettre des
/// Ballons sans contrepartie. La cagnotte n'est donc jamais fixée par le
/// créateur — elle se constitue elle-même à chaque participation
/// (`join_challenge` ajoute le droit d'entrée à `prize_pool`) et revient en
/// entier au vainqueur (`resolve_expired_challenges`). Le coût de création
/// (200 Ballons) n'y entre jamais : c'est un coût fixe payé une fois par le
/// créateur, pas une mise. Voir `20260101000012_challenge_prize_pool.sql`.
class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  ConsumerState<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _recordUnitController = TextEditingController();
  final _prizeDescriptionController = TextEditingController();

  String _type = 'challenge';
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  bool _isSubmitting = false;
  bool _typeInitializedForBrand = false;

  /// Miroir client, affichage uniquement, de la logique serveur de
  /// `create_challenge` (le vrai coût est toujours calculé côté serveur).
  int get _entryCostForType => _type == 'battle'
      ? EconomyConstants.joinBattleMinCost
      : EconomyConstants.joinChallengeCost;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose();
    _recordUnitController.dispose();
    _prizeDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now().add(const Duration(hours: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endDate),
    );
    if (time == null) return;

    setState(() {
      _endDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSubmitting) return;
    if (_endDate.isBefore(DateTime.now())) {
      context.showSnackBar('La date de fin doit être dans le futur.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final maxParticipants = int.tryParse(_maxParticipantsController.text.trim());

    final challenge = await ref.read(challengeActionsControllerProvider.notifier).create(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _type,
          endDate: _endDate,
          maxParticipants: _type == 'sponsored' ? null : maxParticipants,
          recordUnit: _type == 'king' ? _recordUnitController.text.trim() : null,
          prizeDescription:
              _type == 'sponsored' ? _prizeDescriptionController.text.trim() : null,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (challenge != null) {
      context.showSnackBar('Défi créé !');
      context.pushReplacement(RouteNames.challengeDetailPath(challenge.id));
    } else {
      final failure = ref.read(challengeActionsControllerProvider).error;
      context.showSnackBar(
        failure is Failure ? failure.message : 'Échec de la création du défi.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBrand = ref.watch(currentProfileProvider).valueOrNull?.role == 'brand';
    if (isBrand && !_typeInitializedForBrand) {
      _typeInitializedForBrand = true;
      _type = 'sponsored';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isBrand ? 'Créer un Défi Sponsorisé' : 'Créer un défi'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isBrand) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      'Gratuit à créer et à rejoindre : aucun Ballon n\'est '
                      'débité ni distribué. Le prix que tu décris ci-dessous '
                      'est un prix réel que tu remets toi-même au vainqueur, '
                      'hors de l\'app.',
                      style: context.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ] else ...[
                  Text(
                    'Coût de création : 200 Ballons',
                    style: context.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Type de défi'),
                    items: _creatableTypes
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(challengeTypeLabels[t] ?? t),
                          ),
                        )
                        .toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            if (value != null) setState(() => _type = value);
                          },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      'Chaque participant paiera $_entryCostForType Ballons pour '
                      'rejoindre. Cette somme s\'ajoute à la cagnotte, versée '
                      'en entier au vainqueur — toi y compris, si tu '
                      'participes aussi.',
                      style: context.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Titre'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Le titre est requis.' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_type == 'sponsored')
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: TextFormField(
                      controller: _prizeDescriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description du prix (ex : une paire de crampons)',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => (_type == 'sponsored' && (v == null || v.trim().isEmpty))
                          ? 'La description du prix est requise.'
                          : null,
                    ),
                  ),
                if (_type == 'king')
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: TextFormField(
                      controller: _recordUnitController,
                      decoration: const InputDecoration(
                        labelText: 'Unité du record (ex : jongles, secondes)',
                      ),
                      validator: (v) => (_type == 'king' && (v == null || v.trim().isEmpty))
                          ? 'Requis pour un King Challenge.'
                          : null,
                    ),
                  ),
                if (_type != 'king')
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: TextFormField(
                      controller: _maxParticipantsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Participants max (optionnel)',
                      ),
                    ),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date de fin'),
                  subtitle: Text(
                    '${_endDate.day}/${_endDate.month}/${_endDate.year} à '
                    '${_endDate.hour.toString().padLeft(2, '0')}:'
                    '${_endDate.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _isSubmitting ? null : _pickEndDate,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: isBrand ? 'Publier le défi' : 'Créer le défi',
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
