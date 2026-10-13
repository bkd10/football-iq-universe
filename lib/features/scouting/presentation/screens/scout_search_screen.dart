import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/string_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../domain/entities/scout_player_result.dart';
import '../providers/scouting_providers.dart';

/// Recherche de joueurs pour un recruteur (PARTIE 8.4/8.5). N'affiche
/// jamais de date de naissance exacte, seulement [ScoutPlayerResult.isMinor]
/// (voir la RPC `scout_search_players`).
class ScoutSearchScreen extends ConsumerStatefulWidget {
  const ScoutSearchScreen({super.key});

  @override
  ConsumerState<ScoutSearchScreen> createState() => _ScoutSearchScreenState();
}

class _ScoutSearchScreenState extends ConsumerState<ScoutSearchScreen> {
  final _queryController = TextEditingController();
  final _countryController = TextEditingController();
  String? _position;

  @override
  void dispose() {
    _queryController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(scoutSearchQueryProvider.notifier).state = ScoutSearchQuery(
      query: _queryController.text.trim(),
      position: _position,
      country: _countryController.text.trim().isEmpty
          ? null
          : _countryController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(scoutSearchResultsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rechercher des joueurs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                TextField(
                  controller: _queryController,
                  decoration: const InputDecoration(
                    labelText: 'Pseudo',
                    prefixIcon: Icon(Icons.search),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _applyFilters(),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _position,
                        decoration: const InputDecoration(labelText: 'Poste'),
                        items: [
                          const DropdownMenuItem<String>(child: Text('Tous')),
                          ...AppConstants.playerPositions.map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.capitalize),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() => _position = value),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _countryController,
                        decoration: const InputDecoration(labelText: 'Pays'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _applyFilters,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      'Rechercher',
                      style: TextStyle(color: AppColors.background),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: resultsAsync.when(
              loading: () => const AppFullScreenLoader(),
              error: (error, _) => Center(
                child: Text(
                  error is Failure ? error.message : 'Erreur de chargement.',
                ),
              ),
              data: (results) {
                if (results.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucun joueur trouvé.',
                      style: context.textTheme.bodyMedium,
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _PlayerTile(player: results[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player});

  final ScoutPlayerResult player;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.push(RouteNames.otherProfilePath(player.id)),
      leading: CircleAvatar(
        backgroundColor: AppColors.surfaceLight,
        backgroundImage:
            player.avatarUrl != null ? NetworkImage(player.avatarUrl!) : null,
        child:
            player.avatarUrl == null ? const Icon(Icons.person_outline) : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              player.displayName?.isNotEmpty == true
                  ? player.displayName!
                  : '@${player.username}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (player.isMinor) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                'Mineur',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        [
          if (player.position != null) player.position!.capitalize,
          if (player.city != null) player.city!,
          if (player.country != null) player.country!,
        ].join(' · '),
      ),
      trailing: Text(
        '${Formatters.compactCount(player.stars)} ★',
        style: const TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
