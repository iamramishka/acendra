import 'package:acendra/features/learning/data/repositories/learning_progress_repository.dart';
import 'package:acendra/features/learning/domain/course_progress_summary.dart';
import 'package:acendra/features/learning/presentation/providers/course_overview_metadata_provider.dart';
import 'package:acendra/features/learning/presentation/providers/course_overview_provider.dart';
import 'package:acendra/features/learning/presentation/screens/course_overview_screen.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  for (final action in ['Resume', 'curriculum lesson']) {
    testWidgets('$action dismisses the old completion notice on navigation', (
      tester,
    ) async {
      final summary = CourseProgressSummary.from(
        const [
          CurriculumSection(
            id: 'module',
            title: 'Module',
            position: 1,
            lessons: [
              LessonItem(
                id: 'a',
                title: 'First lesson',
                lessonType: 'text',
                position: 1,
                isPreview: false,
              ),
              LessonItem(
                id: 'b',
                title: 'Next lesson',
                lessonType: 'text',
                position: 2,
                isPreview: false,
              ),
            ],
          ),
        ],
        const {'a': SavedLessonProgress(lessonId: 'a', completed: true)},
      );
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                const Scaffold(body: CourseOverviewScreen(courseId: 'course')),
          ),
          GoRoute(
            path: '/learn/course/b',
            builder: (_, _) => const Scaffold(
              body: Center(child: Text('Next lesson destination')),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            courseOverviewProvider('course').overrideWith((_) async => summary),
            courseOverviewMetadataProvider(
              'course',
            ).overrideWith((_) async => null),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      ScaffoldMessenger.of(
        tester.element(find.byType(CourseOverviewScreen)),
      ).showSnackBar(
        const SnackBar(
          duration: Duration(minutes: 1),
          content: Text('Module finished'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Module finished'), findsOneWidget);
      final target = action == 'Resume'
          ? find.text('Resume')
          : find.widgetWithText(ListTile, 'Next lesson');
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/learn/course/b');
      expect(find.text('Next lesson destination'), findsOneWidget);
      expect(find.text('Module finished'), findsNothing);
    });
  }
}
