import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/errors/exceptions.dart';
import '../models/scout_player_result_model.dart';

class ScoutingRemoteDataSource {
  const ScoutingRemoteDataSource(this._client);

  final supa.SupabaseClient _client;

  Future<List<ScoutPlayerResultModel>> searchPlayers({
    String? query,
    String? position,
    String? country,
  }) async {
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'scout_search_players',
        params: {
          'p_query': query,
          'p_position': position,
          'p_country': country,
        },
      );
      return rows
          .cast<Map<String, dynamic>>()
          .map(ScoutPlayerResultModel.fromJson)
          .toList();
    } on supa.PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> startTrial() async {
    try {
      await _client.rpc<Map<String, dynamic>>('start_scout_trial');
    } on supa.PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<Map<String, dynamic>?> getMySubscription() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Aucune session active.');
    }
    try {
      return await _client
          .from('scout_subscriptions')
          .select()
          .eq('scout_id', user.id)
          .maybeSingle();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Exception _mapRpcError(supa.PostgrestException e) {
    if (e.code == '28000') {
      return AuthException(e.message);
    }
    return ServerException(e.message);
  }
}
