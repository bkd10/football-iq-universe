import 'package:video_player/video_player.dart';

import 'picked_video.dart';
import 'video_source_service_mobile.dart'
    if (dart.library.html) 'video_source_service_web.dart' as impl;

/// Isole toute API native liée à la vidéo (caméra, compression, lecture
/// d'un fichier local) derrière une interface unique — jamais
/// `ImagePicker`/`VideoCompress`/`dart:io File` appelés directement depuis
/// un écran. Sélectionne automatiquement l'implémentation mobile (caméra +
/// compression via `video_compress`) ou web (sélecteur de fichiers du
/// navigateur, sans compression côté client — `video_compress` n'a pas
/// d'implémentation web) via un import conditionnel Dart
/// (`if (dart.library.html) ...`), résolu à la compilation : le code
/// mobile n'est jamais inclus dans le bundle web et vice-versa.
abstract class VideoSourceService {
  factory VideoSourceService() = impl.VideoSourceServiceImpl;

  /// `null` si l'utilisateur annule la sélection.
  Future<PickedVideo?> pickFromCamera();

  Future<PickedVideo?> pickFromGallery();

  /// Contrôleur de lecture pour la prévisualisation avant publication.
  /// `VideoPlayerController.file` n'existe que sur mobile ;
  /// `.networkUrl` (avec l'URL `blob:` fournie par le navigateur) est la
  /// seule option qui fonctionne sur web — cette différence reste interne
  /// à chaque implémentation, l'écran appelant n'a jamais à la connaître.
  VideoPlayerController createPreviewController(PickedVideo video);

  /// Compresse la vidéo et génère une miniature avant upload. No-op sur
  /// web (retourne [video] tel quel, sans miniature) : la vidéo originale
  /// est envoyée telle quelle plutôt que de bloquer la publication.
  Future<PickedVideo> prepareForUpload(PickedVideo video);
}
