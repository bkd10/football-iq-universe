import 'package:image_picker/image_picker.dart' show XFile;
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/storage_service.dart';
import '../models/video_comment_model.dart';
import '../models/video_model.dart';

/// Champ de jointure commun : embarque le profil du créateur/auteur dans
/// une seule requête plutôt que de faire un aller-retour réseau par vidéo.
const _creatorSelect =
    'id, username, display_name, avatar_url, level, is_verified, country, position, '
    'preferred_foot, stars, videos_count, likes_received_count, moves_created_count, '
    'challenges_won_count, form_score';

class VideoRemoteDataSource {
  const VideoRemoteDataSource(this._client, this._storageService);

  final supa.SupabaseClient _client;
  final StorageService _storageService;

  Future<List<VideoModel>> getFeed({
    int limit = 10,
    DateTime? beforeCreatedAt,
  }) async {
    try {
      final baseQuery = _client
          .from('videos')
          .select('*, creator:profiles($_creatorSelect)')
          .eq('status', 'active');

      final filtered = beforeCreatedAt != null
          ? baseQuery.lt('created_at', beforeCreatedAt.toIso8601String())
          : baseQuery;

      final rows = await filtered
          .order('talent_score', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);

      return rows.map((row) => VideoModel.fromJson(row)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<VideoModel>> getVideosByUser(String userId) async {
    try {
      final rows = await _client
          .from('videos')
          .select('*, creator:profiles($_creatorSelect)')
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return rows.map((row) => VideoModel.fromJson(row)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<VideoModel?> getVideoById(String videoId) async {
    try {
      final row = await _client
          .from('videos')
          .select('*, creator:profiles($_creatorSelect)')
          .eq('id', videoId)
          .eq('status', 'active')
          .maybeSingle();

      return row != null ? VideoModel.fromJson(row) : null;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<VideoModel>> getReproductions(String moveId) async {
    try {
      final rows = await _client
          .from('videos')
          .select('*, creator:profiles($_creatorSelect)')
          .eq('original_move_id', moveId)
          .eq('status', 'active')
          .order('likes_count', ascending: false);

      return rows.map((row) => VideoModel.fromJson(row)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<VideoModel>> getTrendingMoves({int limit = 20}) async {
    try {
      final rows = await _client
          .from('videos')
          .select('*, creator:profiles($_creatorSelect)')
          .eq('is_move', true)
          .eq('status', 'active')
          .order('reproductions_count', ascending: false)
          .order('talent_score', ascending: false)
          .limit(limit);

      return rows.map((row) => VideoModel.fromJson(row)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Renvoie, parmi `videoIds`, ceux likés / masterclassés par
  /// l'utilisateur courant — pour hydrater `Video.hasLiked/hasMasterclassed`
  /// côté repository.
  Future<({Set<String> liked, Set<String> masterclassed})> getMyReactions(
    List<String> videoIds,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || videoIds.isEmpty) {
      return (liked: <String>{}, masterclassed: <String>{});
    }

    try {
      final rows = await _client
          .from('likes')
          .select('video_id, type')
          .eq('user_id', userId)
          .inFilter('video_id', videoIds);

      final liked = <String>{};
      final masterclassed = <String>{};
      for (final row in rows) {
        final map = row;
        final videoId = map['video_id'] as String;
        if (map['type'] == 'masterclass') {
          masterclassed.add(videoId);
        } else {
          liked.add(videoId);
        }
      }
      return (liked: liked, masterclassed: masterclassed);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Bascule la réaction de l'utilisateur sur une vidéo. `likes` a une
  /// contrainte UNIQUE(user_id, video_id) : un utilisateur n'a qu'UNE seule
  /// réaction par vidéo (like OU masterclass). Un insert ou un update gère
  /// la création et le changement de type (le trigger
  /// `trigger_like_type_change` réajuste les compteurs dénormalisés).
  Future<void> toggleLike({
    required String videoId,
    required bool currentlyLiked,
    bool isMasterclass = false,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Connecte-toi pour réagir à une vidéo.');
    }

    try {
      if (currentlyLiked) {
        await _client.from('likes').delete().match({
          'user_id': userId,
          'video_id': videoId,
        });
      } else {
        // Pas d'`upsert` : il réécrirait aussi user_id/video_id, que la base
        // n'autorise plus à modifier (seul `type` l'est).
        final type = isMasterclass ? 'masterclass' : 'like';
        final existing = await _client
            .from('likes')
            .select('id')
            .match({'user_id': userId, 'video_id': videoId}).maybeSingle();
        if (existing == null) {
          await _client.from('likes').insert({
            'user_id': userId,
            'video_id': videoId,
            'type': type,
          });
        } else {
          await _client
              .from('likes')
              .update({'type': type}).eq('id', existing['id'] as Object);
        }
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<VideoCommentModel>> getComments(String videoId) async {
    try {
      final rows = await _client
          .from('comments')
          .select('*, author:profiles($_creatorSelect)')
          .eq('video_id', videoId)
          .eq('status', 'active')
          .order('created_at', ascending: true);

      return rows.map((row) => VideoCommentModel.fromJson(row)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<VideoCommentModel> addComment({
    required String videoId,
    required String content,
    String? parentId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Connecte-toi pour commenter.');
    }

    try {
      final row = await _client
          .from('comments')
          .insert({
            'video_id': videoId,
            'user_id': userId,
            'content': content,
            if (parentId != null) 'parent_id': parentId,
          })
          .select('*, author:profiles($_creatorSelect)')
          .single();

      return VideoCommentModel.fromJson(row);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Incrémente le compteur de vues via la fonction Postgres
  /// `increment_video_views` (SECURITY DEFINER) plutôt qu'un UPDATE direct
  /// — elle attribue aussi 1 Star au créateur tous les 100 vues (PARTIE
  /// 4.2), une logique qui ne doit jamais tourner côté client.
  Future<void> registerView(String videoId) async {
    try {
      await _client.rpc<void>(
        'increment_video_views',
        params: {'p_video_id': videoId},
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<VideoModel> uploadVideo({
    required XFile videoFile,
    required String caption,
    required String category,
    int? durationSeconds,
    bool isMove = false,
    String? moveName,
    String? originalMoveId,
    XFile? thumbnailFile,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Connecte-toi pour publier une vidéo.');
    }

    try {
      final videoUrl = await _storageService.uploadVideo(videoFile, userId);
      final thumbnailUrl = thumbnailFile != null
          ? await _storageService.uploadThumbnail(thumbnailFile, userId)
          : null;

      final trimmedMoveName = moveName?.trim();
      final moveSlug =
          isMove && trimmedMoveName != null && trimmedMoveName.isNotEmpty
              ? '${_slugify(trimmedMoveName)}-${userId.substring(0, 6)}'
              : null;

      final row = await _client
          .from('videos')
          .insert({
            'user_id': userId,
            'video_url': videoUrl,
            'thumbnail_url': thumbnailUrl,
            'duration_seconds': durationSeconds,
            'caption': caption,
            'category': category,
            'is_move': isMove,
            if (isMove) 'move_name': trimmedMoveName,
            if (moveSlug != null) 'move_slug': moveSlug,
            if (originalMoveId != null) 'original_move_id': originalMoveId,
          })
          .select('*, creator:profiles($_creatorSelect)')
          .single();

      return VideoModel.fromJson(row);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  String _slugify(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
  }
}
