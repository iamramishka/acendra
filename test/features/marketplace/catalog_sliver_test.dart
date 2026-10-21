import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:acendra/features/marketplace/presentation/widgets/course_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_course_repository.dart';

void main() {
  testWidgets(
    'offscreen catalog cards are built only when scrolled into view',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final courses = List.generate(100, (i) {
        final id = i.toString().padLeft(3, '0');
        return CourseSummary(
          id: 'course-$id',
          slug: 'course-$id',
          title: 'Course $id',
          shortDescription: 'Synthetic catalog fixture $id.',
          priceMinor: 1000,
          currencyCode: 'LKR',
          publishedAt: '2026-10-21',
        );
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            courseRepositoryProvider.overrideWithValue(
              FakeCourseRepository(result: courses),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: MarketplaceScreen())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('100 Courses'), findsOneWidget);
      expect(find.text('Course 000'), findsOneWidget);
      expect(find.text('Course 099'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Course 099'),
        600,
        maxScrolls: 120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Course 099'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('column count uses the container width on a wide screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 390,
              child: CustomScrollView(
                slivers: [
                  CourseGrid(courses: [fakeCourse, fakeCourse]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final cards = find.byType(Card);
    expect(
      tester.getTopLeft(cards.at(0)).dx,
      tester.getTopLeft(cards.at(1)).dx,
    );
    expect(
      tester.getTopLeft(cards.at(1)).dy,
      greaterThan(tester.getBottomLeft(cards.at(0)).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
