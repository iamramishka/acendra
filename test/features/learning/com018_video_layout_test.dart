import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/learning/domain/entities/lesson_content.dart';
import 'package:acendra/features/learning/presentation/providers/learning_provider.dart';
import 'package:acendra/features/learning/presentation/screens/learning_workspace_screen.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:acendra/features/video_player/presentation/widgets/authorized_video_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _course = 'synthetic-course';
const _title = 'Building Responsive Interfaces';
const _state = LearningState(
  courseId: _course,
  progressReady: true,
  currentLessonId: 'video',
  currentContent: LessonContent(
    id: 'video',
    title: _title,
    lessonType: 'video',
    position: 0,
    sectionId: 'module',
  ),
  sections: [
    CurriculumSection(
      id: 'module',
      title: 'Synthetic module',
      position: 0,
      lessons: [
        LessonItem(
          id: 'video',
          title: _title,
          lessonType: 'video',
          position: 0,
          isPreview: false,
        ),
      ],
    ),
  ],
);

class _Lessons extends LearningNotifier {
  _Lessons(Ref ref) : super(_course, ref) {
    state = _state;
  }
  @override
  Future<void> loadCourse(String courseId) async {}
}

void main() {
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('artifact video order $width dark=$dark scale=$scale', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                currentSessionProvider.overrideWithValue(null),
                learningWorkspaceProvider(
                  _course,
                ).overrideWith((ref) => _Lessons(ref)),
              ],
              child: MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: const Scaffold(
                  body: LearningWorkspaceScreen(courseId: _course),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final player = find.byType(AuthorizedVideoWidget);
          final header = find.text('Lesson 01 · Video Lesson');
          expect(
            tester.getBottomLeft(player).dy,
            lessThan(tester.getTopLeft(header).dy),
          );
          expect(find.text('Course Progress'), findsOneWidget);
          expect(find.text('0 of 1 lessons completed'), findsOneWidget);
          final complete = find.widgetWithText(FilledButton, 'Mark Complete');
          expect(complete.hitTestable(), findsOneWidget);
          expect(tester.widget<FilledButton>(complete).onPressed, isNotNull);
          await tester.ensureVisible(find.text('Resources'));
          await tester.tap(find.text('Resources'));
          await tester.pumpAndSettle();
          expect(
            find.text('No PDF resources are available in this module.'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
