import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/errors/exceptions.dart';
import '../models/content_report_model.dart';

/// Signalement de contenu — voir `content_reports`
/// (`20260101000015_hardening.sql`). L'insertion passe directement par la
/// table (RLS `with check (auth.uid() = reporter_id)`), pas par une RPC :
/// aucune règle métier serveur à appliquer au-delà de "un utilisateur ne
/// peut signaler qu'en son propre nom". La lecture/résolution de la liste
/// est réservée aux admins par RLS — un non-admin qui tenterait d'appeler
/// `getPendingReports`/`resolveReport` recevrait simplement une liste
/// vide / une erreur de permission, jamais les données d'un autre.
class ModerationRemoteDataSource {
  const ModerationRemoteDataSource(this._client);

  final supa.SupabaseClient _client;

  Future<void> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Connecte-toi pour signaler un contenu.');
    }
    try {
      await _client.from('content_reports').insert({
        'target_type': targetType,
        'target_id': targetId,
        'reporter_id': userId,
        'reason': reason,
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<ContentReportModel>> getPendingReports() async {
    try {
      final rows = await _client
          .from('content_reports')
          .select('*, reporter:profiles(username)')
          .eq('status', 'pending')
          .order('created_at', ascending: true);
      return rows.map((row) => ContentReportModel.fromRow(row)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> resolveReport({
    required String reportId,
    required String status,
    String? resolutionNote,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Authentification requise.');
    }
    try {
      // RPC admin : en plus de clore le signalement, retire réellement la
      // vidéo/le commentaire visé quand le statut est `actioned`.
      await _client.rpc<void>(
        'admin_resolve_report',
        params: {
          'p_report_id': reportId,
          'p_status': status,
          'p_note': resolutionNote,
        },
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
