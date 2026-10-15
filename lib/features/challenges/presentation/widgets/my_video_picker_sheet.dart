import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../../../shared/widgets/video_thumbnail_tile.dart';
import '../../../videos/domain/entities/video.dart';
import '../../../videos/presentation/providers/video_providers.dart';

/// Choix d'une de ses propres vidéos (pour participer à un défi ou lancer
/// une Battle).
class MyVideoPickerSheet extends ConsumerWidget {
  const MyVideoPickerSheet({required this.userId, super.key});

  static Future<Video?> show(BuildContext context, String userId) {
    return showModalBottomSheet<Video>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => MyVideoPickerSheet(userId: userId),
    );
  }

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(userVideosProvider(userId));

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
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
            Text('Choisis ta vidéo', style: context.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: videosAsync.when(
                loading: () => const Center(child: AppLoader()),
                error: (error, _) => Center(
                  child: Text(error is Failure ? error.message : 'Erreur.'),
                ),
                data: (videos) {
                  if (videos.isEmpty) {
                    return Center(
                      child: Text(
                        'Publie d\'abord une vidéo pour pouvoir participer.',
                        style: context.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
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
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      return VideoThumbnailTile(
                        video: video,
                        onTap: () => Navigator.of(context).pop(video),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
