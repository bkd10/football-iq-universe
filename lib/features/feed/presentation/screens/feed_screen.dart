import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/economy_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../../economy/presentation/providers/economy_providers.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../videos/presentation/providers/video_providers.dart';
import '../widgets/feed_video_tile.dart';

enum _FeedTab { forYou, following, trending }

/// Feed vidéo plein écran — voir PARTIE 8.1. "Ouverture" (algorithme Talent
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
  }

  /// Réclame le bonus de connexion quotidienne une fois par session (voir
  /// `award_coins` — la RPC rejette silencieusement si déjà réclamé
  /// aujourd'hui, ce qui est l'état normal la plupart du temps).
  Future<void> _claimDailyLogin() async {
    final result = await ref
        .read(economyControllerProvider.notifier)
        .awardCoins(EconomyReason.dailyLogin);
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
      context.showSnackBar('Bientôt disponible.');
      return;
    }
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          feedAsync.when(
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
                return const Center(
                  child: Text(
                    'Aucune vidéo pour l\'instant — sois le premier à publier !',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: () => ref.read(feedControllerProvider.notifier).refresh(),
                child: PageView.builder(
                  controller: _pageController,
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              // Un `Row`/`Expanded` plutôt qu'un `Stack`+`Positioned` : sur
              // un écran étroit (360px), un Stack centrant les 3 onglets
              // sur toute la largeur les faisait chevaucher les icônes
              // positionnées à droite. Ici, les onglets ne peuvent grandir
              // que dans l'espace réellement libre à gauche des icônes, et
              // défilent horizontalement plutôt que déborder si besoin.
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FeedTabLabel(
                            label: 'Vestiaire',
                            active: _tab == _FeedTab.following,
                            onTap: () => _selectTab(_FeedTab.following),
                          ),
                          const SizedBox(width: 16),
                          _FeedTabLabel(
                            label: 'Ouverture',
                            active: _tab == _FeedTab.forYou,
                            onTap: () => _selectTab(_FeedTab.forYou),
                          ),
                          const SizedBox(width: 16),
                          _FeedTabLabel(
                            label: 'Tendances',
                            active: _tab == _FeedTab.trending,
                            onTap: () => _selectTab(_FeedTab.trending),
                          ),
                        ],
                      ),
                    ),
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
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white60,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          if (active)
            Container(width: 18, height: 2, color: AppColors.primary),
        ],
      ),
    );
  }
}
