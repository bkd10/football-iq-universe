import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/errors/exceptions.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

// N'inclut jamais `guardian_approval_token` : cette liste est lue par les
// DEUX parties (joueur et recruteur), et seul le joueur doit pouvoir
// obtenir ce jeton (voir `getGuardianApprovalToken`, RPC dédiée qui vérifie
// `auth.uid() = player_id`) — le recruteur ne doit jamais pouvoir le
// construire/partager lui-même.
const _conversationSelect = 'id, player_id, scout_id, status, requested_at, '
    'approved_at, last_message_at, '
    'player:profiles!player_id(username, display_name, avatar_url), '
    'scout:profiles!scout_id(username, display_name, avatar_url)';

class MessagingRemoteDataSource {
  const MessagingRemoteDataSource(this._client);

  final supa.SupabaseClient _client;

  Future<List<ConversationModel>> getConversations() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Aucune session active.');
    }
    try {
      final rows = await _client
          .from('conversations')
          .select(_conversationSelect)
          .or('player_id.eq.${user.id},scout_id.eq.${user.id}')
          .order('last_message_at', ascending: false, nullsFirst: false)
          .order('requested_at', ascending: false);

      final unreadConversationIds = await _getUnreadConversationIds(user.id);

      return rows
          .map(
            (row) => ConversationModel.fromRow(
              row,
              viewerId: user.id,
              hasUnread: unreadConversationIds.contains(row['id'] as String),
            ),
          )
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<Set<String>> _getUnreadConversationIds(String viewerId) async {
    final rows = await _client
        .from('messages')
        .select('conversation_id')
        .isFilter('read_at', null)
        .neq('sender_id', viewerId);
    return rows.map((row) => row['conversation_id'] as String).toSet();
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      final rows = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at');
      return rows.map((row) => MessageModel.fromJson(row)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> markConversationRead(String conversationId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client
          .from('messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', conversationId)
          .neq('sender_id', user.id)
          .isFilter('read_at', null);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> sendMessage({
    required String conversationId,
    required String body,
  }) async {
    try {
      await _client.rpc<void>(
        'send_message',
        params: {'p_conversation_id': conversationId, 'p_body': body},
      );
    } on supa.PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<Map<String, dynamic>> requestScoutContact(String playerId) async {
    try {
      return await _client.rpc<Map<String, dynamic>>(
        'request_scout_contact',
        params: {'p_player_id': playerId},
      );
    } on supa.PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Réservée au joueur concerné (vérifié côté serveur) : c'est lui qui
  /// transmet ce lien à son tuteur, jamais le recruteur.
  Future<String> getGuardianApprovalToken(String conversationId) async {
    try {
      final token = await _client.rpc<String>(
        'get_guardian_approval_token',
        params: {'p_conversation_id': conversationId},
      );
      return token;
    } on supa.PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> approveGuardianContact(String token) async {
    try {
      await _client.rpc<Map<String, dynamic>>(
        'approve_guardian_contact',
        params: {'p_token': token},
      );
    } on supa.PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> declineGuardianContact(String token) async {
    try {
      await _client.rpc<Map<String, dynamic>>(
        'decline_guardian_contact',
        params: {'p_token': token},
      );
    } on supa.PostgrestException catch (e) {
      throw _mapRpcError(e);
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
