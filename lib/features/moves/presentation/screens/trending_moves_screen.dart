import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../../../shared/widgets/video_thumbnail_tile.dart';
import '../../../videos/presentation/providers/video_providers.dart';

/// Moves du moment — voir PARTIE 9.2 (écran "Trending Moves"), triés par
/// nombre de reproductions.
class TrendingMovesScreen extends ConsumerWidget {
  const TrendingMovesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movesAsync = ref.watch(trendingMovesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Moves du moment')),
      body: movesAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (error, _) => Center(
          child: Text(error is Failure ? error.message : 'Erreur de chargement.'),
        ),
        data: (moves) {
          if (moves.isEmpty) {
            return Center(
              child: Text(
                'Aucun Move pour l\'instant — sois le premier à en créer un !',
                style: context.textTheme.bodyMedium,
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 0.72,
            ),
            itemCount: moves.length,
            itemBuilder: (context, index) {
              final move = moves[index];
              return VideoThumbnailTile(
                video: move,
                onTap: () => context.push(RouteNames.moveDetailPath(move.id)),
              );
            },
          );
        },
      ),
    );
  }
}
