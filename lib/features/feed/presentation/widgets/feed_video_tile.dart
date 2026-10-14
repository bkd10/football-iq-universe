import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/video/inline_video_controller.dart';
import '../../../missions/presentation/providers/missions_providers.dart';
import '../../../profile/presentation/providers/social_providers.dart';
import '../../../videos/domain/entities/video.dart';
import '../../../videos/presentation/providers/video_providers.dart';
import '../../../videos/presentation/widgets/comments_sheet.dart';

/// Une "page" du feed plein écran : lecture vidéo + interactions
/// (like/Masterclass/commentaires/partage/suivre) — voir PARTIE 8.1.
class FeedVideoTile extends ConsumerStatefulWidget {
  const FeedVideoTile({required this.video, required this.isActive, super.key});

  final Video video;
  final bool isActive;

  @override
  ConsumerState<FeedVideoTile> createState() => _FeedVideoTileState();
}

class _FeedVideoTileState extends ConsumerState<FeedVideoTile> {
  InlineVideoController? _controller;
  Timer? _viewTimer;
  int _heartBurstId = 0;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final controller = InlineVideoController(widget.video.videoUrl);
    _controller = controller;
    controller.addListener(_onControllerChanged);
    await controller.initialize();
    if (!mounted) return;
    setState(() {});
    if (widget.isActive) _play();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant FeedVideoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _play();
      } else {
        _pause();
      }
    }
  }

  void _play() {
    _controller?.play();
    _viewTimer?.cancel();
    _viewTimer = Timer(AppConstants.minWatchTimeForView, () {
      if (!mounted) return;
      ref.read(feedControllerProvider.notifier).registerView(widget.video.id);
      ref.read(missionsControllerProvider.notifier).registerVideoWatched();
    });
  }

  void _pause() {
    _controller?.pause();
    _viewTimer?.cancel();
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    _controller
      ?..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null) return;
    controller.isPlaying ? controller.pause() : controller.play();
  }

  void _toggleSound() {
    final controller = _controller;
    if (controller == null) return;
    controller.isMuted = !controller.isMuted;
  }

  void _onDoubleTap() {
    if (!widget.video.hasLiked) {
      ref
          .read(feedControllerProvider.notifier)
          .toggleLike(widget.video.id, isMasterclass: false);
    }
    setState(() => _heartBurstId++);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTap: _onDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildVideoLayer(),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),
          Center(
            child: KeyedSubtree(
              key: ValueKey(_heartBurstId),
              child: _heartBurstId == 0
                  ? const SizedBox.shrink()
                  : const Icon(Icons.favorite, color: AppColors.primary, size: 96)
                      .animate()
                      .scale(
                        begin: const Offset(0.4, 0.4),
                        end: const Offset(1.1, 1.1),
                        duration: 220.ms,
                        curve: Curves.easeOut,
                      )
                      .then(delay: 250.ms)
                      .fadeOut(duration: 250.ms),
            ),
          ),
          _buildActionRail(),
          _buildInfoOverlay(context),
        ],
      ),
    );
  }

  Widget _buildVideoLayer() {
    final controller = _controller;
    if (controller != null && controller.hasError) {
      return const ColoredBox(
        color: AppColors.surface,
        child: Center(
          child: Icon(Icons.videocam_off_outlined, color: AppColors.textSecondary, size: 40),
        ),
      );
    }
    return ColoredBox(
      color: AppColors.surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.video.thumbnailUrl != null)
            Image.network(
              widget.video.thumbnailUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          if (controller != null) controller.buildView(),
          // Lecture bloquée (ex. mode économie d'énergie sur iPhone) ou mise
          // en pause : un tap relance.
          if (controller != null && widget.isActive && !controller.isPlaying)
            const Center(
              child: Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 88),
            ),
        ],
      ),
    );
  }

  Widget _buildActionRail() {
    final video = widget.video;
    final followState = ref.watch(followControllerProvider(video.userId));

    return Positioned(
      right: AppSpacing.sm,
      bottom: 110,
      child: Column(
        children: [
          _CreatorAvatar(video: video, isFollowing: followState.valueOrNull ?? false),
          const SizedBox(height: AppSpacing.lg),
          _RailButton(
            icon: (_controller?.isMuted ?? false) ? Icons.volume_off : Icons.volume_up,
            label: 'Son',
            onTap: _toggleSound,
          ),
          const SizedBox(height: AppSpacing.md),
          _RailButton(
            icon: video.hasLiked ? Icons.favorite : Icons.favorite_border,
            color: video.hasLiked ? AppColors.primary : Colors.white,
            label: Formatters.compactCount(video.likesCount),
            onTap: () => ref
                .read(feedControllerProvider.notifier)
                .toggleLike(video.id, isMasterclass: false),
          ),
          const SizedBox(height: AppSpacing.md),
          _RailButton(
            icon: Icons.star,
            color: video.hasMasterclassed ? AppColors.gold : Colors.white,
            label: Formatters.compactCount(video.masterclassCount),
            onTap: () => ref
                .read(feedControllerProvider.notifier)
                .toggleLike(video.id, isMasterclass: true),
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
            label: 'Partager',
            onTap: () => SharePlus.instance.share(
              ShareParams(
                text: video.isMove
                    ? 'Regarde le Move "${video.moveName}" sur Football IQ Universe : ${video.videoUrl}'
                    : 'Regarde cette vidéo sur Football IQ Universe : ${video.videoUrl}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoOverlay(BuildContext context) {
    final video = widget.video;
    final creator = video.creator;

    return Positioned(
      left: AppSpacing.md,
      right: 76,
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
                  '@${creator?.username ?? 'inconnu'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
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
            GestureDetector(
              onTap: () => context.push(RouteNames.moveDetailPath(video.id)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '🔥 ${video.moveName ?? 'Move'} — Move original',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else if (video.originalMoveId != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => context.push(RouteNames.moveDetailPath(video.originalMoveId!)),
              child: const Text(
                'Reproduit un Move',
                style: TextStyle(
                  color: AppColors.diamond,
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
          if (video.caption.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              video.caption,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '#${video.category}',
            style: const TextStyle(color: AppColors.diamond, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CreatorAvatar extends ConsumerWidget {
  const _CreatorAvatar({required this.video, required this.isFollowing});

  final Video video;
  final bool isFollowing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creator = video.creator;
    return GestureDetector(
      onTap: () => ref.read(followControllerProvider(video.userId).notifier).toggle(),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.surfaceLight,
            child: Text(
              (creator?.username.isNotEmpty ?? false)
                  ? creator!.username[0].toUpperCase()
                  : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          if (!isFollowing)
            Positioned(
              bottom: -8,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 14, color: AppColors.background),
              ),
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
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}
