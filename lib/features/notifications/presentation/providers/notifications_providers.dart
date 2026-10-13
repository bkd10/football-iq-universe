import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../data/datasources/notifications_remote_datasource.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/get_unread_notifications_count.dart';
import '../../domain/usecases/mark_all_notifications_read.dart';
import '../../domain/usecases/mark_notification_read.dart';

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>((ref) {
  return NotificationsRemoteDataSource(ref.watch(supabaseClientProvider));
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepositoryImpl(ref.watch(notificationsRemoteDataSourceProvider));
});

final getNotificationsUseCaseProvider = Provider(
  (ref) => GetNotifications(ref.watch(notificationsRepositoryProvider)),
);
final getUnreadNotificationsCountUseCaseProvider = Provider(
  (ref) => GetUnreadNotificationsCount(ref.watch(notificationsRepositoryProvider)),
);
final markNotificationReadUseCaseProvider = Provider(
  (ref) => MarkNotificationRead(ref.watch(notificationsRepositoryProvider)),
);
final markAllNotificationsReadUseCaseProvider = Provider(
  (ref) => MarkAllNotificationsRead(ref.watch(notificationsRepositoryProvider)),
);

/// Compteur de notifications non lues — pochoir rouge sur l'icône cloche.
final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final result = await ref.watch(getUnreadNotificationsCountUseCaseProvider)();
  return result.fold((_) => 0, (count) => count);
});

class NotificationsController extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    final result = await ref.read(getNotificationsUseCaseProvider)();
    return result.fold((failure) => throw failure, (list) => list);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(getNotificationsUseCaseProvider)();
      return result.fold((failure) => throw failure, (list) => list);
    });
  }

  Future<void> markAsRead(String notificationId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final index = current.indexWhere((n) => n.id == notificationId);
    if (index == -1 || current[index].isRead) return;

    final updated = [...current];
    updated[index] = updated[index].copyWith(isRead: true);
    state = AsyncData(updated);

    final result = await ref.read(markNotificationReadUseCaseProvider)(notificationId);
    result.fold((_) => state = AsyncData(current), (_) {});
    ref.invalidate(unreadNotificationsCountProvider);
  }

  Future<void> markAllAsRead() async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.map((n) => n.copyWith(isRead: true)).toList());

    final result = await ref.read(markAllNotificationsReadUseCaseProvider)();
    result.fold((_) => state = AsyncData(current), (_) {});
    ref.invalidate(unreadNotificationsCountProvider);
  }
}

final notificationsControllerProvider =
    AsyncNotifierProvider<NotificationsController, List<AppNotification>>(
  NotificationsController.new,
);
