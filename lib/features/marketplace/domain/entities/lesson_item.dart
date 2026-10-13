import 'package:flutter/foundation.dart';

@immutable
class LessonItem {
  const LessonItem({
    required this.id,
    required this.title,
    required this.lessonType,
    required this.position,
    required this.isPreview,
    this.durationSeconds,
  });

  final String id;
  final String title;
  final String lessonType;
  final int position;
  final bool isPreview;
  final int? durationSeconds;

  String get typeLabel => switch (lessonType) {
    'video' => 'Video',
    'pdf' => 'PDF',
    'text' => 'Article',
    'image' => 'Image',
    _ => lessonType,
  };
}
