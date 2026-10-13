import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/errors/exceptions.dart';
import '../models/daily_mission_model.dart';

class MissionsRemoteDataSource {
  const MissionsRemoteDataSource(this._client);

  final supa.SupabaseClient _client;

  Future<DailyMissionModel> getTodayMission() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Connecte-toi pour voir tes missions.');
    }

    try {
      final today = DateTime.now();
      final todayStr =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final row = await _client
          .from('daily_missions')
          .select()
          .eq('user_id', userId)
          .eq('mission_date', todayStr)
          .maybeSingle();

      // Aucune ligne encore créée aujourd'hui = aucune mission complétée ;
      // les RPC (`award_coins`, `increment_videos_watched`) créent la ligne
      // au premier événement de la journée.
      return row != null
          ? DailyMissionModel.fromJson(row)
          : DailyMissionModel(missionDate: DateTime(today.year, today.month, today.day));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> incrementVideosWatched() async {
    try {
      final today = DateTime.now();
      final todayStr =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      await _client.rpc<void>(
        'increment_videos_watched',
        params: {'p_local_date': todayStr},
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
