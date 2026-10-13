import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
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
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsControllerProvider.notifier).markAllAsRead(),
            child: const Text('Tout marquer lu'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const AppFullScreenLoader(),
        error: (error, _) => Center(
          child: Text(error is Failure ? error.message : 'Erreur de chargement.'),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Aucune notification pour l\'instant. Poste une vidéo ou rejoins un défi pour commencer à en recevoir.',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      onTap: () => _onTap(context, ref),
      tileColor: notification.isRead ? null : AppColors.primary.withValues(alpha: 0.06),
      leading: CircleAvatar(
        backgroundColor: AppColors.surfaceLight,
        child: Icon(_icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w700,
        ),
      ),
      subtitle: notification.body != null ? Text(notification.body!) : null,
      trailing: Text(
        Formatters.relativeTime(notification.createdAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
