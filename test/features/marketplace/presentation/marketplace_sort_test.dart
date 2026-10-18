import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:acendra/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_course_repository.dart';

CourseSummary _c(String id, int price, String published) => CourseSummary(
  id: id,
  slug: id,
  title: 'Course $id',
  shortDescription: 'About $id',
  priceMinor: price,
  currencyCode: 'LKR',
  publishedAt: published,
);

void main() {
  final repo = FakeCourseRepository(
    result: [
      _c('mid', 200000, '2026-02-01'),
      _c('cheap', 100000, '2026-01-01'),
      _c('dear', 300000, '2026-03-01'),
    ],
  );

  ProviderContainer container() => ProviderContainer(
    overrides: [courseRepositoryProvider.overrideWithValue(repo)],
  );

  test('sorts by price in both directions and by newest', () async {
    final c = container();
    addTearDown(c.dispose);
    await c.read(marketplaceProvider.future);

    List<String> ids() =>
        c.read(filteredCoursesProvider).requireValue.map((e) => e.id).toList();

    expect(ids(), ['dear', 'mid', 'cheap']);
    c.read(courseSortProvider.notifier).state = CourseSort.priceLow;
    expect(ids(), ['cheap', 'mid', 'dear']);
    c.read(courseSortProvider.notifier).state = CourseSort.priceHigh;
    expect(ids(), ['dear', 'mid', 'cheap']);
  });

  testWidgets('shows count, title and a no-match message', (tester) async {
    final c = container();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: Scaffold(body: MarketplaceScreen())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Explore Courses'), findsOneWidget);
    expect(find.text('3 Courses'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz-no-match');
    await tester.pumpAndSettle();
    expect(
      find.text('No courses found. Try a different word or category.'),
      findsOneWidget,
    );
    expect(find.text('No courses available yet.'), findsNothing);
  });
}
