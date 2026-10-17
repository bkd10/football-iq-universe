import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/social_providers.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notifications_providers.dart';

/// Écran "Notifications" (PARTIE 9.2, écran 31) — nouvel abonné, like,
/// commentaire, Move reproduit, badge débloqué, défi gagné/terminé.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'.tr),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsControllerProvider.notifier).markAllAsRead(),
            child: Text('Tout marquer lu'.tr),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const AppFullScreenLoader(),
        error: (error, _) => Center(
          child: Text(error is Failure ? error.message : 'Erreur de chargement.'.tr),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Aucune notification pour l\'instant. Poste une vidéo ou rejoins un défi pour commencer à en recevoir.'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(notificationsControllerProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _NotificationTile(notification: notifications[index]),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  IconData get _icon {
    switch (notification.type) {
      case 'new_follower':
        return Icons.person_add_alt_1;
      case 'like':
        return Icons.favorite;
      case 'masterclass':
        return Icons.star;
      case 'comment':
        return Icons.mode_comment;
      case 'move_reproduced':
        return Icons.refresh;
      case 'badge_earned':
        return Icons.military_tech;
      case 'challenge_won':
        return Icons.emoji_events;
      case 'challenge_ended':
        return Icons.timer_off;
      case 'scout_interest':
        return Icons.visibility;
      case 'contact_approved':
        return Icons.mark_email_read_outlined;
      case 'moderation':
        return Icons.shield_outlined;
      default:
        return Icons.notifications;
    }
  }

  void _onTap(BuildContext context, WidgetRef ref) {
    ref.read(notificationsControllerProvider.notifier).markAsRead(notification.id);

    switch (notification.referenceType) {
      case 'video':
        if (notification.referenceId != null) {
          context.push(RouteNames.videoDetailPath(notification.referenceId!));
        }
      case 'profile':
        if (notification.referenceId != null) {
          context.push(RouteNames.otherProfilePath(notification.referenceId!));
        }
      case 'challenge':
        if (notification.referenceId != null) {
          context.push(RouteNames.challengeDetailPath(notification.referenceId!));
        }
      case 'conversation':
        if (notification.referenceId != null) {
          context.push(RouteNames.conversationPath(notification.referenceId!));
        }
      case 'badge':
        context.push(RouteNames.profile);
    }
  }

  /// Notifications venant d'un autre joueur (réaction, commentaire,
  /// abonnement...) : on peut ouvrir son profil et le suivre directement.
  bool get _fromPlayer =>
      notification.actorId != null &&
      const {'new_follower', 'like', 'masterclass', 'comment', 'move_reproduced'}
          .contains(notification.type);

  void _openActor(BuildContext context, WidgetRef ref) {
    ref.read(notificationsControllerProvider.notifier).markAsRead(notification.id);
    context.push(RouteNames.otherProfilePath(notification.actorId!));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(currentProfileProvider).valueOrNull?.id;
    final showActor = _fromPlayer && notification.actorId != myId;
    final avatarUrl = notification.actorAvatarUrl;
    final username = notification.actorUsername;

    final icon = CircleAvatar(
      backgroundColor: AppColors.surfaceLight,
      child: Icon(_icon, color: AppColors.primary, size: 20),
    );

    return ListTile(
      onTap: () => _onTap(context, ref),
      tileColor: notification.isRead ? null : AppColors.primary.withValues(alpha: 0.06),
      leading: showActor
          ? GestureDetector(
              onTap: () => _openActor(context, ref),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.surfaceLight,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Text(
                            username != null && username.isNotEmpty
                                ? username[0].toUpperCase()
                                : '?',
                          )
                        : null,
                  ),
                  PositionedDirectional(
                    end: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_icon, color: AppColors.primary, size: 12),
                    ),
                  ),
                ],
              ),
            )
          : icon,
      title: Text(
        notification.title.trServer,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w700,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notification.body != null) Text(notification.body!.trServer),
          if (showActor && username != null)
            GestureDetector(
              onTap: () => _openActor(context, ref),
              child: Text(
                '@{username} · voir le profil'.trArgs({'username': username}),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(height: 2),
          Text(
            Formatters.relativeTime(notification.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: showActor ? _NotificationFollowButton(userId: notification.actorId!) : null,
    );
  }
}

class _NotificationFollowButton extends ConsumerWidget {
  const _NotificationFollowButton({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingAsync = ref.watch(followControllerProvider(userId));
    if (!followingAsync.hasValue) return const SizedBox(width: 88);
    final isFollowing = followingAsync.value!;
    void toggle() => ref.read(followControllerProvider(userId).notifier).toggle();

    return SizedBox(
      width: 88,
      child: isFollowing
          ? OutlinedButton(
              onPressed: toggle,
              style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
              child: Text('Abonné ✓'.tr, style: const TextStyle(fontSize: 12)),
            )
          : FilledButton(
              onPressed: toggle,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
              ),
              child: Text(
                'Suivre'.tr,
                style: const TextStyle(color: AppColors.background, fontSize: 12),
              ),
            ),
    );
  }
}
