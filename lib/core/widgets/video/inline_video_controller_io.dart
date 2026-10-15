import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import 'inline_video_controller.dart';

InlineVideoController createInlineVideoController(String url) => _NativeInlineVideoController(url);

class _NativeInlineVideoController extends ChangeNotifier implements InlineVideoController {
  _NativeInlineVideoController(String url) : _url = url, _controller = VideoPlayerController.networkUrl(Uri.parse(url)) {
    _controller.addListener(_onTick);
  }

  final String _url;
  VideoPlayerController _controller;
  bool _hasError = false;
  bool _endHandled = false;
  VoidCallback? _onCompleted;

  /// Pas de boucle native : on détecte la fin pour compter la vidéo comme
  /// regardée en entier, puis on relance depuis le début.
  void _onTick() {
    final value = _controller.value;
    final duration = value.duration;
    if (value.isInitialized && duration > Duration.zero) {
      final atEnd = value.position >= duration - const Duration(milliseconds: 200);
      if (atEnd && !_endHandled) {
        _endHandled = true;
        _onCompleted?.call();
        _controller.seekTo(Duration.zero).then((_) => _controller.play());
      } else if (!atEnd && value.position < duration - const Duration(seconds: 1)) {
        _endHandled = false;
      }
    }
    notifyListeners();
  }

  @override
  Future<void> initialize() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(false);
    } catch (_) {
      _hasError = true;
    }
    notifyListeners();
  }

  @override
  bool get isPlaying => _controller.value.isPlaying;

  @override
  bool get hasError => _hasError || _controller.value.hasError;

  @override
  String? get errorDetail => _controller.value.errorDescription;

  @override
  double? get durationSeconds {
    final d = _controller.value.duration;
    return d > Duration.zero ? d.inMilliseconds / 1000 : null;
  }

  @override
  set onCompleted(VoidCallback? callback) => _onCompleted = callback;

  @override
  void retry() {
    _controller
      ..removeListener(_onTick)
      ..dispose();
    _hasError = false;
    _controller = VideoPlayerController.networkUrl(Uri.parse(_url))..addListener(_onTick);
    initialize();
  }

  @override
  bool get isMuted => _controller.value.volume == 0;

  @override
  set isMuted(bool value) => _controller.setVolume(value ? 0 : 1);

  @override
  void play() => _controller.play();

  @override
  void pause() => _controller.pause();

  @override
  Widget buildView() {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        if (!value.isInitialized || value.size.isEmpty) return const SizedBox.expand();
        return FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: value.size.width,
            height: value.size.height,
            child: VideoPlayer(_controller),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }
}
