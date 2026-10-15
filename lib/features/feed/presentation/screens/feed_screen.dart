import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/economy_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../../economy/presentation/providers/economy_providers.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../videos/presentation/providers/video_providers.dart';
import '../widgets/feed_guide_sheet.dart';
import '../widgets/feed_video_tile.dart';

enum _FeedTab { forYou, following, trending }

/// Feed vidéo : une carte de joueur par vidéo, qu'on fait défiler — voir
/// PARTIE 8.1. "Ouverture" (algorithme Talent
/// First) est le feed branché en MVP ; "Tendances" ouvre les Moves du moment
/// (PARTIE 9.2) ; "Vestiaire" est prévu mais pas encore implémenté
/// (PARTIE 20, Semaines à venir).
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _pageController = PageController();
  _FeedTab _tab = _FeedTab.forYou;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _claimDailyLogin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FeedGuideSheet.showOnce(context);
    });
  }

  /// Réclame le bonus de connexion quotidienne une fois par session (voir
  /// `award_coins` — la RPC rejette silencieusement si déjà réclamé
  /// aujourd'hui, ce qui est l'état normal la plupart du temps).
  Future<void> _claimDailyLogin() async {
    final result =
        await ref.read(economyControllerProvider.notifier).awardCoins(EconomyReason.dailyLogin);
    if (!mounted) return;
    result.fold((_) {}, (newBalance) {
      context.showSnackBar('🎉 Bonus de connexion quotidienne récupéré !');
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index, int total) {
    setState(() => _activeIndex = index);
    if (index >= total - 3) {
      ref.read(feedControllerProvider.notifier).loadMore();
    }
  }

  void _selectTab(_FeedTab tab) {
    if (tab == _FeedTab.trending) {
      context.push(RouteNames.trendingMoves);
      return;
    }
    if (tab == _tab) return;
    if (tab != _FeedTab.forYou) {
      context.showSnackBar(
        'Le Vestiaire arrive bientôt : tu y verras les vidéos des joueurs que tu suis.',
      );
      return;
    }
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedControllerProvider);

    return Scaffold(
      backgroundColor: _pitch,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1.2),
            radius: 1.4,
            colors: [Color(0xFF1C4A30), _pitch],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: feedAsync.when(
                  loading: () => const Center(child: AppLoader()),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        error is Failure ? error.message : 'Impossible de charger le feed.',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  data: (videos) {
                    if (videos.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('⚽', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(
                                'LE TERRAIN EST LIBRE',
                                style: GoogleFonts.barlowCondensed(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Publie la première vidéo et prends la première carte.',
                                style: TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onRefresh: () => ref.read(feedControllerProvider.notifier).refresh(),
                      child: PageView.builder(
                        controller: _pageController,
                        // Sur ordinateur aussi, on fait défiler les cartes à la souris.
                        scrollBehavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: PointerDeviceKind.values.toSet(),
                        ),
                        scrollDirection: Axis.vertical,
                        itemCount: videos.length,
                        onPageChanged: (index) => _onPageChanged(index, videos.length),
                        itemBuilder: (context, index) {
                          return FeedVideoTile(
                            video: videos[index],
                            isActive: index == _activeIndex,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text.rich(
                TextSpan(
                  children: const [
                    TextSpan(text: 'FOOTBALL '),
                    TextSpan(text: 'IQ', style: TextStyle(color: _lime)),
                  ],
                  style: GoogleFonts.barlowCondensed(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.help_outline, color: Colors.white),
                tooltip: 'Comment ça marche',
                onPressed: () => FeedGuideSheet.show(context),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => context.push(RouteNames.search),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.mail_outline, color: Colors.white),
                tooltip: 'Messages',
                onPressed: () => context.push(RouteNames.inbox),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final unread = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
                  return IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      child: const Icon(Icons.notifications_outlined, color: Colors.white),
                    ),
                    onPressed: () => context.push(RouteNames.notifications),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FeedTabLabel(
                  label: 'Vestiaire',
                  active: _tab == _FeedTab.following,
                  onTap: () => _selectTab(_FeedTab.following),
                ),
                const SizedBox(width: 8),
                _FeedTabLabel(
                  label: 'Ouverture',
                  active: _tab == _FeedTab.forYou,
                  onTap: () => _selectTab(_FeedTab.forYou),
                ),
                const SizedBox(width: 8),
                _FeedTabLabel(
                  label: 'Tendances',
                  active: _tab == _FeedTab.trending,
                  onTap: () => _selectTab(_FeedTab.trending),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _tabHints[_tab]!,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

const _tabHints = {
  _FeedTab.forYou: 'Les talents à découvrir, peu importe leurs abonnés.',
  _FeedTab.following: 'Les vidéos des joueurs que tu suis.',
  _FeedTab.trending: 'Les Moves du moment.',
};

const _pitch = Color(0xFF0D2418);
const _lime = Color(0xFFD8F34A);

class _FeedTabLabel extends StatelessWidget {
  const _FeedTabLabel({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          border: Border.all(color: active ? Colors.white : Colors.white30),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? _pitch : Colors.white70,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
