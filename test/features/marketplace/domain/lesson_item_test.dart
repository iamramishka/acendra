import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:flutter_test/flutter_test.dart';

LessonItem lesson({int? seconds, bool preview = false}) => LessonItem(
  id: 'l',
  title: 'L',
  lessonType: 'video',
  position: 0,
  isPreview: preview,
  durationSeconds: seconds,
);

void main() {
  group('LessonItem.durationLabel', () {
    test('is null when duration is unknown or zero', () {
      expect(lesson().durationLabel, isNull);
      expect(lesson(seconds: 0).durationLabel, isNull);
    });
    test('rounds up to whole minutes', () {
      expect(lesson(seconds: 1).durationLabel, '1 min');
      expect(lesson(seconds: 300).durationLabel, '5 min');
      expect(lesson(seconds: 301).durationLabel, '6 min');
    });
  });

  group('LessonItem.isUnlockedFor', () {
    test('owned students can open every lesson', () {
      expect(lesson().isUnlockedFor(owned: true), isTrue);
    });
    test('non-owners can only open free previews', () {
      expect(lesson(preview: true).isUnlockedFor(owned: false), isTrue);
      expect(lesson().isUnlockedFor(owned: false), isFalse);
    });
  });
}
