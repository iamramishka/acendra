import 'package:acendra/features/my_courses/data/repositories/supabase_my_courses_repository.dart';
import 'package:acendra/features/my_courses/domain/repositories/my_courses_repository.dart';
import 'package:acendra/features/my_courses/presentation/screens/my_courses_screen.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_my_courses_repository.dart';

ProviderContainer _container(MyCoursesRepository repo) => ProviderContainer(
      overrides: [myCoursesRepositoryProvider.overrideWithValue(repo)],
    );

Widget _wrap(Widget child, ProviderContainer container) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: child),
    );

void main() {
  group('MyCoursesScreen', () {
    testWidgets('shows loading indicator while courses are being fetched',
        (tester) async {
      // The async notifier starts in AsyncLoading before the first future
      // resolves. Pumping without settling captures that initial frame.
      final container = _container(
        FakeMyCoursesRepository(result: [fakeEnrolledCourse]),
      );

      await tester.pumpWidget(_wrap(const MyCoursesScreen(), container));
      // Do NOT call pumpAndSettle — the async future is still in flight.

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      container.dispose();
    });

    testWidgets('shows AppEmptyState when enrolled course list is empty',
        (tester) async {
      final container = _container(FakeMyCoursesRepository());

      await tester.pumpWidget(_wrap(const MyCoursesScreen(), container));
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(
        find.text('You have not enrolled in any courses yet.'),
        findsOneWidget,
      );
      container.dispose();
    });

    testWidgets('shows course card when enrolled courses are returned',
        (tester) async {
      final container = _container(
        FakeMyCoursesRepository(result: [fakeEnrolledCourse]),
      );

      await tester.pumpWidget(_wrap(const MyCoursesScreen(), container));
      await tester.pumpAndSettle();

      expect(find.text('Flutter Fundamentals'), findsOneWidget);
      container.dispose();
    });

    testWidgets('shows error state with retry button on failure',
        (tester) async {
      final container =
          _container(FakeMyCoursesRepository(shouldThrow: true));

      await tester.pumpWidget(_wrap(const MyCoursesScreen(), container));
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(
        find.text('Failed to load your courses. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      container.dispose();
    });
  });
}
