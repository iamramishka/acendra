import 'package:acendra/features/video_player/domain/entities/video_progress.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:video_player/video_player.dart';

class VideoPlayerNotifier extends StateNotifier<VideoProgress> {
  VideoPlayerNotifier() : super(const VideoProgress());

  VideoPlayerController? _controller;

  Future<void> initialize(String videoUrl) async {
    _controller?.removeListener(_onControllerUpdate);
    await _controller?.dispose();
    _controller = null;

    state = const VideoProgress(status: VideoPlayerStatus.loading);

    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _controller!.addListener(_onControllerUpdate);

      await _controller!.initialize();

      state = VideoProgress(
        status: VideoPlayerStatus.paused,
        duration: _controller!.value.duration,
      );
    } catch (_) {
      state = const VideoProgress(
        status: VideoPlayerStatus.error,
        errorMessage: 'Could not play this video. Please try again.',
      );
    }
  }

  void _onControllerUpdate() {
    final ctrl = _controller;
    if (ctrl == null) return;
    final value = ctrl.value;

    if (value.hasError) {
      state = state.copyWith(
        status: VideoPlayerStatus.error,
        errorMessage: value.errorDescription,
      );
      return;
    }

    final buffered = value.buffered.isNotEmpty
        ? (value.buffered.last.end.inMilliseconds /
                  value.duration.inMilliseconds.toDouble())
              .clamp(0.0, 1.0)
        : 0.0;

    VideoPlayerStatus status;
    if (value.isBuffering) {
      status = VideoPlayerStatus.buffering;
    } else if (value.isPlaying) {
      status = VideoPlayerStatus.playing;
    } else if (value.position >= value.duration &&
        value.duration > Duration.zero) {
      status = VideoPlayerStatus.ended;
    } else {
      status = VideoPlayerStatus.paused;
    }

    state = state.copyWith(
      status: status,
      position: value.position,
      duration: value.duration,
      buffered: buffered,
    );
  }

  Future<void> play() async {
    await _controller?.play();
  }

  Future<void> pause() async {
    await _controller?.pause();
  }

  Future<void> seekTo(Duration position) async {
    await _controller?.seekTo(position);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _controller?.setPlaybackSpeed(speed);
  }

  VideoPlayerController? get controller => _controller;

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}

final videoPlayerProvider =
    StateNotifierProvider.autoDispose<VideoPlayerNotifier, VideoProgress>(
      (ref) => VideoPlayerNotifier(),
    );
