import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../features/videos/domain/entities/video.dart';
import '../../features/sponsored/presentation/widgets/challenge_vote_button.dart';
import 'pressable.dart';

/// Vignette vidéo réutilisée dans les grilles (Football Passport, fiche
/// d'un Move, Trending Moves) : miniature + badge Move + compteur de vues.
class VideoThumbnailTile extends StatelessWidget {
  const VideoThumbnailTile({required this.video, this.onTap, this.showVote = false, super.key});

  final Video video;
  final VoidCallback? onTap;

  /// Profil : petit bouton Voter si la vidéo est dans un défi en cours.
  final bool showVote;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Vidéo, {n} vues'.trArgs({'n': Formatters.compactCount(video.viewsCount)}),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: AppColors.surface,
            child: video.thumbnailUrl != null
                ? CachedNetworkImage(
                    imageUrl: video.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const Icon(
                      Icons.videocam_outlined,
                      color: AppColors.textSecondary,
                    ),
                  )
                : const Icon(Icons.videocam_outlined, color: AppColors.textSecondary),
          ),
          if (showVote)
            PositionedDirectional(
              end: 4,
              bottom: 4,
              child: ChallengeVoteButton(videoId: video.id, compact: true),
            ),
          if (video.isMove)
            const PositionedDirectional(
              top: 4,
              start: 4,
              child: Text('🔥', style: TextStyle(fontSize: 14)),
            ),
          PositionedDirectional(
            start: 4,
            bottom: 4,
            child: Row(
              children: [
                const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                Text(
                  Formatters.compactCount(video.viewsCount),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
