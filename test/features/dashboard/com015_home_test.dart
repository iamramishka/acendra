import 'dart:async';

import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/core/widgets/navigation/student_shell.dart';
import 'package:acendra/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:acendra/features/dashboard/presentation/screens/dashboard_home_screen.dart';
import 'package:acendra/features/dashboard/domain/entities/student_home.dart';
import 'package:acendra/features/dashboard/presentation/providers/student_home_provider.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_personal_section.dart';
import 'package:acendra/features/dashboard/presentation/widgets/student_home_cards.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:acendra/features/my_courses/domain/entities/course_progress.dart';
import 'package:acendra/features/my_courses/domain/entities/enrolled_course.dart';
import 'package:acendra/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _course = EnrolledCourse(
  id: 'enrollment',
  courseId: 'course-a',
  title: 'Flutter Foundations',
  shortDescription: 'Build responsive interfaces.',
  status: 'active',
  enrolledAt: '2026-10-01',
);
const _next = HomeLesson(
  course: _course,
  lesson: LessonItem(
    id: 'next',
    title: 'Responsive interfaces',
    lessonType: 'video',
    position: 2,
    isPreview: false,
  ),
  number: 2,
);
final _data = StudentHome(
  courses: const [_course],
  progress: {
    'course-a': CourseProgress(
      courseId: 'course-a',
      totalLessons: 18,
      completedLessons: 7,
      nextLessonId: 'next',
      lastOpenedAt: DateTime(2026, 10, 26),
    ),
  },
  nextLessons: const {'course-a': _next},
  recent: const [
    HomeLesson(
      course: _course,
      lesson: LessonItem(
        id: 'pdf',
        title: 'Layouts Guide',
        lessonType: 'pdf',
        position: 1,
        isPreview: false,
      ),
      number: 1,
      pdfPage: 4,
    ),
    _next,
  ],
);

Widget _app(Widget child, {bool dark = false, double scale = 1}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

void main() {
  testWidgets('mobile shell retains the prototype two-column course layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const DashboardHomeData empty = (
      slides: [],
      categories: [],
      courses: [],
      highlights: [],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentHomeProvider.overrideWith((ref) => _data),
          dashboardHomeProvider.overrideWith((ref) => empty),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const StudentShell(child: DashboardHomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(StudentOwnedCourseCard)).width,
      lessThan(180),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('a new student still gets the Home greeting and Explore action', (
    tester,
  ) async {
    var explored = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentHomeProvider.overrideWith((ref) => const StudentHome()),
          displayNameProvider.overrideWithValue('Asha'),
        ],
        child: _app(
          DashboardPersonalSection(
            now: DateTime(2026, 10, 27, 9),
            onExplore: () => explored = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('Welcome back, Asha'), findsOneWidget);
    await tester.tap(find.text('Explore Courses'));
    expect(explored, isTrue);
  });

  test('greeting follows local time boundaries', () {
    expect(DashboardPersonalSection.greetingFor(0), 'Good morning');
    expect(DashboardPersonalSection.greetingFor(11), 'Good morning');
    expect(DashboardPersonalSection.greetingFor(12), 'Good afternoon');
    expect(DashboardPersonalSection.greetingFor(16), 'Good afternoon');
    expect(DashboardPersonalSection.greetingFor(17), 'Good evening');
  });

  testWidgets(
    'resume, course, recent and View All preserve real destinations',
    (tester) async {
      String? path;
      var viewed = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [studentHomeProvider.overrideWith((ref) => _data)],
          child: _app(
            DashboardPersonalSection(
              onLessonSelected: (value) => path = value,
              onViewAll: () => viewed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('39% complete'), findsOneWidget);
      expect(find.text('7 of 18 lessons completed'), findsNWidgets(2));
      await tester.tap(find.text('Resume Learning'));
      expect(path, '/learn/course-a/next');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      expect(path, '/learn/course-a/next');
      await tester.ensureVisible(find.text('Layouts Guide'));
      await tester.tap(find.text('Layouts Guide'));
      expect(path, '/learn/course-a/pdf');
      expect(find.textContaining('PDF · page 4'), findsOneWidget);
      expect(find.textContaining('page 4 of'), findsNothing);
      await tester.ensureVisible(find.text('View All'));
      await tester.tap(find.text('View All'));
      expect(viewed, isTrue);
    },
  );

  testWidgets(
    'failed progress keeps courses without zero percent or fake resume',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentHomeProvider.overrideWith(
              (ref) => const StudentHome(
                courses: [_course],
                progressUnavailable: true,
                recentUnavailable: true,
              ),
            ),
          ],
          child: _app(const DashboardPersonalSection()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Progress unavailable'), findsOneWidget);
      expect(find.text('0%'), findsNothing);
      expect(find.byType(StudentResumeCard), findsNothing);
      expect(find.text('Open Course'), findsOneWidget);
    },
  );

  testWidgets(
    'loading is explicit; error retry fetches fresh data with safe copy',
    (tester) async {
      final pending = Completer<StudentHome>();
      var attempts = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentHomeProvider.overrideWith((ref) {
              if (++attempts == 1) return pending.future;
              return _data;
            }),
          ],
          child: _app(const DashboardPersonalSection()),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.completeError(StateError('private database diagnostics'));
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to load your courses. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('private database'), findsNothing);
      await tester.tap(find.text('Retry learning details'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.byType(StudentResumeCard), findsOneWidget);
    },
  );

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('personal Home fits $width dark=$dark text=$scale', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                studentHomeProvider.overrideWith((ref) => _data),
                displayNameProvider.overrideWithValue(
                  'Student with a long display name',
                ),
              ],
              child: _app(
                const DashboardPersonalSection(),
                dark: dark,
                scale: scale,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.byType(StudentRecentLesson).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.byType(StudentRecentLesson).last.hitTestable(),
            findsOneWidget,
          );
        });
      }
    }
  }
}
