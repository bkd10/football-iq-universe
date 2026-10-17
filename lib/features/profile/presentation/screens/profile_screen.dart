import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/string_extensions.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../../../shared/widgets/video_thumbnail_tile.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../messaging/presentation/providers/messaging_providers.dart';
import '../../../moderation/presentation/widgets/report_content_sheet.dart';
import '../../../videos/presentation/providers/video_providers.dart';
import '../../domain/entities/user_badge.dart';
import '../providers/badges_providers.dart';
import '../providers/social_providers.dart';

/// Mon Profil / Football Passport — voir PARTIE 8.4 : identité, niveau,
/// Ballons/Stars/Football IQ, les 5 dimensions, puis onglets Vidéos / Moves
/// créés / Badges.
///
/// Sert aussi d'écran "Other Profile" (PARTIE 9.2, écran 23) quand [userId]
/// est renseigné : même corps d'écran en lecture seule, avec un bouton
/// Suivre à la place des actions propriétaire (missions/wallet/déconnexion).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({this.userId, super.key});

  /// `null` = mon propre profil. Sinon, Football Passport public de ce
  /// joueur.
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMe = userId == null;
    final profileAsync = isMe
        ? ref.watch(currentProfileProvider)
        : ref.watch(otherProfileProvider(userId!));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isMe ? 'Mon Profil'.tr : 'Football Passport'),
          actions: isMe
              ? [
                  IconButton(
                    icon: const Icon(Icons.local_fire_department_outlined),
                    tooltip: 'Missions du jour'.tr,
                    onPressed: () => context.push(RouteNames.dailyMissions),
                  ),
                  IconButton(
                    icon: const Icon(Icons.paid_outlined),
                    tooltip: 'Wallet'.tr,
                    onPressed: () => context.push(RouteNames.wallet),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Réglages'.tr,
                    onPressed: () => context.push(RouteNames.settings),
                  ),
                ]
              : [
                  IconButton(
                    icon: const Icon(Icons.flag_outlined),
                    tooltip: 'Signaler ce profil'.tr,
                    onPressed: () => showReportContentSheet(
                      context,
                      targetType: 'profile',
                      targetId: userId!,
                    ),
                  ),
                ],
        ),
        body: profileAsync.when(
          loading: () => const AppFullScreenLoader(),
          error: (error, _) => Center(
            child: Text(error is Failure ? error.message : '$error'),
          ),
          data: (profile) {
            if (profile == null) {
              return Center(
                child: Text(
                  isMe ? '' : 'Ce joueur est introuvable.'.tr,
                  style: context.textTheme.bodyLarge,
                ),
              );
            }
            return _ProfileBody(profile: profile, isMe: isMe);
          },
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile, required this.isMe});

  final Profile profile;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelColor = AppColors.forLevel(profile.level);

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.surface,
                  child: Text(
                    profile.username.isNotEmpty
                        ? profile.username[0].toUpperCase()
                        : '?',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  profile.displayName ?? profile.username,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                Text(
                  '@${profile.username}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: levelColor),
                  ),
                  child: Text(
                    profile.level.fromSnakeCaseToTitle,
                    style: TextStyle(color: levelColor, fontWeight: FontWeight.w600),
                  ),
                ),
                if (!isMe) ...[
                  const SizedBox(height: AppSpacing.md),
                  _FollowButton(userId: profile.id),
                ],
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (isMe)
                      _StatTile(label: 'Ballons'.tr, value: profile.coins, color: AppColors.gold),
                    _StatTile(label: 'Stars'.tr, value: profile.stars, color: AppColors.primary),
                    _StatTile(label: 'Football IQ', value: profile.footballIqTotal),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _IqBars(profile: profile),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CountTile(label: 'Abonnés'.tr, value: profile.followersCount),
                    _CountTile(label: 'Abonnements'.tr, value: profile.followingCount),
                    _CountTile(label: 'Vidéos'.tr, value: profile.videosCount),
                  ],
                ),
                if (!isMe) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _ContactPlayerButton(playerId: profile.id),
                ],
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            TabBar(
              tabs: [
                Tab(text: 'Vidéos'.tr),
                Tab(text: 'Moves'.tr),
                Tab(text: 'Badges'.tr),
              ],
            ),
          ),
        ),
      ],
      body: TabBarView(
        children: [
          _VideosGrid(userId: profile.id, movesOnly: false),
          _VideosGrid(userId: profile.id, movesOnly: true),
          _BadgesTab(userId: profile.id),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(color: AppColors.background, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

class _IqBars extends StatelessWidget {
  const _IqBars({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final dimensions = {
      'Technique': profile.iqTechnique,
      'Créativité': profile.iqCreativity,
      'Popularité': profile.iqPopularity,
      'Régularité': profile.iqConsistency,
      'Tactique': profile.iqTactical,
    };
    final maxValue = dimensions.values.fold(1, (a, b) => a > b ? a : b);

    return Column(
      children: dimensions.entries.map((entry) {
        final rawRatio = maxValue == 0 ? 0.0 : entry.value / maxValue;
        final ratio = rawRatio < 0 ? 0.0 : (rawRatio > 1 ? 1.0 : rawRatio);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                child: Text(entry.key.tr, style: context.textTheme.bodySmall),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 32,
                child: Text(
                  '${entry.value}',
                  textAlign: TextAlign.end,
                  style: context.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _VideosGrid extends ConsumerWidget {
  const _VideosGrid({required this.userId, required this.movesOnly});

  final String userId;
  final bool movesOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(userVideosProvider(userId));

    return videosAsync.when(
      loading: () => const Center(child: AppLoader()),
      error: (error, _) => Center(
        child: Text(error is Failure ? error.message : 'Erreur de chargement.'.tr),
      ),
      data: (videos) {
        final filtered = movesOnly ? videos.where((v) => v.isMove).toList() : videos;
        if (filtered.isEmpty) {
          return Center(
            child: Text(
              movesOnly
                  ? 'Aucun Move créé pour l\'instant.'.tr
                  : 'Aucune vidéo pour l\'instant.'.tr,
              style: context.textTheme.bodyMedium,
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.xs),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 0.72,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) => VideoThumbnailTile(
            video: filtered[index],
            onTap: () => context.push(RouteNames.videoDetailPath(filtered[index].id)),
          ),
        );
      },
    );
  }
}

class _BadgesTab extends ConsumerWidget {
  const _BadgesTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(userBadgesProvider(userId));

    return badgesAsync.when(
      loading: () => const Center(child: AppLoader()),
      error: (error, _) => Center(
        child: Text(error is Failure ? error.message : 'Erreur de chargement.'.tr),
      ),
      data: (badges) {
        if (badges.isEmpty) {
          return Center(
            child: Text(
              'Aucun badge débloqué pour l\'instant.'.tr,
              style: context.textTheme.bodyMedium,
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.85,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) => _BadgeTile(badge: badges[index]),
        );
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final UserBadge badge;

  static const _rarityColors = {
    'common': AppColors.bronze,
    'rare': AppColors.silver,
    'epic': AppColors.gold,
    'legendary': AppColors.diamond,
  };

  @override
  Widget build(BuildContext context) {
    final color = _rarityColors[badge.rarity] ?? AppColors.bronze;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, color: color, size: 32),
          const SizedBox(height: AppSpacing.xs),
          Text(
            badge.name.trServer,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _FollowButton extends ConsumerWidget {
  const _FollowButton({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingAsync = ref.watch(followControllerProvider(userId));
    final isFollowing = followingAsync.valueOrNull ?? false;

    return SizedBox(
      width: 160,
      child: isFollowing
          ? OutlinedButton(
              onPressed: () =>
                  ref.read(followControllerProvider(userId).notifier).toggle(),
              child: Text('Abonné ✓'.tr),
            )
          : FilledButton(
              onPressed: () =>
                  ref.read(followControllerProvider(userId).notifier).toggle(),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('Suivre'.tr, style: const TextStyle(color: AppColors.background)),
            ),
    );
  }
}

/// Réservé aux recruteurs vérifiés (abonnement actif requis, voir
/// `request_scout_contact`) — pour tout autre visiteur, reste une simple
/// information plutôt qu'un bouton qui ne ferait rien.
class _ContactPlayerButton extends ConsumerWidget {
  const _ContactPlayerButton({required this.playerId});

  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myRole = ref.watch(currentProfileProvider).valueOrNull?.role;
    final isScout = myRole == 'scout';
    final isLoading = ref.watch(messagingActionsControllerProvider).isLoading;

    return OutlinedButton(
      onPressed: isLoading
          ? null
          : () async {
              if (!isScout) {
                context.showSnackBar(
                  'Réservé aux recruteurs vérifiés · contact médié pour les mineurs.'.tr,
                );
                return;
              }
              final status = await ref
                  .read(messagingActionsControllerProvider.notifier)
                  .requestScoutContact(playerId);
              if (!context.mounted) return;
              if (status == null) {
                final failure = ref.read(messagingActionsControllerProvider).error;
                context.showSnackBar(
                  failure is Failure ? failure.message : 'Échec de la demande de contact.'.tr,
                  isError: true,
                );
              } else if (status == 'pending_guardian_approval') {
                context.showSnackBar(
                  'Ce joueur est mineur : demande envoyée, en attente d\'approbation de son tuteur.'.tr,
                );
              } else {
                context.showSnackBar('Demande de contact envoyée.'.tr);
                unawaited(context.push(RouteNames.inbox));
              }
            },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.diamond),
        foregroundColor: AppColors.diamond,
      ),
      child: Text(isScout ? 'Demander le contact'.tr : 'Contacter ce joueur'.tr),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.color = AppColors.textPrimary,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: AppTypography.stat(color: color)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
