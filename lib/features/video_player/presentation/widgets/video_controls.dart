import 'package:acendra/app/theme/app_colors.dart';
import 'package:acendra/features/video_player/domain/entities/video_progress.dart';
import 'package:flutter/material.dart';

class VideoControls extends StatelessWidget {
  const VideoControls({
    super.key,
    required this.progress,
    required this.onPlayPause,
    required this.onSeek,
    required this.onFullscreen,
    this.speed = 1.0,
    this.onSpeed,
    this.isFullscreen = false,
  });

  final VideoProgress progress;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onFullscreen;
  final double speed;
  final ValueChanged<double>? onSpeed;
  final bool isFullscreen;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0
        ? '${d.inHours}:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = progress.status == VideoPlayerStatus.playing;
    final totalMs = progress.duration.inMilliseconds.toDouble();
    final posMs = progress.position.inMilliseconds.toDouble().clamp(
      0.0,
      totalMs > 0 ? totalMs : 1.0,
    );
    final sliderMax = totalMs > 0 ? totalMs : 1.0;
    final primaryColor = AppColors.dark.primary;

    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            children: [
              Text(
                _formatDuration(progress.position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                _formatDuration(progress.duration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: Semantics(
              label: 'Seek',
              child: Slider(
                value: posMs,
                min: 0,
                max: sliderMax,
                activeColor: primaryColor,
                inactiveColor: Colors.white24,
                onChanged: totalMs > 0
                    ? (value) => onSeek(Duration(milliseconds: value.round()))
                    : null,
              ),
            ),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                label: isPlaying ? 'Pause' : 'Play',
                button: true,
                child: IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: onPlayPause,
                ),
              ),
              if (onSpeed != null)
                PopupMenuButton<double>(
                  tooltip: 'Playback speed',
                  initialValue: speed,
                  onSelected: onSpeed,
                  itemBuilder: (_) => [
                    for (final s in const [1.0, 1.25, 1.5, 2.0])
                      PopupMenuItem(value: s, child: Text('${s}x')),
                  ],
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: Text(
                        '${speed}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              if (onFullscreen != null)
                Semantics(
                  label: isFullscreen ? 'Exit fullscreen' : 'Enter fullscreen',
                  button: true,
                  child: IconButton(
                    icon: Icon(
                      isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.white,
                    ),
                    onPressed: onFullscreen,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
