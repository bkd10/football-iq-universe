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
import '../../../videos/domain/entities/video.dart';
import '../providers/challenge_providers.dart';
import '../widgets/battle_opponent_picker_sheet.dart';
import '../widgets/date_time_field.dart';
import '../widgets/my_video_picker_sheet.dart';

/// Battle 1 contre 1 : le joueur fixe les règles (« le plus beau but »,
/// « qui réussit ce geste »...), la mise en Ballons et, s'il veut, son
/// adversaire. L'adversaire mise la même somme pour relever la Battle, les
/// autres utilisateurs votent, le gagnant remporte les deux mises.
///
/// Adversaire : le premier qui relève, un joueur choisi parmi ses abonnés
/// et abonnements (ou tapé à la main), ou un joueur tiré au hasard.
enum _OpponentMode { open, chosen, random }

class CreateBattleScreen extends ConsumerStatefulWidget {
  const CreateBattleScreen({super.key});

  @override
  ConsumerState<CreateBattleScreen> createState() => _CreateBattleScreenState();
}

class _CreateBattleScreenState extends ConsumerState<CreateBattleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _rulesController = TextEditingController();
  final _stakeController = TextEditingController(text: '30');

  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  Video? _video;
  _OpponentMode _opponentMode = _OpponentMode.open;
  String? _opponentUsername;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _rulesController.dispose();
    _stakeController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile == null) return;
    final video = await MyVideoPickerSheet.show(context, profile.id);
    if (video == null) return;
    setState(() => _video = video);
  }

  Future<void> _pickOpponent() async {
    final username = await BattleOpponentPickerSheet.show(context);
    if (username == null || !mounted) return;
    setState(() {
      _opponentUsername = username;
      _opponentMode = _OpponentMode.chosen;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSubmitting) return;
    if (_video == null) {
      context.showSnackBar('Choisis ta vidéo pour la Battle.', isError: true);
      return;
    }
    if (_opponentMode == _OpponentMode.chosen && _opponentUsername == null) {
      context.showSnackBar('Choisis ton adversaire.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    final battle = await ref.read(challengeActionsControllerProvider.notifier).createBattle(
          title: _titleController.text.trim(),
          rules: _rulesController.text.trim(),
          stake: int.parse(_stakeController.text.trim()),
          videoId: _video!.id,
          endDate: _endDate,
          opponentUsername: _opponentMode == _OpponentMode.chosen ? _opponentUsername : null,
          randomOpponent: _opponentMode == _OpponentMode.random,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (battle != null) {
      context.showSnackBar('Battle lancée ! ⚔️');
      context.pushReplacement(RouteNames.challengeDetailPath(battle.id));
    } else {
      final failure = ref.read(challengeActionsControllerProvider).error;
      context.showSnackBar(
        failure is Failure ? failure.message : 'Impossible de lancer la Battle.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(currentProfileProvider).valueOrNull?.coins;

    return Scaffold(
      appBar: AppBar(title: const Text('Lancer une Battle')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(
                    '⚔️ Toi contre un autre joueur. Tu fixes les règles et la mise. '
                    'Ton adversaire mise la même somme pour relever le défi, puis '
                    'les utilisateurs votent. Le gagnant remporte les deux mises. '
                    'Égalité ou personne en face : chacun récupère sa mise.',
                    style: context.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    hintText: 'Ex : le plus beau but',
                  ),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Donne un titre (3 caractères minimum).'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _rulesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Règles',
                    hintText: 'Ex : qui fait ce geste ? Le plus beau geste gagne.',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _stakeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Mise (Ballons)',
                    helperText: coins != null ? 'Tu as $coins Ballons' : null,
                  ),
                  validator: (v) {
                    final stake = int.tryParse(v?.trim() ?? '');
                    if (stake == null ||
                        stake < EconomyConstants.battleMinStake ||
                        stake > EconomyConstants.battleMaxStake) {
                      return 'Entre ${EconomyConstants.battleMinStake} et '
                          '${EconomyConstants.battleMaxStake} Ballons.';
                    }
                    if (coins != null && stake > coins) return 'Tu n\'as que $coins Ballons.';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Adversaire', style: context.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<_OpponentMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: _OpponentMode.open,
                      label: Text('Ouvert'),
                      icon: Icon(Icons.public),
                    ),
                    ButtonSegment(
                      value: _OpponentMode.chosen,
                      label: Text('Choisir'),
                      icon: Icon(Icons.person_search),
                    ),
                    ButtonSegment(
                      value: _OpponentMode.random,
                      label: Text('Aléatoire'),
                      icon: Icon(Icons.casino_outlined),
                    ),
                  ],
                  selected: {_opponentMode},
                  onSelectionChanged: _isSubmitting
                      ? null
                      : (selection) {
                          final mode = selection.first;
                          setState(() => _opponentMode = mode);
                          if (mode == _OpponentMode.chosen && _opponentUsername == null) {
                            _pickOpponent();
                          }
                        },
                ),
                const SizedBox(height: AppSpacing.xs),
                switch (_opponentMode) {
                  _OpponentMode.open => const _OpponentHint(
                      'Le premier joueur qui relève la Battle sera ton adversaire.',
                    ),
                  _OpponentMode.random => const _OpponentHint(
                      'Un joueur tiré au hasard sera défié et prévenu.',
                    ),
                  _OpponentMode.chosen => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_outline),
                      title: Text(
                        _opponentUsername != null
                            ? '@$_opponentUsername'
                            : 'Choisir parmi tes abonnés et abonnements',
                      ),
                      subtitle: _opponentUsername != null ? const Text('Changer') : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _isSubmitting ? null : _pickOpponent,
                    ),
                },
                const SizedBox(height: AppSpacing.md),
                Text('Ta vidéo', style: context.textTheme.titleSmall),
                if (_video != null)
                  MyVideoTile(
                    video: _video!,
                    onTap: _isSubmitting ? null : _pickVideo,
                    trailing: const Text('Changer'),
                  )
                else
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.videocam_outlined),
                    title: const Text('Choisir ma vidéo'),
                    subtitle: const Text('La vidéo avec laquelle tu affrontes ton adversaire'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _isSubmitting ? null : _pickVideo,
                  ),
                const SizedBox(height: AppSpacing.sm),
                DateTimeField(
                  label: 'Fin des votes',
                  value: _endDate,
                  enabled: !_isSubmitting,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 14)),
                  onChanged: (d) => setState(() => _endDate = d),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: 'Lancer la Battle',
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

class _OpponentHint extends StatelessWidget {
  const _OpponentHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        text,
        style: context.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
