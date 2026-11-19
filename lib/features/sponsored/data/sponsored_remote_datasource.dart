import 'dart:async';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../core/errors/failures.dart';
import '../domain/sponsored_models.dart';

/// Défis sponsorisés du fil et infos de vote des vidéos
/// (`20260101000038_sponsored_feed_votes.sql`).
class SponsoredRemoteDataSource {
  SponsoredRemoteDataSource(this._client);

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

  Future<SponsoredFeedConfig> getFeedConfig() => _call(() async {
        final row = await _client
            .from('app_config')
            .select('value')
            .eq('key', 'sponsored_feed')
            .maybeSingle();
        return SponsoredFeedConfig.fromJson(row?['value'] as Map<String, dynamic>?);
      });

  Future<List<SponsoredFeedChallenge>> getFeedChallenges() => _call(() async {
        final rows = await _client.rpc<List<dynamic>>('get_feed_sponsored_challenges');
        return rows.map((r) => SponsoredFeedChallenge.fromJson(r as Map<String, dynamic>)).toList();
      });

  // --- Infos de vote par vidéo, regroupées : les vignettes d'un profil ou
  // les pages du fil demandées au même moment partent en un seul appel.
  final Map<String, Completer<List<VideoChallengeEntry>>> _pending = {};
  Timer? _flushTimer;

  Future<List<VideoChallengeEntry>> getEntries(String videoId) {
    final existing = _pending[videoId];
    if (existing != null) return existing.future;
    final completer = Completer<List<VideoChallengeEntry>>();
    _pending[videoId] = completer;
    _flushTimer ??= Timer(const Duration(milliseconds: 40), _flush);
    return completer.future;
  }

  Future<void> _flush() async {
    _flushTimer = null;
    final batch = Map.of(_pending);
    _pending.clear();
    if (batch.isEmpty) return;
    try {
      final rows = await _call(
        () => _client.rpc<List<dynamic>>(
          'get_video_challenge_entries',
          params: {'p_video_ids': batch.keys.toList()},
        ),
      );
      final byVideo = <String, List<VideoChallengeEntry>>{};
      for (final r in rows) {
        final e = VideoChallengeEntry.fromJson(r as Map<String, dynamic>);
        byVideo.putIfAbsent(e.videoId, () => []).add(e);
      }
      batch.forEach((id, c) => c.complete(byVideo[id] ?? const []));
    } catch (e) {
      batch.forEach((_, c) => c.completeError(e));
    }
  }

  Future<int?> vote({required String challengeId, required String participantId}) => _call(() async {
        final row = await _client.rpc<dynamic>(
          'vote_for_participant',
          params: {
            'p_challenge_id': challengeId,
            'p_participant_id': participantId,
            'p_device_id': await deviceId(),
          },
        );
        return row is Map ? (row['votes_count'] as num?)?.toInt() : null;
      });

  /// Identifiant aléatoire de l'appareil (aucune donnée du téléphone), haché
  /// par le serveur : sert seulement à repérer plusieurs comptes qui votent
  /// depuis le même appareil.
  static Future<String?> deviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString(_deviceKey);
      if (id == null) {
        final rnd = Random.secure();
        id = List.generate(16, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
        await prefs.setString(_deviceKey, id);
      }
      return id;
    } catch (_) {
      return null;
    }
  }

  static const _deviceKey = 'vote_device_id';
}
