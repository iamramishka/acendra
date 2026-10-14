import 'dart:async';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/video_player/data/video_authorization_repository.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Learning integration accepts identity only, never a caller-supplied media URL.
class AuthorizedVideoWidget extends ConsumerStatefulWidget {
  const AuthorizedVideoWidget({
    super.key,
    required this.lessonId,
    required this.title,
  });
  final String lessonId;
  final String title;
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
    );
  }
}

class _VideoLease extends ConsumerStatefulWidget {
  const _VideoLease({super.key, required this.lessonId, required this.title});
  final String lessonId, title;
  @override
  ConsumerState<_VideoLease> createState() => _VideoLeaseState();
}

class _VideoLeaseState extends ConsumerState<_VideoLease> {
  AuthorizedVideo? _video;
  String? _error;
  Timer? _expiry;
  int _request = 0;
  bool _loading = true;
  VideoPlayerController? _controller;
  void _stopPlayback() {
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
    if (_controller?.value.hasError == true) {
      _stopPlayback();
      setState(() {
        _video = null;
        _loading = false;
        _error = 'Video playback stopped. Request access again.';
      });
    } else {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_authorize);
  }

  Future<void> _authorize() async {
    if (!mounted) return;
    final request = ++_request;
    _expiry?.cancel();
    _stopPlayback();
    setState(() {
      _video = null;
      _error = null;
      _loading = true;
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
      _video = video;
      // Stop one second early rather than promise uninterrupted signed renewal.
      _expiry = Timer(remaining - const Duration(seconds: 1), () {
        if (mounted) {
          _request++;
          _stopPlayback();
          setState(() {
            _video = null;
            _loading = false;
            _error = 'Video authorization expired. Request access again.';
          });
        }
      });
      final controller = VideoPlayerController.networkUrl(video.url);
      _controller = controller;
      controller.addListener(_playbackChanged);
      await controller.initialize();
      if (!mounted || request != _request || _controller != controller) return;
      setState(() {
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      _expiry?.cancel();
      _stopPlayback();
      setState(() {
        _loading = false;
        _video = null;
        _error = error is VideoAuthorizationException
            ? error.message
            : 'Video access is temporarily unavailable.';
      });
    }
  }

  @override
  void dispose() {
    _request++;
    _expiry?.cancel();
    _stopPlayback();
    _video = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final video = _video;
    if (video == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error ?? 'Video access is temporarily unavailable.'),
          TextButton(
            onPressed: _authorize,
            child: const Text('Request video access'),
          ),
        ],
      );
    }
    final controller = _controller;
    if (controller == null)
      return const Text('Video access is temporarily unavailable.');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
        Text(widget.title),
        IconButton(
          tooltip: controller.value.isPlaying ? 'Pause video' : 'Play video',
          icon: Icon(
            controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
          onPressed: () async {
            try {
              if (controller.value.isPlaying) {
                await controller.pause();
              } else {
                await controller.play();
              }
            } catch (_) {
              if (mounted) {
                _stopPlayback();
                setState(() {
                  _video = null;
                  _error = 'Video playback stopped. Request access again.';
                });
              }
            }
          },
        ),
      ],
    );
  }
}
