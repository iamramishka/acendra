import 'dart:async';
import 'dart:js_interop';

import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/video_player/data/video_authorization_repository.dart';
import 'package:acendra/features/video_player/presentation/widgets/video_error_state.dart';
import 'package:acendra/features/video_player/presentation/widgets/video_loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

@JS('acendraMuxVideo')
external _MuxRuntime? get _runtime;
extension type _MuxRuntime(JSObject _) implements JSObject {
  external _MuxSurface mount(
    web.HTMLElement host,
    JSObject lease,
    JSFunction emit,
  );
}
extension type _MuxSurface(JSObject _) implements JSObject {
  external JSPromise<JSAny?> get ready;
  external void destroy();
}

/// Web implementation uses the approved pinned adaptive player, with the same
/// identity-only authorization boundary as the native implementation.
class AuthorizedVideoWidget extends ConsumerStatefulWidget {
  const AuthorizedVideoWidget({
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
  ConsumerState<AuthorizedVideoWidget> createState() => _AuthorizedWebState();
}

class _AuthorizedWebState extends ConsumerState<AuthorizedVideoWidget> {
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
    return _WebLease(
      key: ValueKey(_generation),
      lessonId: widget.lessonId,
      title: widget.title,
      initialVideoSeconds: widget.initialVideoSeconds,
      onVideoSeconds: widget.onVideoSeconds,
    );
  }
}

class _WebLease extends ConsumerStatefulWidget {
  const _WebLease({
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
  ConsumerState<_WebLease> createState() => _WebLeaseState();
}

class _WebLeaseState extends ConsumerState<_WebLease> {
  AuthorizedVideo? _video;
  String? _error;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    Future.microtask(_authorize);
  }

  Future<void> _authorize() async {
    if (!mounted) return;
    final request = ++_request;
    setState(() {
      _video = null;
      _error = null;
    });
    try {
      final video = await ref
          .read(videoAuthorizationRepositoryProvider)
          .authorize(widget.lessonId);
      if (!mounted || request != _request) return;
      if (video.expiresAt.difference(DateTime.now()) <=
          const Duration(seconds: 1)) {
        throw const VideoAuthorizationException(
          'Video authorization expired. Request access again.',
        );
      }
      setState(() => _video = video);
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(
        () => _error = error is VideoAuthorizationException
            ? error.message
            : 'Video access is temporarily unavailable.',
      );
    }
  }

  @override
  void dispose() {
    _request++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return VideoErrorState(errorMessage: _error, onRetry: _authorize);
    }
    final video = _video;
    if (video == null) return const VideoLoadingState(label: 'Loading…');
    return _MuxView(
      key: ValueKey(_request),
      video: video,
      title: widget.title,
      resumeSeconds: widget.initialVideoSeconds,
      onProgress: widget.onVideoSeconds,
      onFailure: (expired) {
        if (!mounted || _video == null) return;
        setState(() {
          _video = null;
          _error = expired
              ? 'Video authorization expired. Request access again.'
              : 'Video playback stopped. Request access again.';
        });
      },
    );
  }
}

class _MuxView extends StatefulWidget {
  const _MuxView({
    super.key,
    required this.video,
    required this.title,
    required this.onFailure,
    this.resumeSeconds,
    this.onProgress,
  });
  final AuthorizedVideo video;
  final String title;
  final int? resumeSeconds;
  final ValueChanged<int>? onProgress;
  final ValueChanged<bool> onFailure;
  @override
  State<_MuxView> createState() => _MuxViewState();
}

class _MuxViewState extends State<_MuxView> {
  _MuxSurface? _surface;
  bool _ready = false;
  void _attach(Object element) {
    if (!mounted) return;
    try {
      final runtime = _runtime;
      if (runtime == null) throw StateError('Player runtime unavailable');
      final host = element as web.HTMLElement;
      host.style.cssText = 'width:100%;height:100%;background:#000;';
      final surface = runtime.mount(
        host,
        {
              'url': widget.video.url.toString(),
              'expiresAt': widget.video.expiresAt.millisecondsSinceEpoch,
              'title': widget.title,
              'resumeSeconds': widget.resumeSeconds ?? 0,
            }.jsify()
            as JSObject,
        ((JSObject event) {
          if (!mounted) return;
          final data = event.dartify();
          if (data is! Map) return;
          if (data['kind'] == 'progress' && data['seconds'] is num) {
            widget.onProgress?.call((data['seconds'] as num).toInt());
          } else if (data['kind'] == 'expired' || data['kind'] == 'error') {
            widget.onFailure(data['kind'] == 'expired');
          }
        }).toJS,
      );
      _surface = surface;
      unawaited(
        surface.ready.toDart
            .then((_) {
              if (mounted) setState(() => _ready = true);
            })
            .catchError((Object _) {
              if (mounted) widget.onFailure(false);
            }),
      );
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFailure(false);
      });
    }
  }

  @override
  void dispose() {
    _surface?.destroy();
    _surface = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      HtmlElementView.fromTagName(tagName: 'div', onElementCreated: _attach),
      if (!_ready)
        const IgnorePointer(child: VideoLoadingState(label: 'Loading…')),
    ],
  );
}
