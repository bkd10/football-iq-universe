import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/widgets/video/inline_video_controller.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../moderation/presentation/widgets/report_content_sheet.dart';
import '../../domain/entities/video.dart';
import '../providers/video_providers.dart';
import '../widgets/comments_sheet.dart';

/// Écran "Video Detail" (PARTIE 9.2, écran 8) : vue plein écran d'une
/// vidéo consultée hors du fil principal — grille du profil, fiche Move
/// (meilleures reproductions), recherche... Auparavant un simple message
/// "à venir" ; réutilise le même vocabulaire visuel que le feed.
class VideoDetailScreen extends ConsumerStatefulWidget {
  const VideoDetailScreen({required this.videoId, super.key});

  final String videoId;

  @override
  ConsumerState<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends ConsumerState<VideoDetailScreen> {
  InlineVideoController? _controller;
  String? _initializedForUrl;
  Timer? _viewTimer;

  @override
  void dispose() {
    _viewTimer?.cancel();
    _controller
      ?..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initController(String url) async {
    if (_initializedForUrl == url) return;
    _initializedForUrl = url;
    final controller = InlineVideoController(url);
    _controller = controller;
    controller.addListener(_onControllerChanged);
    await controller.initialize();
    if (!mounted) return;
    setState(() {});
    controller.play();
    _viewTimer = Timer(AppConstants.minWatchTimeForView, () {
      if (!mounted) return;
      ref.read(videoDetailControllerProvider(widget.videoId).notifier).registerView();
    });
  }

  @override
  Widget build(BuildContext context) {
    final videoAsync = ref.watch(videoDetailControllerProvider(widget.videoId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: videoAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              error is Failure ? error.message : 'Vidéo introuvable.'.tr,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (video) {
          if (video == null) {
            return Center(
              child: Text(
                'Cette vidéo a été supprimée ou n\'existe plus.'.tr,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _initController(video.videoUrl);
          });
          return _VideoDetailBody(video: video, controller: _controller);
        },
      ),
    );
  }
}

class _VideoDetailBody extends ConsumerWidget {
  const _VideoDetailBody({
    required this.video,
    required this.controller,
  });

  final Video video;
  final InlineVideoController? controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildVideoLayer(),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ),
        PositionedDirectional(
          top: AppSpacing.md,
          start: AppSpacing.sm,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.feed),
            ),
          ),
        ),
        PositionedDirectional(
          top: AppSpacing.md,
          end: AppSpacing.sm,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.flag_outlined, color: Colors.white),
              tooltip: 'Signaler'.tr,
              onPressed: () => showReportContentSheet(
                context,
                targetType: 'video',
                targetId: video.id,
              ),
            ),
          ),
        ),
        _buildActionRail(context, ref),
        _buildInfoOverlay(context),
      ],
    );
  }

  Widget _buildVideoLayer() {
    final c = controller;
    if (c != null && c.hasError) {
      return const ColoredBox(
        color: AppColors.surface,
        child: Center(
          child: Icon(Icons.videocam_off_outlined, color: AppColors.textSecondary, size: 40),
        ),
      );
    }
    return GestureDetector(
      onTap: c == null ? null : () => c.isPlaying ? c.pause() : c.play(),
      child: ColoredBox(
        color: AppColors.surface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (video.thumbnailUrl != null)
              Image.network(
                video.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            if (c != null) c.buildView(),
            if (c != null && !c.isPlaying)
              const Center(
                child: Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 88),
              ),
            if (c != null)
              PositionedDirectional(
                top: AppSpacing.xl * 2,
                end: AppSpacing.md,
                child: IconButton(
                  icon: Icon(c.isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                  onPressed: () => c.isMuted = !c.isMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRail(BuildContext context, WidgetRef ref) {
    return PositionedDirectional(
      end: AppSpacing.sm,
      bottom: 110,
      child: Column(
        children: [
          _RailButton(
            icon: video.hasLiked ? Icons.favorite : Icons.favorite_border,
            color: video.hasLiked ? AppColors.primary : Colors.white,
            label: Formatters.compactCount(video.likesCount),
            onTap: () => ref
                .read(videoDetailControllerProvider(video.id).notifier)
                .toggleLike(isMasterclass: false),
          ),
          const SizedBox(height: AppSpacing.md),
          _RailButton(
            icon: Icons.star,
            color: video.hasMasterclassed ? AppColors.gold : Colors.white,
            label: Formatters.compactCount(video.masterclassCount),
            onTap: () => ref
                .read(videoDetailControllerProvider(video.id).notifier)
                .toggleLike(isMasterclass: true),
          ),
          const SizedBox(height: AppSpacing.md),
          _RailButton(
            icon: Icons.mode_comment_outlined,
            label: Formatters.compactCount(video.commentsCount),
            onTap: () => CommentsSheet.show(context, video.id),
          ),
          const SizedBox(height: AppSpacing.md),
          _RailButton(
            icon: Icons.share_outlined,
            label: 'Partager'.tr,
            onTap: () => SharePlus.instance.share(
              ShareParams(
                text: video.isMove
                    ? 'Regarde le Move "{move}" sur Football IQ Universe : {url}'
                        .trArgs({'move': video.moveName, 'url': video.videoUrl})
                    : 'Regarde cette vidéo sur Football IQ Universe : {url}'
                        .trArgs({'url': video.videoUrl}),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoOverlay(BuildContext context) {
    final creator = video.creator;
    return PositionedDirectional(
      start: AppSpacing.md,
      end: 76,
      bottom: AppSpacing.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => context.push(RouteNames.otherProfilePath(video.userId)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '@${creator?.username ?? 'inconnu'.tr}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
                if (creator?.isVerified ?? false) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, size: 15, color: AppColors.primary),
                ],
              ],
            ),
          ),
          if (video.isMove) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '🔥 {move} — Move original'.trArgs({'move': video.moveName ?? 'Move'}),
                style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ] else if (video.originalMoveId != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => context.push(RouteNames.moveDetailPath(video.originalMoveId!)),
              child: Text(
                'Reproduit un Move'.tr,
                style: const TextStyle(color: AppColors.diamond, fontSize: 11, decoration: TextDecoration.underline),
              ),
            ),
          ],
          if (video.caption.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(video.caption, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
          const SizedBox(height: 4),
          Text(
            '#{category} · {views} vues'.trArgs({
              'category': video.category,
              'views': Formatters.compactCount(video.viewsCount),
            }),
            style: const TextStyle(color: AppColors.diamond, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}
