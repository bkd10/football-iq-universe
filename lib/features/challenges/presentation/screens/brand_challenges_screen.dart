import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/challenge_providers.dart';
import '../widgets/challenge_card.dart';

/// Liste des Défis Sponsorisés créés par la marque connectée (PARTIE 8.3).
/// Réutilise `challengesProvider('sponsored')` (tous les défis sponsorisés
/// de la plateforme) filtré côté client sur `creator.id` — un compte marque
/// n'en crée jamais assez pour qu'un filtre serveur dédié soit nécessaire.
class BrandChallengesScreen extends ConsumerWidget {
  const BrandChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(currentProfileProvider).valueOrNull?.id;
    final challengesAsync = ref.watch(challengesProvider('sponsored'));

    return Scaffold(
      appBar: AppBar(title: const Text('Mes Défis Sponsorisés')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.createChallenge),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.background),
        label: const Text('Nouveau défi', style: TextStyle(color: AppColors.background)),
      ),
      body: challengesAsync.when(
        loading: () => const AppFullScreenLoader(),
        error: (error, _) => Center(
          child: Text(error is Failure ? error.message : 'Erreur de chargement.'),
        ),
        data: (challenges) {
          final mine = challenges.where((c) => c.creator?.id == myId).toList();
          if (mine.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Aucun défi publié pour l\'instant. Crée ton premier Défi '
                  'Sponsorisé avec le bouton ci-dessous.',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyLarge,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: mine.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ChallengeCard(
                challenge: mine[index],
                onTap: () => context.push(RouteNames.challengeDetailPath(mine[index].id)),
              ),
            ),
          );
        },
      ),
    );
  }
}
