import 'dart:async';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/video_player/data/video_authorization_repository.dart';
import 'package:acendra/features/video_player/domain/entities/video_progress.dart';
import 'package:acendra/features/video_player/presentation/widgets/video_controls.dart';
import 'package:acendra/features/video_player/presentation/widgets/video_error_state.dart';
import 'package:acendra/features/video_player/presentation/widgets/video_loading_state.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Learning integration accepts identity only, never a caller-supplied media URL.
class AuthorizedVideoWidget extends ConsumerStatefulWidget {
  const AuthorizedVideoWidget({
    super.key,
    required this.lessonId,
    required this.title,
    this.initialVideoSeconds,
    this.onVideoSeconds,
  });

  final String lessonId;
  final String title;

  /// Resume position in seconds from saved progress (CSA-138).
  final int? initialVideoSeconds;

  /// Called every ~5 s while playing with the current position in seconds (CSA-138).
  final ValueChanged<int>? onVideoSeconds;

  @override
  ConsumerState<AuthorizedVideoWidget> createState() =>
      _AuthorizedVideoWidgetState();
}

class _AuthorizedVideoWidgetState extends ConsumerState<AuthorizedVideoWidget> {
  String? _actor, _token, _lesson;
  int _generation = 0;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    if (_actor != session?.user.id ||
        _token != session?.accessToken ||
        _lesson != widget.lessonId) {
      _actor = session?.user.id;
      _token = session?.accessToken;
      _lesson = widget.lessonId;
      _generation++;
    }
    if (session == null) {
      return const Text('Please sign in to watch this lesson.');
    }
    // Token/session changes replace the entire lease and player scope. Old URLs
    // and controllers are disposed rather than handed to another account.
    return _VideoLease(
      key: ValueKey(_generation),
      lessonId: widget.lessonId,
      title: widget.title,
      initialVideoSeconds: widget.initialVideoSeconds,
      onVideoSeconds: widget.onVideoSeconds,
    );
  }
}

class _VideoLease extends ConsumerStatefulWidget {
  const _VideoLease({
    super.key,
    required this.lessonId,
    required this.title,
    this.initialVideoSeconds,
    this.onVideoSeconds,
  });

  final String lessonId, title;
  final int? initialVideoSeconds;
  final ValueChanged<int>? onVideoSeconds;

  @override
  ConsumerState<_VideoLease> createState() => _VideoLeaseState();
}

class _VideoLeaseState extends ConsumerState<_VideoLease> {
  String? _error;
  Timer? _expiry;
  int _request = 0;
  bool _loading = true;
  VideoPlayerController? _controller;
  VideoProgress _progress = const VideoProgress();

  // Controls visibility — tap-to-show/hide with 3-second auto-hide (CSA-135).
  bool _controlsVisible = true;
  Timer? _hideTimer;

  // Periodic reporter — fires every 5 s while playing (CSA-138).
  Timer? _progressTimer;

  void _stopPlayback() {
    // _progressTimer runs for the widget's full lifetime; it is NOT cancelled
    // here — it checks status before reporting so it is safe during re-auth.
    final controller = _controller;
    _controller = null;
    controller?.removeListener(_playbackChanged);
    if (controller != null) {
      unawaited(controller.pause().catchError((Object _) {}));
      unawaited(controller.dispose().catchError((Object _) {}));
    }
  }

