import 'package:flutter/foundation.dart';

@immutable
class VideoLesson {
  const VideoLesson({
    required this.id,
    required this.title,
    required this.videoUrl,
    this.duration,
  });

  final String id;
  final String title;
  final String videoUrl;
  final Duration? duration;

  VideoLesson copyWith({
    String? id,
    String? title,
    String? videoUrl,
    Duration? duration,
  }) => VideoLesson(
    id: id ?? this.id,
    title: title ?? this.title,
    videoUrl: videoUrl ?? this.videoUrl,
    duration: duration ?? this.duration,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoLesson &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          videoUrl == other.videoUrl &&
          duration == other.duration;

  @override
  int get hashCode => Object.hash(id, title, videoUrl, duration);
}
