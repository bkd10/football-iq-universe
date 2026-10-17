import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/battle_opponent.dart';
import '../models/challenge_model.dart';
import '../models/challenge_participation_model.dart';

const _creatorSelect = 'id, username, display_name, avatar_url, level, is_verified';

/// `!creator_id`/`!record_holder_id` désambiguïsent l'embed PostgREST :
/// `challenges` a plusieurs clés étrangères vers `profiles`
/// (creator_id, opponent_id, record_holder_id, sponsor_id, winner_id).
const _challengeSelect =
    '*, creator:profiles!creator_id($_creatorSelect), '
    'record_holder:profiles!record_holder_id($_creatorSelect), '
    'opponent:profiles!opponent_id($_creatorSelect)';

class ChallengeRemoteDataSource {
  const ChallengeRemoteDataSource(this._client);

  final supa.SupabaseClient _client;

  Future<List<ChallengeModel>> getChallenges({String? type}) async {
    try {
      final baseQuery = _client.from('challenges').select(_challengeSelect);
      final filtered = type != null ? baseQuery.eq('type', type) : baseQuery;

      final rows = await filtered
          .order('status', ascending: true)
          .order('end_date', ascending: true);

      return rows
          .map((row) => ChallengeModel.fromJson(row))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<ChallengeModel?> getChallengeById(String challengeId) async {
    try {
      final row = await _client
          .from('challenges')
          .select(_challengeSelect)
          .eq('id', challengeId)
          .maybeSingle();

      return row != null ? ChallengeModel.fromJson(row) : null;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<ChallengeParticipationModel>> getParticipations(
    String challengeId,
  ) async {
    try {
      final rows = await _client
          .from('challenge_participations')
          .select(
            '*, participant:profiles!user_id($_creatorSelect), '
            'video:videos!video_id(id, video_url, thumbnail_url)',
          )
          .eq('challenge_id', challengeId)
          .order('votes_count', ascending: false);

      return rows
          .map(
            (row) =>
                ChallengeParticipationModel.fromJson(row),
          )
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Ensemble des `user_id` des participants pour qui l'utilisateur courant
  /// a déjà voté dans ce défi (au plus un, vu UNIQUE(challenge_id, voter_id),
  /// mais renvoyé en Set pour un lookup direct côté repository).
  Future<Set<String>> getMyVotes(String challengeId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    try {
      final rows = await _client
          .from('challenge_votes')
          .select('participant_id')
          .eq('challenge_id', challengeId)
          .eq('voter_id', userId);

      return rows.map((row) => row['participant_id'] as String).toSet();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> joinChallenge({
    required String challengeId,
    required String videoId,
  }) async {
    try {
      await _client.rpc<void>(
        'join_challenge',
        params: {'p_challenge_id': challengeId, 'p_video_id': videoId},
      );
    } on supa.PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> voteForParticipant({
    required String challengeId,
    required String participantUserId,
  }) async {
    try {
      await _client.rpc<void>(
        'vote_for_participant',
        params: {
          'p_challenge_id': challengeId,
          'p_participant_id': participantUserId,
        },
      );
    } on supa.PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<ChallengeModel> createChallenge({
    required String title,
    required String description,
    required String type,
    String? category,
    required DateTime endDate,
    int prizePool = 0,
    int? maxParticipants,
    String? recordUnit,
    String? prizeDescription,
    DateTime? startDate,
  }) async {
    try {
      final result = await _client.rpc<Map<String, dynamic>>(
        'create_challenge',
        params: {
          'p_title': title,
          'p_description': description,
          'p_type': type,
          'p_category': category,
          'p_end_date': endDate.toUtc().toIso8601String(),
          'p_prize_pool': prizePool,
          'p_max_participants': maxParticipants,
          'p_record_unit': recordUnit,
          'p_prize_description': prizeDescription,
          'p_start_date': startDate?.toUtc().toIso8601String(),
        },
      );
      final challengeId = result['challenge_id'] as String;
      final created = await getChallengeById(challengeId);
      if (created == null) {
        throw const ServerException('Défi créé mais introuvable.');
      }
      return created;
    } on supa.PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  /// Battle 1 contre 1 : le créateur mise [stake] Ballons avec sa vidéo ;
  /// l'adversaire (désigné, ou le premier qui relève) mise la même somme.
  Future<ChallengeModel> createBattle({
    required String title,
    required String rules,
    required int stake,
    required String videoId,
    required DateTime endDate,
    String? opponentUsername,
    bool randomOpponent = false,
  }) async {
    try {
      final result = await _client.rpc<Map<String, dynamic>>(
        'create_battle',
        params: {
          'p_title': title,
          'p_rules': rules,
          'p_stake': stake,
          'p_video_id': videoId,
          'p_end_date': endDate.toUtc().toIso8601String(),
          'p_opponent_username': opponentUsername,
          'p_random_opponent': randomOpponent,
        },
      );
      final created = await getChallengeById(result['challenge_id'] as String);
      if (created == null) {
        throw const ServerException('Battle créée mais introuvable.');
      }
      return created;
    } on supa.PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  /// Joueurs que l'utilisateur suit ou qui le suivent, filtrés par
  /// [query] (pseudo ou nom) : les adversaires proposés pour une Battle.
  Future<List<BattleOpponent>> getBattleOpponentSuggestions(String? query) async {
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'battle_opponent_suggestions',
        params: {'p_query': query},
      );
      return rows
          .map((row) => BattleOpponent.fromJson(row as Map<String, dynamic>))
          .toList();
    } on supa.PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  /// Même logique que `EconomyRemoteDataSource._mapRpcError` : les RPC
  /// `join_challenge`/`create_challenge` réutilisent `spend_coins` en
  /// interne et lèvent les mêmes messages d'erreur PL/pgSQL.
  Exception _mapRpcError(supa.PostgrestException e) {
    if (e.code == '28000') {
      return AuthException(e.message);
    }
    if (e.message.contains('insuffisant')) {
      return InsufficientCoinsException(e.message);
    }
    return ServerException(e.message);
  }
}
