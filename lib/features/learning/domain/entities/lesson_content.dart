import 'package:flutter/foundation.dart';

@immutable
class LessonContent {
  const LessonContent({
    required this.id,
    required this.title,
    required this.lessonType,
    required this.position,
    required this.sectionId,
    this.contentText,
    this.contentImageUrl,
  });

  final String id;
  final String title;
  final String lessonType;
  final int position;
  final String sectionId;
  final String? contentText;
  final String? contentImageUrl;
}
