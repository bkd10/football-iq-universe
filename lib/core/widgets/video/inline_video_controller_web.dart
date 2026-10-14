import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'inline_video_controller.dart';

InlineVideoController createInlineVideoController(String url) => _WebInlineVideoController(url);

int _nextViewId = 0;

class _WebInlineVideoController extends ChangeNotifier implements InlineVideoController {
  _WebInlineVideoController(String url) : _viewType = 'fiu-inline-video-${_nextViewId++}' {
    // Muet + playsinline AVANT la source : conditions de Safari (iPhone)
    // pour charger et lancer la vidéo sans geste de l'utilisateur.
    _element
      ..muted = true
      ..defaultMuted = true
      ..loop = true
      ..playsInline = true
      ..autoplay = false
      ..preload = 'auto'
      ..setAttribute('muted', '')
      ..setAttribute('playsinline', '')
      ..setAttribute('webkit-playsinline', '');
    _element.style
      ..width = '100%'
      ..height = '100%'
      ..objectFit = 'cover'
      // Les gestes (tap, double tap) restent gérés par Flutter.
      ..pointerEvents = 'none';
    _element.onPlay.listen((_) => notifyListeners());
    _element.onPause.listen((_) => notifyListeners());
    _element.onVolumeChange.listen((_) => notifyListeners());
    _element.onError.listen((_) {
      _hasError = true;
      notifyListeners();
    });
    _element.src = url;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) => _element);
  }

  final String _viewType;
  final web.HTMLVideoElement _element = web.HTMLVideoElement();
  bool _hasError = false;

  @override
  Future<void> initialize() async {}

  @override
  bool get isPlaying => !_element.paused;

  @override
  bool get hasError => _hasError;

  @override
  bool get isMuted => _element.muted;

  @override
  set isMuted(bool value) {
    _element.muted = value;
    // Remettre le son pendant un geste peut relancer une vidéo que Safari
    // avait mise en pause : on s'assure qu'elle continue.
    if (!value && _element.paused) play();
  }

  @override
  void play() {
    // Refus possible (mode économie d'énergie) : l'icône lecture reste
    // affichée et un tap relance la lecture.
    _element.play().toDart.then((_) {}, onError: (Object _) => notifyListeners());
  }

  @override
  void pause() => _element.pause();

  @override
  Widget buildView() => HtmlElementView(viewType: _viewType);

  @override
  void dispose() {
    _element
      ..pause()
      ..removeAttribute('src')
      ..load();
    super.dispose();
  }
}
