import 'package:acendra/features/learning/data/repositories/learning_progress_repository.dart';
import 'package:acendra/features/learning/domain/course_progress_summary.dart';
import 'package:acendra/features/learning/presentation/providers/course_overview_provider.dart';
import 'package:acendra/features/learning/presentation/screens/course_overview_screen.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

LessonItem _l(String id) => LessonItem(
  id: id,
  title: 'Lesson $id',
  lessonType: 'text',
  position: 1,
  isPreview: false,
);

final _sections = [
  CurriculumSection(id: 's1', title: 'Basics', position: 1, lessons: [_l('a')]),
  CurriculumSection(id: 's2', title: 'More', position: 2, lessons: [_l('b')]),
];

Future<String?> _pump(WidgetTester tester, CourseProgressSummary s) async {
  String? opened;
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) =>
            const Scaffold(body: CourseOverviewScreen(courseId: 'c1')),
      ),
      GoRoute(
        path: '/learn/:courseId/:lessonId',
        builder: (_, state) {
          opened = state.pathParameters['lessonId'];
          return const Scaffold(body: Text('workspace'));
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [courseOverviewProvider('c1').overrideWith((_) async => s)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

void main() {
  testWidgets('shows percent, counts and Resume opens the next lesson', (
    tester,
  ) async {
    final s = CourseProgressSummary.from(_sections, {
      'a': const SavedLessonProgress(lessonId: 'a', completed: true),
    });
    await _pump(tester, s);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('1 of 2 lessons completed'), findsOneWidget);
    expect(find.text('2 modules · 2 lessons'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    expect(find.text('workspace'), findsOneWidget);
  });

  testWidgets('fresh course offers Start Lesson', (tester) async {
    await _pump(tester, CourseProgressSummary.from(_sections, const {}));
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('Start Lesson'), findsOneWidget);
  });

  testWidgets('finished course shows completion instead of Resume', (
    tester,
  ) async {
    final s = CourseProgressSummary.from(_sections, {
      for (final id in ['a', 'b'])
        id: SavedLessonProgress(lessonId: id, completed: true),
    });
    await _pump(tester, s);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Course completed'), findsOneWidget);
    expect(find.text('Resume'), findsNothing);
  });
}
