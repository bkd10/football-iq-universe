import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/economy_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/challenge_providers.dart';
import '../widgets/date_time_field.dart';

/// Formulaire de création d'un Challenge : ouvert à tous, avec une date de
/// début et une date de fin. La Battle (1 contre 1) a son propre écran,
/// `CreateBattleScreen`. Monde reste officiel, piloté par un admin ;
/// Sponsorisé est réservé à un compte marque vérifié
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
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  bool _isSubmitting = false;
  bool _typeInitializedForBrand = false;


  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose();
    _recordUnitController.dispose();
    _prizeDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSubmitting) return;
    if (_endDate.isBefore(_startDate.add(const Duration(hours: 1)))) {
      context.showSnackBar('La fin doit être au moins 1 heure après le début.'.tr, isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final maxParticipants = int.tryParse(_maxParticipantsController.text.trim());

    final challenge = await ref.read(challengeActionsControllerProvider.notifier).create(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _type,
          startDate: _startDate,
          endDate: _endDate,
          maxParticipants: _type == 'sponsored' ? null : maxParticipants,
          recordUnit: _type == 'king' ? _recordUnitController.text.trim() : null,
          prizeDescription:
              _type == 'sponsored' ? _prizeDescriptionController.text.trim() : null,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (challenge != null) {
      context.showSnackBar('Défi créé !'.tr);
      context.pushReplacement(RouteNames.challengeDetailPath(challenge.id));
    } else {
      final failure = ref.read(challengeActionsControllerProvider).error;
      context.showSnackBar(
        failure is Failure ? failure.message : 'Échec de la création du défi.'.tr,
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
        title: Text(isBrand ? 'Créer un Défi Sponsorisé'.tr : 'Créer un Challenge'.tr),
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
                      ('Gratuit à créer et à rejoindre : aucun Ballon n\'est '
                              'débité ni distribué. Le prix que tu décris ci-dessous '
                              'est un prix réel que tu remets toi-même au vainqueur, '
                              'hors de l\'app.')
                          .tr,
                      style: context.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      ('🎯 Un Challenge est ouvert à tous les joueurs entre la date de '
                              'début et la date de fin. Créer coûte '
                              '{createCost} Ballons ; chaque '
                              'participant paie {joinCost} Ballons, '
                              'qui forment la cagnotte. Le joueur avec le plus de votes la '
                              'remporte.')
                          .trArgs({
                        'createCost': EconomyConstants.createChallengeCost,
                        'joinCost': EconomyConstants.joinChallengeCost,
                      }),
                      style: context.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Titre'.tr),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Le titre est requis.'.tr : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description'.tr,
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
                      decoration: InputDecoration(
                        labelText: 'Description du prix (ex : une paire de crampons)'.tr,
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => (_type == 'sponsored' && (v == null || v.trim().isEmpty))
                          ? 'La description du prix est requise.'.tr
                          : null,
                    ),
                  ),
                if (_type != 'sponsored')
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: TextFormField(
                      controller: _maxParticipantsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Participants max (optionnel)'.tr,
                      ),
                    ),
                  ),
                DateTimeField(
                  label: 'Début'.tr,
                  value: _startDate,
                  enabled: !_isSubmitting,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  onChanged: (d) => setState(() {
                    _startDate = d;
                    if (_endDate.isBefore(d.add(const Duration(hours: 1)))) {
                      _endDate = d.add(const Duration(days: 2));
                    }
                  }),
                ),
                DateTimeField(
                  label: 'Fin'.tr,
                  value: _endDate,
                  enabled: !_isSubmitting,
                  firstDate: _startDate,
                  lastDate: _startDate.add(const Duration(days: 60)),
                  onChanged: (d) => setState(() => _endDate = d),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: isBrand ? 'Publier le défi'.tr : 'Créer le défi'.tr,
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
