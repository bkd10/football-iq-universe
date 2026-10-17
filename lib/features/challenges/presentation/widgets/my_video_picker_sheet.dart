import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../../../core/utils/formatters.dart';
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
            Text('Choisis ta vidéo'.tr, style: context.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: videosAsync.when(
                loading: () => const Center(child: AppLoader()),
                error: (error, _) => Center(
                  child: Text(error is Failure ? error.message : 'Erreur.'.tr),
                ),
                data: (videos) {
                  if (videos.isEmpty) {
                    return Center(
                      child: Text(
                        'Publie d\'abord une vidéo pour pouvoir participer.'.tr,
                        style: context.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  // Liste plutôt que grille : beaucoup de vidéos n'ont pas de
                  // miniature, la légende et la date permettent de s'y
                  // retrouver.
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    itemCount: videos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      return MyVideoTile(
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

/// Une vidéo du joueur : miniature (ou icône), légende, date et vues.
class MyVideoTile extends StatelessWidget {
  const MyVideoTile({required this.video, this.onTap, this.trailing, super.key});

  final Video video;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final caption = video.caption.trim();
    final title = video.isMove && video.moveName != null
        ? '🔥 ${video.moveName}'
        : (caption.isNotEmpty ? caption : 'Vidéo sans légende'.tr);
    final age = Formatters.relativeTime(video.createdAt);
    final published = DateTime.now().difference(video.createdAt).inMinutes < 1
        ? 'Publiée {age}'.trArgs({'age': age})
        : 'Publiée il y a {age}'.trArgs({'age': age});
    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 44,
          height: 58,
          child: ColoredBox(
            color: AppColors.surfaceLight,
            child: video.thumbnailUrl != null
                ? Image.network(
                    video.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.videocam_outlined, size: 20),
                  )
                : const Icon(Icons.videocam_outlined, size: 20),
          ),
        ),
      ),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '{published} · {views} vues'.trArgs({
          'published': published,
          'views': Formatters.compactCount(video.viewsCount),
        }),
      ),
      trailing: trailing,
    );
  }
}
