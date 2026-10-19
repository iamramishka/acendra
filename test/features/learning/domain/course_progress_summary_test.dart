import 'package:acendra/features/learning/data/repositories/learning_progress_repository.dart';
import 'package:acendra/features/learning/domain/course_progress_summary.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:flutter_test/flutter_test.dart';

LessonItem _lesson(String id, int position) => LessonItem(
  id: id,
  title: 'Lesson $id',
  lessonType: 'text',
  position: position,
  isPreview: false,
);

SavedLessonProgress _done(String id, {DateTime? opened}) =>
    SavedLessonProgress(lessonId: id, completed: true, lastOpenedAt: opened);

final _sections = [
  CurriculumSection(
    id: 's1',
    title: 'One',
    position: 1,
    lessons: [_lesson('a', 1), _lesson('b', 2)],
  ),
  CurriculumSection(
    id: 's2',
    title: 'Two',
    position: 2,
    lessons: [_lesson('c', 1), _lesson('d', 2)],
  ),
];

void main() {
  test('empty progress: 0%, first lesson is next, nothing started', () {
    final s = CourseProgressSummary.from(_sections, const {});
    expect(s.totalLessons, 4);
    expect(s.completedLessons, 0);
    expect(s.percent, 0);
    expect(s.nextLesson?.id, 'a');
    expect(s.hasStarted, isFalse);
    expect(s.sectionStatus('s1'), SectionStatus.todo);
  });

  test('counts completed lessons and rounds percent', () {
    final s = CourseProgressSummary.from(_sections, {
      'a': _done('a'),
      'b': _done('b'),
      'c': _done('c'),
    });
    expect(s.completedLessons, 3);
    expect(s.percent, 75);
    expect(s.nextLesson?.id, 'd');
    expect(s.hasStarted, isTrue);
    expect(s.sectionStatus('s1'), SectionStatus.completed);
    expect(s.sectionStatus('s2'), SectionStatus.current);
  });

  test('next lesson is the first incomplete after the last completed one', () {
    final s = CourseProgressSummary.from(_sections, {'b': _done('b')});
    expect(s.nextLesson?.id, 'c');
  });

  test('all complete: 100%, no next lesson', () {
    final s = CourseProgressSummary.from(_sections, {
      for (final id in ['a', 'b', 'c', 'd']) id: _done(id),
    });
    expect(s.percent, 100);
    expect(s.nextLesson, isNull);
    expect(s.sectionStatus('s2'), SectionStatus.completed);
  });

  test('ignores progress for lessons not in the curriculum', () {
    final s = CourseProgressSummary.from(_sections, {'zzz': _done('zzz')});
    expect(s.completedLessons, 0);
  });

  test('empty curriculum yields 0% without dividing by zero', () {
    final s = CourseProgressSummary.from(const [], const {});
    expect(s.percent, 0);
    expect(s.nextLesson, isNull);
  });

  test('isLastInSection identifies module boundaries', () {
    final s = CourseProgressSummary.from(_sections, const {});
    expect(s.isLastInSection('b'), isTrue);
    expect(s.isLastInSection('a'), isFalse);
  });
}
