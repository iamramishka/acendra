import 'package:flutter/foundation.dart';

enum VideoPlayerStatus { idle, loading, buffering, playing, paused, ended, error }

@immutable
class VideoProgress {
  const VideoProgress({
    this.status = VideoPlayerStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffered = 0.0,
    this.errorMessage,
  });

  final VideoPlayerStatus status;
  final Duration position;
  final Duration duration;
  final double buffered;
  final String? errorMessage;

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  VideoProgress copyWith({
    VideoPlayerStatus? status,
    Duration? position,
    Duration? duration,
    double? buffered,
    String? errorMessage,
  }) => VideoProgress(
    status: status ?? this.status,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    buffered: buffered ?? this.buffered,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoProgress &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          position == other.position &&
          duration == other.duration &&
          buffered == other.buffered &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      Object.hash(status, position, duration, buffered, errorMessage);
}
