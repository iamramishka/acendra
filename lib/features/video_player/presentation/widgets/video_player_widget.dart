import 'dart:async';

import 'package:acendra/features/video_player/domain/entities/video_lesson.dart';
import 'package:acendra/features/video_player/domain/entities/video_progress.dart';
import 'package:acendra/features/video_player/presentation/providers/video_player_provider.dart';
import 'package:acendra/features/video_player/presentation/widgets/video_controls.dart';
import 'package:acendra/features/video_player/presentation/widgets/video_error_state.dart';
import 'package:acendra/features/video_player/presentation/widgets/video_loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends ConsumerStatefulWidget {
  const VideoPlayerWidget({super.key, required this.lesson});

  final VideoLesson lesson;

  @override
  ConsumerState<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends ConsumerState<VideoPlayerWidget> {
  bool _controlsVisible = true;
  Timer? _hideTimer;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(videoPlayerProvider.notifier).initialize(widget.lesson.videoUrl);
    });
    _scheduleHideControls();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
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

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(videoPlayerProvider);
    final notifier = ref.read(videoPlayerProvider.notifier);

    final isLoadingOrBuffering =
        progress.status == VideoPlayerStatus.loading ||
        progress.status == VideoPlayerStatus.buffering;
    final isError = progress.status == VideoPlayerStatus.error;

    Widget content;

    if (isError) {
      content = VideoErrorState(
        errorMessage: progress.errorMessage,
        onRetry: () => notifier.initialize(widget.lesson.videoUrl),
      );
    } else if (isLoadingOrBuffering) {
      content = VideoLoadingState(
        label: progress.status == VideoPlayerStatus.buffering
            ? 'Buffering…'
            : 'Loading…',
      );
    } else {
      final controller = notifier.controller;
      content = controller != null && controller.value.isInitialized
          ? VideoPlayer(controller)
          : const ColoredBox(color: Colors.black);
    }

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
              content,
              if (_controlsVisible && !isError && !isLoadingOrBuffering)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: VideoControls(
                    progress: progress,
                    onPlayPause: () {
                      if (progress.status == VideoPlayerStatus.playing) {
                        notifier.pause();
                      } else {
                        notifier.play();
                      }
                      _scheduleHideControls();
                    },
                    onSeek: (pos) {
                      notifier.seekTo(pos);
                      _scheduleHideControls();
                    },
                    onFullscreen: _toggleFullscreen,
                    isFullscreen: _isFullscreen,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
