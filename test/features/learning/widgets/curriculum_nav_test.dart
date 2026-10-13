import 'package:acendra/features/learning/presentation/widgets/curriculum_nav.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

const _lesson1 = LessonItem(
  id: 'l1',
  title: 'Introduction',
  lessonType: 'video',
  position: 1,
  isPreview: true,
  durationSeconds: 185,
);

const _lesson2 = LessonItem(
  id: 'l2',
  title: 'Core Concepts',
  lessonType: 'text',
  position: 2,
  isPreview: false,
);

const _lesson3 = LessonItem(
  id: 'l3',
  title: 'Hands-on Exercise',
  lessonType: 'pdf',
  position: 3,
  isPreview: false,
  durationSeconds: 600,
);

const _sections = [
  CurriculumSection(
    id: 's1',
    title: 'Getting Started',
    position: 1,
    lessons: [_lesson1, _lesson2],
  ),
  CurriculumSection(
    id: 's2',
    title: 'Deep Dive',
    position: 2,
    lessons: [_lesson3],
  ),
];

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CurriculumNav', () {
    testWidgets('renders section titles', (tester) async {
      await tester.pumpWidget(
        _wrap(CurriculumNav(sections: _sections, onLessonTap: (_) {})),
      );

      expect(find.text('1. Getting Started'), findsOneWidget);
      expect(find.text('2. Deep Dive'), findsOneWidget);
    });

    testWidgets(
      'calls onLessonTap with correct id when lesson tile is tapped',
      (tester) async {
        String? tappedId;

        await tester.pumpWidget(
          _wrap(
            CurriculumNav(
              sections: _sections,
              onLessonTap: (id) => tappedId = id,
            ),
          ),
        );

        // Expand the first section so lesson tiles become visible.
        await tester.tap(find.text('1. Getting Started'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Introduction'));
        await tester.pump();

        expect(tappedId, equals('l1'));
      },
    );

    testWidgets('highlights the current lesson tile with selected state', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          CurriculumNav(
            sections: _sections,
            currentLessonId: 'l1',
            onLessonTap: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The section containing l1 is auto-expanded; find the ListTile.
      final listTileFinder = find.ancestor(
        of: find.text('Introduction'),
        matching: find.byType(ListTile),
      );
      expect(listTileFinder, findsOneWidget);

      final tile = tester.widget<ListTile>(listTileFinder);
      expect(
        tile.selected,
        isTrue,
        reason: 'Expected the current lesson tile to have selected == true',
      );
    });

    testWidgets('section containing currentLessonId is expanded by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          CurriculumNav(
            sections: _sections,
            currentLessonId: 'l1',
            onLessonTap: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Lesson from section 1 should be visible without tapping.
      expect(find.text('Introduction'), findsOneWidget);
    });

    testWidgets('shows Preview chip for isPreview lessons', (tester) async {
      await tester.pumpWidget(
        _wrap(CurriculumNav(sections: _sections, onLessonTap: (_) {})),
      );

      // Expand section 1.
      await tester.tap(find.text('1. Getting Started'));
      await tester.pumpAndSettle();

      expect(find.text('Preview'), findsOneWidget);
    });

    testWidgets('shows empty state when no sections provided', (tester) async {
      await tester.pumpWidget(
        _wrap(CurriculumNav(sections: const [], onLessonTap: (_) {})),
      );

      expect(find.text('No curriculum available yet.'), findsOneWidget);
    });

    testWidgets('formats durationSeconds as mm:ss', (tester) async {
      await tester.pumpWidget(
        _wrap(CurriculumNav(sections: _sections, onLessonTap: (_) {})),
      );

      // Expand section 1 to see lesson1 (185 s = 03:05).
      await tester.tap(find.text('1. Getting Started'));
      await tester.pumpAndSettle();

      expect(find.text('03:05'), findsOneWidget);
    });
  });
}
