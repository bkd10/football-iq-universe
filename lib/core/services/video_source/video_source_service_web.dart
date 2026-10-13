import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'picked_video.dart';
import 'video_source_service.dart';

/// Implémentation web : le navigateur n'expose la caméra qu'au travers du
/// même sélecteur de fichiers (`<input type="file" capture>` sur les
/// navigateurs qui le supportent — retombe sur un simple choix de fichier
/// sinon), géré en interne par `image_picker_for_web`. Aucune compression
/// côté client (`video_compress` n'a pas d'implémentation web) : la vidéo
/// choisie est envoyée telle quelle. `dart:io` n'est jamais importé ici —
/// il n'existe pas sur web.
class VideoSourceServiceImpl implements VideoSourceService {
  @override
  Future<PickedVideo?> pickFromCamera() => _pick(ImageSource.camera);

  @override
  Future<PickedVideo?> pickFromGallery() => _pick(ImageSource.gallery);

  Future<PickedVideo?> _pick(ImageSource source) async {
    final picked = await ImagePicker().pickVideo(source: source);
    if (picked == null) return null;
    return PickedVideo(file: picked);
  }

  @override
  VideoPlayerController createPreviewController(PickedVideo video) {
    // `XFile.path` est une URL `blob:` sur web, directement lisible par
    // `video_player_web` via `networkUrl` — `.file()` n'existe pas sur web.
    return VideoPlayerController.networkUrl(Uri.parse(video.file.path));
  }

  @override
  Future<PickedVideo> prepareForUpload(PickedVideo video) async => video;
}
