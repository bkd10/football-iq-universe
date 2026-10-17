import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../domain/entities/battle_opponent.dart';
import '../providers/challenge_providers.dart';

/// Choix de l'adversaire d'une Battle parmi les joueurs que l'on suit ou
/// qui nous suivent. Renvoie le pseudo choisi (sans @), ou un pseudo tapé
/// à la main si le joueur n'est pas dans la liste.
class BattleOpponentPickerSheet extends ConsumerStatefulWidget {
  const BattleOpponentPickerSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => const BattleOpponentPickerSheet(),
    );
  }

  @override
  ConsumerState<BattleOpponentPickerSheet> createState() => _BattleOpponentPickerSheetState();
}

class _BattleOpponentPickerSheetState extends ConsumerState<BattleOpponentPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _typedUsername => _query.trim().replaceAll(RegExp(r'^[@\s]+'), '');

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(battleOpponentSuggestionsProvider(_query.trim()));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Choisis ton adversaire'.tr, style: context.textTheme.titleLarge),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextField(
                  controller: _searchController,
                  autocorrect: false,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un @pseudo'.tr,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              Expanded(
                child: suggestions.when(
                  loading: () => const Center(child: AppLoader()),
                  error: (error, _) => Center(
                    child: Text(error is Failure ? error.message : 'Erreur.'.tr),
                  ),
                  data: (opponents) => ListView(
                    children: [
                      if (_typedUsername.length >= 2 &&
                          !opponents.any(
                            (o) => o.username.toLowerCase() == _typedUsername.toLowerCase(),
                          ))
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.surfaceLight,
                            child: Icon(Icons.alternate_email),
                          ),
                          title: Text('Défier @{user}'.trArgs({'user': _typedUsername})),
                          subtitle: Text('Joueur hors de tes abonnés'.tr),
                          onTap: () => Navigator.of(context).pop(_typedUsername),
                        ),
                      if (opponents.isEmpty && _typedUsername.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            ('Tu ne suis encore personne et personne ne te suit. '
                                    'Tape le @pseudo d\'un joueur, ou choisis « Aléatoire ».')
                                .tr,
                            style: context.textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      for (final opponent in opponents) _OpponentTile(opponent: opponent),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpponentTile extends StatelessWidget {
  const _OpponentTile({required this.opponent});

  final BattleOpponent opponent;

  @override
  Widget build(BuildContext context) {
    final name = opponent.displayName;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.surfaceLight,
        backgroundImage: opponent.avatarUrl != null ? NetworkImage(opponent.avatarUrl!) : null,
        child: opponent.avatarUrl == null ? Text(opponent.username[0].toUpperCase()) : null,
      ),
      title: Text('@${opponent.username}', overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [if (name != null && name.isNotEmpty) name, opponent.relationLabel.tr].join(' · '),
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => Navigator.of(context).pop(opponent.username),
    );
  }
}