  void _playbackChanged() {
    if (!mounted) return;
    final ctrl = _controller;
    if (ctrl == null) return;
    final value = ctrl.value;

    if (value.hasError) {
      _stopPlayback();
      setState(() {
        _loading = false;
        _error = 'Video playback stopped. Request access again.';
        _progress = VideoProgress(
          status: VideoPlayerStatus.error,
          errorMessage: value.errorDescription,
        );
      });
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

    setState(() {
      _progress = VideoProgress(
        status: status,
        position: value.position,
        duration: value.duration,
        buffered: buffered,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    // Single periodic timer for the widget's full lifetime (CSA-138).
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_progress.status == VideoPlayerStatus.playing &&
          _progress.position.inSeconds > 0) {
        widget.onVideoSeconds?.call(_progress.position.inSeconds);
      }
    });
    Future.microtask(_authorize);
  }

  Future<void> _authorize() async {
    if (!mounted) return;
    final request = ++_request;
    _expiry?.cancel();
    _stopPlayback();
    setState(() {
      _error = null;
      _loading = true;
      _progress = const VideoProgress(status: VideoPlayerStatus.loading);
    });
    try {
      final video = await ref
          .read(videoAuthorizationRepositoryProvider)
          .authorize(widget.lessonId);
      if (!mounted || request != _request) return;
      final remaining = video.expiresAt.difference(DateTime.now());
      if (remaining <= const Duration(seconds: 1)) {
        throw const VideoAuthorizationException(
          'Video authorization expired. Request access again.',
        );
      }
      // Stop one second early rather than promise uninterrupted signed renewal.
      _expiry = Timer(remaining - const Duration(seconds: 1), () {
        if (mounted) {
          _request++;
          _stopPlayback();
          setState(() {
            _loading = false;
            _error = 'Video authorization expired. Request access again.';
            _progress = const VideoProgress(status: VideoPlayerStatus.error);
          });
        }
      });
      final controller = VideoPlayerController.networkUrl(video.url);
      _controller = controller;
      controller.addListener(_playbackChanged);
      await controller.initialize();
      if (!mounted || request != _request || _controller != controller) return;

      // Seek to saved resume position (CSA-138).
      final resumeSeconds = widget.initialVideoSeconds;
      if (resumeSeconds != null &&
          resumeSeconds > 0 &&
          controller.value.duration > Duration.zero) {
        final resumePos = Duration(seconds: resumeSeconds);
        if (resumePos < controller.value.duration) {
          await controller.seekTo(resumePos);
          if (!mounted || request != _request || _controller != controller) {
            return;
          }
        }
      }

      setState(() {
        _loading = false;
        _progress = VideoProgress(
          status: VideoPlayerStatus.paused,
          duration: controller.value.duration,
          position: controller.value.position,
        );
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      _expiry?.cancel();
      _stopPlayback();
      setState(() {
        _loading = false;
        _error = error is VideoAuthorizationException
            ? error.message
            : 'Video access is temporarily unavailable.';
        _progress = VideoProgress(
          status: VideoPlayerStatus.error,
          errorMessage: _error,
        );
      });
    }
  }

  @override
  void dispose() {
    _request++;
    _expiry?.cancel();
    _hideTimer?.cancel();
    _progressTimer?.cancel();
    _stopPlayback();
    super.dispose();
  }

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleHideControls();
  }

  Future<void> _onPlayPause() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      if (_progress.status == VideoPlayerStatus.playing) {
        await controller.pause();
      } else {
        await controller.play();
      }
      _scheduleHideControls();
    } catch (_) {
      if (mounted) {
        _stopPlayback();
        setState(() {
          _error = 'Video playback stopped. Request access again.';
          _progress = const VideoProgress(status: VideoPlayerStatus.error);
        });
      }
    }
  }

  Future<void> _onSeek(Duration position) async {
    await _controller?.seekTo(position);
    _scheduleHideControls();
  }

  @override
  Widget build(BuildContext context) {
    // Authorization loading, initial video load, or buffering (CSA-137).
    if (_loading ||
        _progress.status == VideoPlayerStatus.loading ||
        _progress.status == VideoPlayerStatus.buffering) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: VideoLoadingState(
          label: _loading
              ? 'Loading…'
              : _progress.status == VideoPlayerStatus.buffering
                  ? 'Buffering…'
                  : 'Loading…',
        ),
      );
    }

    // Authorization or playback error (CSA-137).
    if (_error != null || _progress.status == VideoPlayerStatus.error) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: VideoErrorState(
          errorMessage: _error ?? _progress.errorMessage,
          onRetry: _authorize,
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(color: Colors.black),
      );
    }

    // Fully-featured player with tap-to-show controls (CSA-135).
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: Colors.black,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoPlayer(controller),
              if (_controlsVisible &&
                  _progress.status != VideoPlayerStatus.ended)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: VideoControls(
                    progress: _progress,
                    onPlayPause: _onPlayPause,
                    onSeek: _onSeek,
                    // Fullscreen API not available on Flutter Web; toggle is visual-only.
                    onFullscreen: () {},
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
