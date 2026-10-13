import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/errors/exceptions.dart';
import '../models/app_notification_model.dart';

class NotificationsRemoteDataSource {
  const NotificationsRemoteDataSource(this._client);

  final supa.SupabaseClient _client;

  Future<List<AppNotificationModel>> getNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final rows = await _client
          .from('notifications')
          .select('*, actor:profiles!actor_id(username, avatar_url)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return rows.map(AppNotificationModel.fromJson).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<int> getUnreadCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    try {
      final response = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false)
          .count();
      return response.count;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
