import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/learning/presentation/widgets/video_lesson_panel.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _sections = [
  CurriculumSection(
    id: 'module',
    title: 'Current module',
    position: 1,
    lessons: [
      LessonItem(
        id: 'video',
        title: 'Video lesson',
        lessonType: 'video',
        position: 1,
        isPreview: false,
      ),
      LessonItem(
        id: 'guide',
        title: 'Long PDF lesson title for comfortable learning',
        lessonType: 'pdf',
        position: 2,
        isPreview: false,
      ),
      LessonItem(
        id: 'article',
        title: 'Article',
        lessonType: 'text',
        position: 3,
        isPreview: false,
      ),
    ],
  ),
  CurriculumSection(
    id: 'other',
    title: 'Other module',
    position: 2,
    lessons: [
      LessonItem(
        id: 'other-guide',
        title: 'Other module PDF',
        lessonType: 'pdf',
        position: 1,
        isPreview: false,
      ),
    ],
  ),
];

Widget _app({
  required ValueChanged<String> onResource,
  String section = 'module',
  bool dark = false,
  double scale = 1,
}) => ProviderScope(
  overrides: [currentSessionProvider.overrideWithValue(null)],
  child: MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Scaffold(
      body: VideoLessonPanel(
        lessonId: 'video',
        title: 'Video lesson',
        sectionId: section,
        sections: _sections,
        onResource: onResource,
      ),
    ),
  ),
);

void main() {
  testWidgets('resources contain only PDF lessons from the current module', (
    tester,
  ) async {
    String? opened;
    await tester.pumpWidget(_app(onResource: (id) => opened = id));
    await tester.tap(find.text('Resources'));
    await tester.pumpAndSettle();
    expect(find.text('Other module PDF'), findsNothing);
    expect(find.text('Article'), findsNothing);
    await tester.ensureVisible(
      find.text('Long PDF lesson title for comfortable learning'),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('Long PDF lesson title for comfortable learning'),
    );
    expect(opened, 'guide');
    expect(find.text('Open in protected reader'), findsOneWidget);
  });

  testWidgets('missing module resources show an honest empty state', (
    tester,
  ) async {
    await tester.pumpWidget(_app(section: 'missing', onResource: (_) {}));
    await tester.tap(find.text('Resources'));
    await tester.pumpAndSettle();
    expect(
      find.text('No PDF resources are available in this module.'),
      findsOneWidget,
    );
  });

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('resources layout $width dark=$dark scale=$scale', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            _app(dark: dark, scale: scale, onResource: (_) {}),
          );
          await tester.tap(find.text('Resources'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.text('Long PDF lesson title for comfortable learning'),
            findsOneWidget,
          );
        });
      }
    }
  }
}
