import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/video/inline_video_controller.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../missions/domain/entities/daily_mission.dart';
import '../../../missions/presentation/providers/missions_providers.dart';
import '../../../profile/presentation/providers/social_providers.dart';
import '../../../videos/domain/entities/video.dart';
import '../../../videos/presentation/providers/video_providers.dart';
import '../../../videos/presentation/widgets/comments_sheet.dart';
import 'player_card_style.dart';

/// Une "page" du feed : la vidéo présentée comme une carte de joueur (note,
/// poste, stats du joueur) avec ses actions (Respect, Masterclass,
/// commentaires, partage, suivre) — voir PARTIE 8.1.
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
  bool _retried = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final controller = InlineVideoController(widget.video.videoUrl);
    _controller = controller;
    controller
      ..addListener(_onControllerChanged)
      ..onCompleted = _onVideoCompleted;
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
    final controller = _controller;
    // Une vidéo en erreur (réseau coupé...) est rechargée une fois quand on
    // revient dessus.
    if (controller != null && controller.hasError && !_retried) {
      _retried = true;
      controller.retry();
    }
    controller?.play();
    ref.read(missionsControllerProvider.notifier).startFullWatch(widget.video.id);
    _viewTimer?.cancel();
    _viewTimer = Timer(AppConstants.minWatchTimeForView, () {
      if (!mounted) return;
      ref.read(feedControllerProvider.notifier).registerView(widget.video.id);
      ref.read(missionsControllerProvider.notifier).registerVideoWatched();
    });
  }

  /// La vidéo a été regardée jusqu'au bout : compte pour la mission du jour.
  Future<void> _onVideoCompleted() async {
    if (!widget.isActive) return;
    final result = await ref
        .read(missionsControllerProvider.notifier)
        .completeFullWatch(widget.video.id, _controller?.durationSeconds);
    if (!mounted || result == null || !result.rewardAwarded) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🎉 +${result.reward} Ballons : ${DailyMission.fullWatchTarget} vidéos '
          'regardées en entier aujourd’hui !',
        ),
      ),
    );
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
      ref.read(feedControllerProvider.notifier).toggleLike(widget.video.id, isMasterclass: false);
    }
    setState(() => _heartBurstId++);
  }

  void _share() {
    final video = widget.video;
    SharePlus.instance.share(
      ShareParams(
        text: video.isMove
            ? 'Regarde le Move "${video.moveName}" sur Football IQ Universe : ${video.videoUrl}'
            : 'Regarde cette vidéo sur Football IQ Universe : ${video.videoUrl}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final style = PlayerCardStyle.forPoints(video.creator?.likesReceivedCount ?? 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: AnimatedScale(
        scale: widget.isActive ? 1 : 0.94,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: style.gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: style.gradient[1].withValues(alpha: widget.isActive ? 0.35 : 0.1),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                Expanded(child: _buildVideoPanel(style)),
                _buildIdentity(context, style),
                _buildStats(style),
                _buildActions(style),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPanel(PlayerCardStyle style) {
    final video = widget.video;
    final controller = _controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: GestureDetector(
        onTap: _togglePlayPause,
        onDoubleTap: _onDoubleTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildVideoLayer(),
            Positioned(
              left: 10,
              top: 10,
              child: _RatingBadge(
                rating: playerRating(video.creator),
                form: video.creator?.formScore ?? 0,
                position: positionShort(video.creator?.position),
                style: style,
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: _GlassButton(
                icon: (controller?.isMuted ?? false) ? Icons.volume_off : Icons.volume_up,
                onTap: _toggleSound,
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: Wrap(
                spacing: 6,
                children: [
                  _GlassChip(text: '#${video.category}'),
                  if (video.isMove)
                    GestureDetector(
                      onTap: () => context.push(RouteNames.moveDetailPath(video.id)),
                      child: _GlassChip(
                        text: '🔥 Move : ${video.moveName ?? 'original'}',
                        highlight: true,
                      ),
                    )
                  else if (video.originalMoveId != null)
                    GestureDetector(
                      onTap: () => context.push(RouteNames.moveDetailPath(video.originalMoveId!)),
                      child: const _GlassChip(text: 'Reproduit un Move'),
                    ),
                ],
              ),
            ),
            Center(
              child: KeyedSubtree(
                key: ValueKey(_heartBurstId),
                child: _heartBurstId == 0
                    ? const SizedBox.shrink()
                    : const Text('👏', style: TextStyle(fontSize: 84))
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
          ],
        ),
      ),
    );
  }

  Widget _buildIdentity(BuildContext context, PlayerCardStyle style) {
    final video = widget.video;
    final creator = video.creator;
    final followState = ref.watch(followControllerProvider(video.userId));
    final isFollowing = followState.valueOrNull ?? false;
    final isMine = ref.read(supabaseClientProvider).auth.currentUser?.id == video.userId;
    final meta = [
      if (countryFlag(creator?.country) != null) countryFlag(creator?.country)!,
      if (creator?.position != null) creator!.position!,
      if (footLabel(creator?.preferredFoot) != null) footLabel(creator?.preferredFoot)!,
      'Carte ${style.label}',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 6, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push(RouteNames.otherProfilePath(video.userId)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          (creator?.displayName?.isNotEmpty ?? false)
                              ? creator!.displayName!.toUpperCase()
                              : (creator?.username ?? 'Joueur').toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.barlowCondensed(
                            color: style.ink,
                            fontSize: 24,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (creator?.isVerified ?? false) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.verified, size: 16, color: style.ink),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: style.inkSoft, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  if (video.caption.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        video.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: style.ink, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!isMine) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => ref.read(followControllerProvider(video.userId).notifier).toggle(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isFollowing ? Colors.transparent : style.panel,
                  border: Border.all(color: isFollowing ? style.ink : style.panel, width: 1.5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isFollowing ? 'Suivi ✓' : 'Suivre',
                  style: TextStyle(
                    color: isFollowing ? style.ink : style.onPanel,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStats(PlayerCardStyle style) {
    final creator = widget.video.creator;
    final stats = [
      ('VID', creator?.videosCount ?? 0),
      ('RESPECT', creator?.likesReceivedCount ?? 0),
      ('STARS', creator?.stars ?? 0),
      ('DÉFIS', creator?.challengesWonCount ?? 0),
      ('MOVES', creator?.movesCreatedCount ?? 0),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          for (final (label, value) in stats)
            Expanded(
              child: Column(
                children: [
                  Text(
                    Formatters.compactCount(value),
                    style: GoogleFonts.barlowCondensed(
                      color: style.ink,
                      fontSize: 19,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: style.inkSoft,
                      fontSize: 9.5,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(PlayerCardStyle style) {
    final video = widget.video;
    return Row(
      children: [
        _CardAction(
          style: style,
          icon: '👏',
          label: 'Respect',
          count: video.likesCount,
          active: video.hasLiked,
          onTap: () {
            if (!video.hasLiked) setState(() => _heartBurstId++);
            ref.read(feedControllerProvider.notifier).toggleLike(video.id, isMasterclass: false);
          },
        ),
        const SizedBox(width: 5),
        _CardAction(
          style: style,
          icon: '⭐',
          label: 'Masterclass',
          count: video.masterclassCount,
          active: video.hasMasterclassed,
          onTap: () =>
              ref.read(feedControllerProvider.notifier).toggleLike(video.id, isMasterclass: true),
        ),
        const SizedBox(width: 5),
        _CardAction(
          style: style,
          icon: '💬',
          label: 'Avis',
          count: video.commentsCount,
          onTap: () => CommentsSheet.show(context, video.id),
        ),
        const SizedBox(width: 5),
        _CardAction(style: style, icon: '↗', label: 'Partager', onTap: _share),
      ],
    );
  }

  Widget _buildVideoLayer() {
    final controller = _controller;
    if (controller != null && controller.hasError) {
      final detail = controller.errorDetail;
      return ColoredBox(
        color: AppColors.surface,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_outlined, color: AppColors.textSecondary, size: 40),
              const SizedBox(height: 8),
              const Text(
                'Vidéo pas encore lisible',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              if (detail != null)
                Text(detail, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                onPressed: () {
                  controller.retry();
                  if (widget.isActive) controller.play();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    return ColoredBox(
      color: const Color(0xFF0B1A12),
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
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({
    required this.rating,
    required this.form,
    required this.position,
    required this.style,
  });

  final int rating;

  /// Forme sur 30 jours : flèche verte si elle porte la note, rouge si
  /// elle la fait baisser.
  final int form;
  final String position;
  final PlayerCardStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
      decoration: BoxDecoration(
        color: style.panel.withValues(alpha: 0.92),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(10), bottom: Radius.circular(20)),
        border: Border.all(color: style.onPanel.withValues(alpha: 0.8), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            '$rating',
            style: GoogleFonts.barlowCondensed(
              color: style.onPanel,
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            position,
            style: GoogleFonts.barlowCondensed(
              color: style.onPanel,
              fontSize: 13,
              height: 1.1,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (form != 0)
            Text(
              form > 0 ? '▲ +$form' : '▼ $form',
              style: TextStyle(
                color: form > 0 ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                fontSize: 10,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.text, this.highlight = false});

  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primary.withValues(alpha: 0.9) : Colors.black54,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: highlight ? AppColors.background : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.style,
    required this.icon,
    required this.label,
    required this.onTap,
    this.count,
    this.active = false,
  });

  final PlayerCardStyle style;
  final String icon;
  final String label;
  final int? count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? style.panel : style.onPanel;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : style.panel,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                count == null ? icon : '$icon ${Formatters.compactCount(count!)}',
                style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 1),
              Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
