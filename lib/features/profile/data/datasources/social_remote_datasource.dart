import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/errors/exceptions.dart';

class SocialRemoteDataSource {
  const SocialRemoteDataSource(this._client);

  final supa.SupabaseClient _client;

  Future<bool> isFollowing(String userId) async {
    final me = _client.auth.currentUser?.id;
    if (me == null || me == userId) return false;

    try {
      final row = await _client
          .from('follows')
          .select('id')
          .eq('follower_id', me)
          .eq('following_id', userId)
          .maybeSingle();
      return row != null;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> toggleFollow({
    required String userId,
    required bool currentlyFollowing,
  }) async {
    final me = _client.auth.currentUser?.id;
    if (me == null) {
      throw const AuthException('Connecte-toi pour suivre ce joueur.');
    }

    try {
      if (currentlyFollowing) {
        await _client.from('follows').delete().match({
          'follower_id': me,
          'following_id': userId,
        });
      } else {
        await _client.from('follows').insert({
          'follower_id': me,
          'following_id': userId,
        });
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
