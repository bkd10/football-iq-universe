import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import 'inline_video_controller.dart';

InlineVideoController createInlineVideoController(String url) => _NativeInlineVideoController(url);

class _NativeInlineVideoController extends ChangeNotifier implements InlineVideoController {
  _NativeInlineVideoController(String url) : _controller = VideoPlayerController.networkUrl(Uri.parse(url)) {
    _controller.addListener(notifyListeners);
  }

  final VideoPlayerController _controller;
  bool _hasError = false;

  @override
  Future<void> initialize() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
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
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }
}
