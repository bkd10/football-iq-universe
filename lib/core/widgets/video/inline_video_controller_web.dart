import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'inline_video_controller.dart';

InlineVideoController createInlineVideoController(String url) => _WebInlineVideoController(url);

int _nextViewId = 0;

class _WebInlineVideoController extends ChangeNotifier implements InlineVideoController {
  _WebInlineVideoController(this._url) : _viewType = 'fiu-inline-video-${_nextViewId++}' {
    // Muet + playsinline AVANT la source : conditions de Safari (iPhone)
    // pour charger et lancer la vidéo sans geste de l'utilisateur.
    _element
      ..muted = true
      ..defaultMuted = true
      // Pas de `loop` : l'évènement `ended` sert à compter les vidéos
      // regardées en entier, puis on relance nous-mêmes depuis le début.
      ..loop = false
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
    _element.onPlay.listen((_) => _notify());
    _element.onPause.listen((_) => _notify());
    _element.onVolumeChange.listen((_) => _notify());
    _element.onEnded.listen((_) {
      if (_disposed) return;
      _onCompleted?.call();
      _element.currentTime = 0;
      play();
    });
    _element.onError.listen((_) {
      if (_disposed) return;
      _hasError = true;
      _notify();
    });
    _element.src = _url;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) => _element);
  }

  final String _url;
  final String _viewType;
  final web.HTMLVideoElement _element = web.HTMLVideoElement();
  bool _hasError = false;
  bool _disposed = false;
  VoidCallback? _onCompleted;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  Future<void> initialize() async {}

  @override
  bool get isPlaying => !_element.paused;

  @override
  bool get hasError => _hasError;

  @override
  String? get errorDetail {
    final code = _element.error?.code;
    return code == null ? null : 'code $code';
  }

  @override
  double? get durationSeconds {
    final d = _element.duration;
    return d.isFinite && d > 0 ? d.toDouble() : null;
  }

  @override
  set onCompleted(VoidCallback? callback) => _onCompleted = callback;

  @override
  void retry() {
    _hasError = false;
    _element
      ..src = _url
      ..load();
    _notify();
  }

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
    _element.play().toDart.then((_) {}, onError: (Object _) => _notify());
  }

  @override
  void pause() => _element.pause();

  @override
  Widget buildView() => HtmlElementView(viewType: _viewType);

  @override
  void dispose() {
    _disposed = true;
    _element
      ..pause()
      ..removeAttribute('src')
      ..load();
    super.dispose();
  }
}
