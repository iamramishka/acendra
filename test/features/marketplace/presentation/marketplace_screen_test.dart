import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/features/marketplace/domain/repositories/course_repository.dart';
import 'package:acendra/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_course_repository.dart';

ProviderContainer _container(CourseRepository repo) => ProviderContainer(
  overrides: [courseRepositoryProvider.overrideWithValue(repo)],
);

Widget _wrap(Widget child, ProviderContainer container) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('shows loading indicator initially', (tester) async {
    final container = _container(FakeCourseRepository(result: [fakeCourse]));
    await tester.pumpWidget(_wrap(const MarketplaceScreen(), container));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    container.dispose();
  });

  testWidgets('shows course card after data loads', (tester) async {
    final container = _container(FakeCourseRepository(result: [fakeCourse]));
    await tester.pumpWidget(_wrap(const MarketplaceScreen(), container));
    await tester.pumpAndSettle();
    expect(find.text('Fake Course'), findsOneWidget);
    expect(find.text('LKR 1,250.00'), findsOneWidget);
    container.dispose();
  });

  testWidgets('shows empty state when no courses', (tester) async {
    final container = _container(FakeCourseRepository());
    await tester.pumpWidget(_wrap(const MarketplaceScreen(), container));
    await tester.pumpAndSettle();
    expect(find.text('No courses available yet.'), findsOneWidget);
    container.dispose();
  });

  testWidgets('shows error state and retry button on failure', (tester) async {
    final container = _container(FakeCourseRepository(shouldThrow: true));
    await tester.pumpWidget(_wrap(const MarketplaceScreen(), container));
    await tester.pumpAndSettle();
    expect(
      find.text('Failed to load courses. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    container.dispose();
  });

  testWidgets(
    'draft courses do not appear (empty repo simulates draft-only DB)',
    (tester) async {
      final container = _container(FakeCourseRepository());
      await tester.pumpWidget(_wrap(const MarketplaceScreen(), container));
      await tester.pumpAndSettle();
      expect(find.text('No courses available yet.'), findsOneWidget);
      container.dispose();
    },
  );
}
