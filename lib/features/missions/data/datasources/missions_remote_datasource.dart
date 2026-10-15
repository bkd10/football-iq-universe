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

  /// Début du visionnage d'une vidéo du feed (compte pour la mission
  /// « regarder des vidéos en entier »).
  Future<void> startVideoWatch(String videoId) async {
    try {
      await _client.rpc<void>(
        'start_video_watch',
        params: {'p_video_id': videoId, 'p_local_date': _todayString()},
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// La vidéo est arrivée au bout. Le serveur vérifie le temps réellement
  /// passé dessus et verse la récompense quand l'objectif du jour est atteint.
  Future<Map<String, dynamic>> completeVideoWatch(String videoId, double? durationSeconds) async {
    try {
      final result = await _client.rpc<Map<String, dynamic>>(
        'complete_video_watch',
        params: {
          'p_video_id': videoId,
          'p_duration_seconds': durationSeconds,
          'p_local_date': _todayString(),
        },
      );
      return result;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  String _todayString() {
    final today = DateTime.now();
    return '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
  }
}
