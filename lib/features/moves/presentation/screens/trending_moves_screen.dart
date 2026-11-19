import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../../../shared/widgets/video_thumbnail_tile.dart';
import '../../../sponsored/domain/sponsored_models.dart';
import '../../../sponsored/presentation/providers/sponsored_providers.dart';
import '../../../sponsored/presentation/widgets/sponsored_challenge_card.dart';
import '../../../videos/presentation/providers/video_providers.dart';

/// Moves du moment — voir PARTIE 9.2 (écran "Trending Moves"), triés par
/// nombre de reproductions.
class TrendingMovesScreen extends ConsumerWidget {
  const TrendingMovesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movesAsync = ref.watch(trendingMovesProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Moves du moment'.tr)),
      body: movesAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (error, _) => Center(
          child: Text(error is Failure ? error.message : 'Erreur de chargement.'.tr),
        ),
        data: (moves) {
          if (moves.isEmpty) {
            return Center(
              child: Text(
                'Aucun Move pour l\'instant — sois le premier à en créer un !'.tr,
                style: context.textTheme.bodyMedium,
              ),
            );
          }
          // Un défi sponsorisé toutes les N vidéos, comme dans « Pour toi ».
          final sponsored = ref.watch(sponsoredFeedChallengesProvider).valueOrNull ?? const [];
          final config =
              ref.watch(sponsoredFeedConfigProvider).valueOrNull ?? const SponsoredFeedConfig();
          final every = config.everyN;
          final showSponsored = config.enabled && sponsored.isNotEmpty;
          final slivers = <Widget>[];
          var shown = 0;
          for (var start = 0; start < moves.length; start += every) {
            final chunk = moves.sublist(start, (start + every).clamp(0, moves.length));
            slivers.add(
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final move = chunk[index];
                    return VideoThumbnailTile(
                      video: move,
                      showVote: true,
                      onTap: () => context.push(RouteNames.moveDetailPath(move.id)),
                    );
                  },
                  childCount: chunk.length,
                ),
              ),
            );
            final isLast = start + every >= moves.length;
            if (showSponsored && (!isLast || shown == 0)) {
              slivers.add(
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  sliver: SliverToBoxAdapter(
                    child: SponsoredChallengeCard(
                      challenge: sponsored[shown % sponsored.length],
                      fullPage: false,
                    ),
                  ),
                ),
              );
              shown++;
            }
          }
          return CustomScrollView(
            slivers: [
              for (final s in slivers)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  sliver: s,
                ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            ],
          );
        },
      ),
    );
  }
}
