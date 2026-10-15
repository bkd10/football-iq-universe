import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../providers/challenge_providers.dart';
import '../widgets/challenge_card.dart';

const _filters = [
  (label: 'Tous', type: null),
  (label: '⚔️ Battle', type: 'battle'),
  (label: '🎯 Challenge', type: 'challenge'),
  (label: '🌍 Monde', type: 'world'),
  (label: '💼 Sponsorisé', type: 'sponsored'),
];

/// Liste des défis — voir PARTIE 8.3 : filtres par type. Un joueur crée
/// Battle/Challenge/King depuis ce bouton "+" ; Monde reste piloté par un
/// admin ; Sponsorisé est créé par un compte marque vérifié depuis son
/// propre tableau de bord (`BrandChallengesScreen`), pas depuis cet écran.
class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(challengesProvider(_selectedType));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Défis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Créer un défi',
            onPressed: () => context.push(RouteNames.createChallenge),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final selected = _selectedType == filter.type;
                return ChoiceChip(
                  label: Text(filter.label),
                  selected: selected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.surfaceLight,
                  ),
                  backgroundColor: AppColors.surface,
                  onSelected: (_) => setState(() => _selectedType = filter.type),
                );
              },
            ),
          ),
          Expanded(
            child: challengesAsync.when(
              loading: () => const Center(child: AppLoader()),
              error: (error, _) => Center(
                child: Text(
                  error is Failure ? error.message : 'Erreur de chargement.',
                  style: context.textTheme.bodyMedium,
                ),
              ),
              data: (challenges) {
                if (challenges.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucun défi pour l\'instant — lance le premier !',
                      style: context.textTheme.bodyMedium,
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async =>
                      ref.invalidate(challengesProvider(_selectedType)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: challenges.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final challenge = challenges[index];
                      return ChallengeCard(
                        challenge: challenge,
                        onTap: () => context.push(
                          RouteNames.challengeDetailPath(challenge.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
