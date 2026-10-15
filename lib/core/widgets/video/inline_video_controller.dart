import 'package:flutter/widgets.dart';

import 'inline_video_controller_io.dart'
    if (dart.library.js_interop) 'inline_video_controller_web.dart' as impl;

/// Lecture d'une vidéo du feed, en boucle, plein cadre (cover).
///
/// Sur mobile : `video_player`. Sur web : un `<video>` natif, démarré muet
/// avec `playsinline` — Safari sur iPhone ne charge pas une vidéo qu'on ne
/// lance pas soi-même et bloque la lecture automatique avec le son, donc
/// `video_player_web` restait bloqué sans jamais afficher l'image.
abstract class InlineVideoController implements Listenable {
  factory InlineVideoController(String url) => impl.createInlineVideoController(url);

  /// Mobile : charge la vidéo. Web : immédiat (le navigateur charge seul).
  Future<void> initialize();

  bool get isPlaying;
  bool get hasError;

  /// Code d'erreur du lecteur, pour comprendre une vidéo illisible
  /// (web : 2 = réseau, 3 = décodage, 4 = format non pris en charge).
  String? get errorDetail;

  /// Durée de la vidéo en secondes, quand le lecteur la connaît.
  double? get durationSeconds;

  /// Appelé chaque fois que la vidéo arrive au bout (elle repart ensuite
  /// du début toute seule).
  set onCompleted(VoidCallback? callback);

  /// Recharge la vidéo après une erreur.
  void retry();
  bool get isMuted;
  set isMuted(bool value);

  void play();
  void pause();

  /// La vidéo, qui remplit son parent.
  Widget buildView();

  void dispose();
}
