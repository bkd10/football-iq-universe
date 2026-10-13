import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/errors/exceptions.dart';
import '../../../auth/data/models/profile_model.dart';
import '../../../videos/data/models/video_model.dart';

class SearchRemoteDataSource {
  const SearchRemoteDataSource(this._client);

  final supa.SupabaseClient _client;

  Future<List<ProfileModel>> searchPlayers(String query) async {
    try {
      final rows = await _client
          .from('profiles')
          .select(kPublicProfileColumns)
          .ilike('username', '%$query%')
          .order('stars', ascending: false)
          .limit(20);
      return rows.map(ProfileModel.fromJson).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<VideoModel>> searchMoves(String query) async {
    try {
      final rows = await _client
          .from('videos')
          .select()
          .eq('is_move', true)
          .eq('status', 'active')
          .ilike('move_name', '%$query%')
          .order('reproductions_count', ascending: false)
          .limit(20);
      return rows.map(VideoModel.fromJson).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
