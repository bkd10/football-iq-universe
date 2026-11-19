import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../core/errors/exceptions.dart';
import '../domain/admin_models.dart';

/// Appels du panneau administrateur. Chaque RPC vérifie côté serveur que
/// l'appelant a `profiles.role = 'admin'` (voir
/// `20260101000022_admin_panel.sql`) : l'app ne fait que présenter.
class AdminRemoteDataSource {
  const AdminRemoteDataSource(this._client);

  final supa.SupabaseClient _client;

  Future<T> _call<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on supa.PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<AdminStats> getStats() => _call(() async {
        final row = await _client.rpc<Map<String, dynamic>>('admin_dashboard_stats');
        return AdminStats.fromRow(row);
      });

  /// File de modération : `pending` (en attente, mineurs concernés et
  /// contenus les plus signalés d'abord) ou `handled` (traités, avec statut
  /// et date de traitement).
  Future<List<AdminReport>> getReports({String status = 'pending'}) => _call(() async {
        final rows = await _client.rpc<List<dynamic>>(
          'admin_moderation_queue',
          params: {'p_status': status, 'p_limit': 200},
        );
        return rows.map((r) => AdminReport.fromRow(r as Map<String, dynamic>)).toList();
      });

  Future<void> resolveReport({
    required String reportId,
    required bool removeContent,
    String? authorMessage,
    String? reporterMessage,
  }) =>
      _call(() => _client.rpc<void>(
            'admin_resolve_report',
            params: {
              'p_report_id': reportId,
              'p_status': removeContent ? 'actioned' : 'dismissed',
              'p_author_message': authorMessage,
              'p_reporter_message': reporterMessage,
            },
          ),);

  Future<List<AdminUser>> getUsers({String? search}) => _call(() async {
        final rows = await _client.rpc<List<dynamic>>(
          'admin_list_users',
          params: {'p_search': search, 'p_limit': 100},
        );
        return rows.map((r) => AdminUser.fromRow(r as Map<String, dynamic>)).toList();
      });

  Future<void> setBan({
    required String userId,
    required bool banned,
    String? reason,
  }) =>
      _call(() => _client.rpc<void>(
            'admin_set_ban',
            params: {'p_user_id': userId, 'p_banned': banned, 'p_reason': reason},
          ),);

  Future<String> createOfficialChallenge({
    required String title,
    required String description,
    required DateTime endDate,
    String? prizeDescription,
  }) =>
      _call(() async {
        final row = await _client.rpc<Map<String, dynamic>>(
          'admin_create_official_challenge',
          params: {
            'p_title': title,
            'p_description': description,
            'p_end_date': endDate.toUtc().toIso8601String(),
            'p_prize_description': prizeDescription,
          },
        );
        return row['challenge_id'] as String;
      });

  // --- Défis sponsorisés (20260101000038_sponsored_feed_votes.sql)

  Future<List<AdminSponsoredDraft>> getSponsoredDrafts() => _call(() async {
        final rows = await _client.rpc<List<dynamic>>('admin_list_sponsored_drafts');
        return rows.map((r) => AdminSponsoredDraft.fromRow(r as Map<String, dynamic>)).toList();
      });

  Future<AdminSponsoredDraft> saveSponsoredDraft(String? id, Map<String, Object?> fields) =>
      _call(() async {
        final row = await _client.rpc<Map<String, dynamic>>(
          'admin_save_sponsored_draft',
          params: {'p_id': id, 'p_fields': fields},
        );
        return AdminSponsoredDraft.fromRow(row);
      });

  Future<String> activateSponsoredDraft(String id) => _call(() async {
        final row = await _client.rpc<Map<String, dynamic>>(
          'admin_activate_sponsored_draft',
          params: {'p_id': id},
        );
        return row['challenge_id'] as String;
      });

  Future<void> setSponsoredFeed({required int everyN, required bool enabled}) => _call(
        () => _client.rpc<dynamic>(
          'admin_set_sponsored_feed',
          params: {'p_every_n': everyN, 'p_enabled': enabled},
        ),
      );

  Future<List<AdminVoteFlag>> getVoteFlags({String status = 'pending'}) => _call(() async {
        final rows = await _client.rpc<List<dynamic>>(
          'admin_list_vote_flags',
          params: {'p_status': status, 'p_limit': 200},
        );
        return rows.map((r) => AdminVoteFlag.fromRow(r as Map<String, dynamic>)).toList();
      });

  Future<void> resolveVoteFlag(String id, {required bool removeVote}) => _call(
        () => _client.rpc<dynamic>(
          'admin_resolve_vote_flag',
          params: {'p_flag_id': id, 'p_action': removeVote ? 'remove_vote' : 'ignore'},
        ),
      );

  Future<int> pendingVoteFlagsCount() => _call(() async {
        final n = await _client.rpc<dynamic>('admin_pending_vote_flags_count');
        return (n as num?)?.toInt() ?? 0;
      });
}
