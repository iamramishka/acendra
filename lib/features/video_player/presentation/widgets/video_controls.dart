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
  final VoidCallback onFullscreen;
  final double speed;
  final ValueChanged<double>? onSpeed;
  final bool isFullscreen;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
      child: Row(
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
          Text(
            _formatDuration(progress.position),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: primaryColor,
                thumbColor: primaryColor,
                inactiveTrackColor: Colors.white24,
                overlayColor: primaryColor.withValues(alpha: 0.2),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Semantics(
                label: 'Seek',
                child: Slider(
                  value: posMs,
                  min: 0,
                  max: sliderMax,
                  onChanged: totalMs > 0
                      ? (v) => onSeek(Duration(milliseconds: v.round()))
                      : null,
                ),
              ),
            ),
          ),
          Text(
            _formatDuration(progress.duration),
            style: const TextStyle(color: Colors.white, fontSize: 12),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${speed}x',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
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
    );
  }
}
