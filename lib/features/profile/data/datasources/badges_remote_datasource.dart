import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/errors/exceptions.dart';
import '../models/user_badge_model.dart';

class BadgesRemoteDataSource {
  const BadgesRemoteDataSource(this._client);

  final supa.SupabaseClient _client;

  Future<List<UserBadgeModel>> getUserBadges(String userId) async {
    try {
      final rows = await _client
          .from('user_badges')
          .select('earned_at, badge:badges(code, name, description, icon_url, category, rarity)')
          .eq('user_id', userId)
          .order('earned_at', ascending: false);

      return rows
          .map((row) => UserBadgeModel.fromJson(row))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
