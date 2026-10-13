import 'package:image_picker/image_picker.dart' show XFile;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Bucket names Supabase Storage — doivent correspondre à
/// `supabase/config.toml` (dev local) et aux buckets créés en production.
class StorageBuckets {
  const StorageBuckets._();

  static const videos = 'videos';
  static const avatars = 'avatars';
  static const thumbnails = 'thumbnails';
}

/// Upload de fichiers vers Supabase Storage. Les fichiers sont rangés sous
/// `<userId>/<uuid>.<ext>` — convention attendue par les policies RLS de
/// `storage.objects` (un utilisateur ne peut écrire que dans son propre
/// dossier), voir `supabase/migrations/20260101000004_storage_and_reactions.sql`.
///
/// Prend des `XFile` (jamais `dart:io File`) et upload via `uploadBinary` —
/// la seule méthode du SDK Supabase qui fonctionne identiquement sur
/// mobile et web (`.upload(path, File)` n'existe que sur mobile).
class StorageService {
  const StorageService(this._client);

  final SupabaseClient _client;

  static const _uuid = Uuid();

  Future<String> uploadVideo(XFile file, String userId) {
    return _upload(bucket: StorageBuckets.videos, file: file, userId: userId);
  }

  Future<String> uploadThumbnail(XFile file, String userId) {
    return _upload(bucket: StorageBuckets.thumbnails, file: file, userId: userId);
  }

  Future<String> uploadAvatar(XFile file, String userId) {
    return _upload(bucket: StorageBuckets.avatars, file: file, userId: userId);
  }

  Future<String> _upload({
    required String bucket,
    required XFile file,
    required String userId,
  }) async {
    final extension = _extensionOf(file.name);
    final path = '$userId/${_uuid.v4()}.$extension';
    final bytes = await file.readAsBytes();
    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: false),
        );
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  /// `XFile.name` reste fiable sur mobile ET web (contrairement à `.path`,
  /// une URL `blob:` sans extension exploitable sur web) — on retombe sur
  /// `mp4` si le nom n'a exceptionnellement pas d'extension.
  String _extensionOf(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) return 'mp4';
    return fileName.substring(dotIndex + 1);
  }
}
