import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:flutter/foundation.dart';

@immutable
class CurriculumSection {
  const CurriculumSection({
    required this.id,
    required this.title,
    required this.position,
    required this.lessons,
  });

  final String id;
  final String title;
  final int position;
  final List<LessonItem> lessons;
}
