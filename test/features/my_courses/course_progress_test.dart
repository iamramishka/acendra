import 'package:acendra/features/dashboard/presentation/widgets/dashboard_personal_section.dart';
import 'package:acendra/features/my_courses/data/repositories/supabase_course_progress_repository.dart';
import 'package:acendra/features/my_courses/domain/entities/course_progress.dart';
import 'package:acendra/features/my_courses/presentation/screens/my_courses_screen.dart';
import 'package:acendra/features/my_courses/data/repositories/supabase_my_courses_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_my_courses_repository.dart';

class _FakeProgress implements CourseProgressRepository {
  _FakeProgress(this.map, {this.fail = false});
  final Map<String, CourseProgress> map;
  final bool fail;

  @override
  Future<Map<String, CourseProgress>> summary() async {
    if (fail) throw Exception('rpc missing');
    return map;
  }
}

CourseProgress _p(int done, int total, {bool opened = false}) => CourseProgress(
  courseId: 'course-1',
  totalLessons: total,
  completedLessons: done,
  nextLessonId: 'l-next',
  lastOpenedAt: opened ? DateTime.utc(2026, 10, 18) : null,
);

Widget _app(Widget child, CourseProgressRepository progress) => ProviderScope(
  overrides: [
    myCoursesRepositoryProvider.overrideWithValue(
      FakeMyCoursesRepository(result: [fakeEnrolledCourse]),
    ),
    courseProgressRepositoryProvider.overrideWithValue(progress),
  ],
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  group('CourseProgress', () {
    test('filters and percent', () {
      expect(_p(0, 10).matches(ProgressFilter.notStarted), isTrue);
      expect(_p(3, 10).matches(ProgressFilter.inProgress), isTrue);
      expect(_p(10, 10).matches(ProgressFilter.completed), isTrue);
      expect(_p(10, 10).matches(ProgressFilter.inProgress), isFalse);
      expect(_p(3, 10).percent, 30);
      expect(_p(0, 0).fraction, 0);
    });

    test('resume goes to next lesson, overview when finished', () {
      expect(_p(3, 10).resumePath, '/learn/course-1/l-next');
      expect(_p(10, 10).resumePath, '/learn/course-1');
    });
  });

  group('MyCoursesScreen progress', () {
    testWidgets('shows progress and Continue Learning', (tester) async {
      await tester.pumpWidget(
        _app(
          const MyCoursesScreen(),
          _FakeProgress({'course-1': _p(3, 10, opened: true)}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('3 of 10 lessons completed • 30%'), findsOneWidget);
      expect(find.text('Continue Learning'), findsOneWidget);
    });

    testWidgets('Completed filter with none shows empty view', (tester) async {
      await tester.pumpWidget(
        _app(const MyCoursesScreen(), _FakeProgress({'course-1': _p(3, 10)})),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
      await tester.pumpAndSettle();
      expect(find.text('No courses in this view.'), findsOneWidget);
    });

    testWidgets('still lists courses when progress cannot load', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const MyCoursesScreen(), _FakeProgress(const {}, fail: true)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Flutter Fundamentals'), findsOneWidget);
      expect(find.text('Open Course'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
    });
  });

  group('DashboardPersonalSection', () {
    test('greeting follows time of day', () {
      expect(DashboardPersonalSection.greetingFor(8), 'Good morning');
      expect(DashboardPersonalSection.greetingFor(13), 'Good afternoon');
      expect(DashboardPersonalSection.greetingFor(20), 'Good evening');
    });

    testWidgets('shows resume card for the started course', (tester) async {
      await tester.pumpWidget(
        _app(
          DashboardPersonalSection(now: DateTime(2026, 10, 18, 9)),
          _FakeProgress({'course-1': _p(3, 10, opened: true)}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Good morning'), findsOneWidget);
      expect(find.text('Continue Learning'), findsOneWidget);
      expect(find.text('3 of 10 lessons completed'), findsOneWidget);
    });
  });
}
