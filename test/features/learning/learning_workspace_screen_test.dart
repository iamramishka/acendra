import 'package:acendra/core/widgets/feedback/app_skeleton.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/features/learning/domain/entities/lesson_content.dart';
import 'package:acendra/features/learning/presentation/providers/learning_provider.dart';
import 'package:acendra/features/learning/presentation/screens/learning_workspace_screen.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Stub notifier — wraps a fixed state; no real async calls.
// ---------------------------------------------------------------------------

class _StubLearningNotifier extends LearningNotifier {
  _StubLearningNotifier(LearningState initial, Ref ref)
    : super(initial.courseId, ref) {
    // Override the state set by the super constructor immediately.
    state = initial;
  }

  @override
  Future<void> loadCourse(String courseId) async {}

  @override
  Future<void> selectLesson(String lessonId) async {}
}

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

const _testCourseId = 'course-test-1';

const _sections = [
  CurriculumSection(
    id: 'sec-1',
    title: 'Introduction',
    position: 1,
    lessons: [
      LessonItem(
        id: 'les-1',
        title: 'Welcome lesson',
        lessonType: 'text',
        position: 1,
        isPreview: true,
      ),
      LessonItem(
        id: 'les-2',
        title: 'Second lesson',
        lessonType: 'text',
        position: 2,
        isPreview: false,
      ),
    ],
  ),
];

const _lessonContent = LessonContent(
  id: 'les-1',
  title: 'Welcome lesson',
  lessonType: 'text',
  position: 1,
  sectionId: 'sec-1',
  contentText: 'Hello, world! This is lesson content.',
);

// ---------------------------------------------------------------------------
// Widget helper
// ---------------------------------------------------------------------------

Widget _wrap(Widget child, LearningState stubState) {
  return ProviderScope(
    overrides: [
      learningWorkspaceProvider(_testCourseId).overrideWith(
        (ref) => _StubLearningNotifier(stubState, ref),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('LearningWorkspaceScreen', () {
    testWidgets('shows AppSkeleton placeholders in loading state', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LearningWorkspaceScreen(courseId: _testCourseId),
          const LearningState(
            courseId: _testCourseId,
            isLoading: true,
            sections: [],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AppSkeleton), findsWidgets);
    });

    testWidgets('shows AppErrorState when error is set and not loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LearningWorkspaceScreen(courseId: _testCourseId),
          const LearningState(
            courseId: _testCourseId,
            isLoading: false,
            error: 'Something went wrong',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('Could not load course content.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets(
      'desktop layout (>=900px) shows 280px sidebar SizedBox',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrap(
            const LearningWorkspaceScreen(courseId: _testCourseId),
            const LearningState(
              courseId: _testCourseId,
              isLoading: false,
              sections: _sections,
              currentLessonId: 'les-1',
              currentContent: _lessonContent,
            ),
          ),
        );
        await tester.pump();

        final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
        final hasSidebar = sizedBoxes.any((sb) => sb.width == 280.0);
        expect(
          hasSidebar,
          isTrue,
          reason: 'Expected a 280px SizedBox for the desktop sidebar',
        );
      },
    );

    testWidgets(
      'mobile layout (<900px) shows FloatingActionButton for curriculum',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrap(
            const LearningWorkspaceScreen(courseId: _testCourseId),
            const LearningState(
              courseId: _testCourseId,
              isLoading: false,
              sections: _sections,
              currentLessonId: 'les-1',
              currentContent: _lessonContent,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(FloatingActionButton), findsOneWidget);
      },
    );
  });
}
