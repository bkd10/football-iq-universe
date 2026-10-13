import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

import '../../constants/app_constants.dart';
import 'picked_video.dart';
import 'video_source_service.dart';

/// Implémentation mobile (Android/iOS) : caméra native + compression réelle
/// via `video_compress` (codecs natifs, aucun équivalent web). Seul fichier
/// du projet autorisé à importer `dart:io`/`video_compress` pour tout ce
/// qui touche à la sélection vidéo — jamais depuis un écran directement.
class VideoSourceServiceImpl implements VideoSourceService {
  @override
  Future<PickedVideo?> pickFromCamera() => _pick(ImageSource.camera);

  @override
  Future<PickedVideo?> pickFromGallery() => _pick(ImageSource.gallery);

  Future<PickedVideo?> _pick(ImageSource source) async {
    final picked = await ImagePicker().pickVideo(
      source: source,
      maxDuration: const Duration(seconds: AppConstants.maxVideoDurationSeconds),
    );
    if (picked == null) return null;
    return PickedVideo(file: picked);
  }

  @override
  VideoPlayerController createPreviewController(PickedVideo video) {
    return VideoPlayerController.file(File(video.file.path));
  }

  @override
  Future<PickedVideo> prepareForUpload(PickedVideo video) async {
    var uploadFile = video.file;
    XFile? thumbnail;

    try {
      final compressed = await VideoCompress.compressVideo(
        video.file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );
      if (compressed?.path != null) {
        uploadFile = XFile(compressed!.path!);
      }
    } catch (_) {
      // La compression est un bonus de performance : on publie la vidéo
      // originale si elle échoue, plutôt que de bloquer l'utilisateur.
    }

    try {
      final thumbFile = await VideoCompress.getFileThumbnail(video.file.path, quality: 60);
      thumbnail = XFile(thumbFile.path);
    } catch (_) {
      thumbnail = null;
    }

    return PickedVideo(file: uploadFile, thumbnail: thumbnail);
  }
}
