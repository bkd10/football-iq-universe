import 'package:image_picker/image_picker.dart' show XFile;

/// Résultat d'une sélection vidéo, indépendant de la plateforme — jamais de
/// `dart:io File` exposé en dehors de `video_source_service_mobile.dart`
/// (voir `VideoSourceService`).
class PickedVideo {
  const PickedVideo({required this.file, this.thumbnail});

  /// `XFile` (package `cross_file`, ré-exporté par `image_picker`) : chemin
  /// réel sur mobile, URL `blob:` sur web — jamais de `dart:io File` ici,
  /// qui n'existe pas sur web.
  final XFile file;

  /// Miniature générée côté client — mobile uniquement (voir
  /// `VideoSourceServiceImpl` mobile) ; toujours `null` sur web, où la
  /// génération de miniature côté client n'est pas implémentée.
  final XFile? thumbnail;
}
