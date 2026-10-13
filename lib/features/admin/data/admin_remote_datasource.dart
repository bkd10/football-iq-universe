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

  Future<List<AdminReport>> getReports() => _call(() async {
        final rows = await _client.rpc<List<dynamic>>('admin_list_reports');
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
}
