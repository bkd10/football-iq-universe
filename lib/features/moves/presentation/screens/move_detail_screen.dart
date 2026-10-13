import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../../../shared/widgets/video_thumbnail_tile.dart';
import '../../../videos/presentation/providers/video_providers.dart';

/// Fiche d'un Move — voir PARTIE 8.2/9.2. Affiche le créateur (crédité à
/// vie), les statistiques et les meilleures reproductions, avec un accès
/// direct pour en créer une nouvelle.
class MoveDetailScreen extends ConsumerWidget {
  const MoveDetailScreen({required this.moveId, super.key});

  final String moveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moveAsync = ref.watch(videoByIdProvider(moveId));

    return Scaffold(
      appBar: AppBar(title: const Text('Move')),
      body: moveAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (error, _) => Center(
          child: Text(error is Failure ? error.message : 'Erreur de chargement.'),
        ),
        data: (move) {
          if (move == null) {
            return Center(
              child: Text('Ce Move est introuvable.', style: context.textTheme.bodyLarge),
            );
          }

          final reproductionsAsync = ref.watch(moveReproductionsProvider(moveId));

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                '🔥 ${move.moveName ?? 'Move'}',
                style: context.textTheme.displaySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Inventé par @${move.creator?.username ?? 'inconnu'}',
                style: context.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatColumn(
                    label: 'Vues',
                    value: Formatters.compactCount(move.viewsCount),
                  ),
                  _StatColumn(
                    label: 'Reproductions',
                    value: Formatters.compactCount(move.reproductionsCount),
                    color: AppColors.primary,
                  ),
                  _StatColumn(
                    label: 'Masterclass',
                    value: Formatters.compactCount(move.masterclassCount),
                    color: AppColors.gold,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppPrimaryButton(
                label: 'Essayer ce Move',
                icon: Icons.videocam,
                onPressed: () => context.push(
                  '${RouteNames.create}?originalMoveId=$moveId',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Meilleures reproductions', style: context.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              reproductionsAsync.when(
                loading: () => const Center(child: AppLoader()),
                error: (error, _) => Text(
                  error is Failure ? error.message : 'Erreur de chargement.',
                ),
                data: (reproductions) {
                  if (reproductions.isEmpty) {
                    return Text(
                      'Personne n\'a encore reproduit ce Move — sois le premier !',
                      style: context.textTheme.bodyMedium,
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: reproductions.length,
                    itemBuilder: (context, index) => VideoThumbnailTile(
                      video: reproductions[index],
                      onTap: () => context.push(
                        RouteNames.videoDetailPath(reproductions[index].id),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    this.color = AppColors.textPrimary,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.stat(color: color, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
