import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../core/errors/failures.dart';
import '../../auth/data/models/profile_model.dart';
import '../domain/safety_models.dart';

/// Appels des fonctions de protection des mineurs
/// (`20260101000037_minor_safety.sql`). Les erreurs du serveur sont des
/// phrases en français, traduites à l'affichage (`Failure.message`).
class SafetyRemoteDataSource {
  const SafetyRemoteDataSource(this._client);

  final supa.SupabaseClient _client;

  Future<T> _call<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on supa.PostgrestException catch (e) {
      throw ServerFailure(e.message);
    } on Failure {
      rethrow;
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  Future<AgeRules> getAgeRules() => _call(() async {
        final row = await _client.rpc<dynamic>('get_age_rules');
        return row is Map<String, dynamic> ? AgeRules.fromJson(row) : const AgeRules();
      });

  Future<MySafety> getMySafety() => _call(() async {
        final row = await _client.rpc<dynamic>('get_my_safety');
        return MySafety.fromJson(row as Map<String, dynamic>);
      });

  Future<MySafety> updateSettings(Map<String, Object?> changes) => _call(() async {
        final row = await _client.rpc<dynamic>('update_my_safety_settings', params: {'p_settings': changes});
        return MySafety.fromJson(row as Map<String, dynamic>);
      });

  Future<({ProfileModel? profile, PublicProfileFlags flags})> getPublicProfile(String userId) =>
      _call(() async {
        final row = await _client.rpc<dynamic>('get_public_profile', params: {'p_user_id': userId});
        if (row is! Map<String, dynamic>) {
          return (profile: null, flags: const PublicProfileFlags(unavailable: true));
        }
        final flags = PublicProfileFlags.fromJson(row);
        return (profile: flags.unavailable ? null : ProfileModel.fromJson(row), flags: flags);
      });

  Future<void> block(String userId) =>
      _call(() => _client.rpc<dynamic>('block_user', params: {'p_user_id': userId}));

  Future<void> unblock(String userId) =>
      _call(() => _client.rpc<dynamic>('unblock_user', params: {'p_user_id': userId}));

  Future<List<BlockedUser>> listBlocks() => _call(() async {
        final rows = await _client.rpc<List<dynamic>>('list_my_blocks');
        return rows.map((r) => BlockedUser.fromJson(r as Map<String, dynamic>)).toList();
      });

  Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
    String? details,
  }) =>
      _call(() => _client.rpc<dynamic>('report_content', params: {
            'p_target_type': targetType,
            'p_target_id': targetId,
            'p_reason': reason,
            'p_details': details,
          },),);

  Future<String> requestParentPurchaseConsent() => _call(() async {
        final row = await _client.rpc<dynamic>('request_parent_purchase_consent');
        return (row as Map<String, dynamic>)['token'] as String;
      });

  /// Envoie (ou renvoie) l'e-mail au parent. Sans service d'e-mail
  /// configuré, renvoie le lien à transmettre soi-même.
  Future<({bool sent, String? link, String? email})> sendParentSignupEmail() => _call(() async {
        try {
          final res = await _client.functions.invoke(
            'send-parent-consent',
            body: {'return_origin': Uri.base.origin},
          );
          final data = (res.data as Map?) ?? const {};
          return (
            sent: data['sent'] == true,
            link: data['link'] as String?,
            email: data['guardian_email'] as String?,
          );
        } on supa.FunctionException catch (e) {
          final details = e.details;
          final message = details is Map ? details['error'] as String? : null;
          throw ServerFailure(message ?? 'Une erreur inattendue est survenue.');
        }
      });

  Future<Map<String, dynamic>?> getParentConsentRequest(String token) => _call(() async {
        final row = await _client.rpc<dynamic>('get_parent_consent_request', params: {'p_token': token});
        return row is Map<String, dynamic> ? row : null;
      });

  Future<void> answerParentConsent(String token, {required bool approve}) => _call(
        () => _client.rpc<dynamic>('answer_parent_consent', params: {'p_token': token, 'p_approve': approve}),
      );
}
