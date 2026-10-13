import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/features/marketplace/presentation/screens/course_detail_screen.dart';
import 'package:acendra/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../fakes/fake_course_repository.dart';

Widget _wrap(Widget child, {FakeCourseRepository? repo}) {
  final r = repo ?? FakeCourseRepository(result: [fakeCourse]);
  return UncontrolledProviderScope(
    container: ProviderContainer(
      overrides: [courseRepositoryProvider.overrideWithValue(r)],
    ),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

Widget _wrapWithRouter({FakeCourseRepository? repo}) {
  final r = repo ?? FakeCourseRepository(result: [fakeCourse], detail: fakeDetail);
  final router = GoRouter(
    initialLocation: '/marketplace',
    routes: [
      GoRoute(
        path: '/marketplace',
        builder: (_, __) => const MarketplaceScreen(),
      ),
      GoRoute(
        path: '/marketplace/:courseId',
        builder: (_, state) =>
            CourseDetailScreen(courseId: state.pathParameters['courseId']!),
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: ProviderContainer(
      overrides: [courseRepositoryProvider.overrideWithValue(r)],
    ),
    child: MaterialApp.router(routerConfig: router),
  );
}

const _dartCourse = CourseSummary(
  id: 'id-2',
  slug: 'advanced-dart',
  title: 'Advanced Dart',
  shortDescription: 'Dart course',
  priceMinor: 0,
  currencyCode: 'LKR',
  publishedAt: '2026-01-01T00:00:00Z',
);

void main() {
  group('MarketplaceScreen', () {
    testWidgets('shows course title when data loads', (tester) async {
      await tester.pumpWidget(
        _wrap(const MarketplaceScreen(),
            repo: FakeCourseRepository(result: [fakeCourse])),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Fake Course'), findsOneWidget);
    });

    testWidgets('shows empty state when no courses', (tester) async {
      await tester.pumpWidget(
        _wrap(const MarketplaceScreen(),
            repo: FakeCourseRepository(result: [])),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No courses available yet.'), findsOneWidget);
    });

    testWidgets('shows error state on failure', (tester) async {
      await tester.pumpWidget(
        _wrap(const MarketplaceScreen(),
            repo: FakeCourseRepository(shouldThrow: true)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.textContaining('Failed to load'), findsOneWidget);
    });

    testWidgets('filters by search query', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MarketplaceScreen(),
          repo: FakeCourseRepository(result: [fakeCourse, _dartCourse]),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(find.byType(SearchBar), 'Dart');
      await tester.pump();

      expect(find.text('Advanced Dart'), findsOneWidget);
      expect(find.text('Fake Course'), findsNothing);
    });

    testWidgets('shows category filter chips when categories present',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MarketplaceScreen(),
          repo: FakeCourseRepository(
            result: [fakeCourse],
            categories: [fakeCategory],
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
    });

    testWidgets('tapping a course card navigates to course detail',
        (tester) async {
      await tester.pumpWidget(_wrapWithRouter());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Fake Course'));
      await tester.pumpAndSettle();

      expect(find.text('Enroll Now'), findsOneWidget);
    });
  });

  group('CourseDetailScreen', () {
    testWidgets('shows course title and price', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CourseDetailScreen(courseId: 'fake-id-1'),
          repo: FakeCourseRepository(detail: fakeDetail),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Fake Course'), findsWidgets);
      expect(find.textContaining('LKR'), findsOneWidget);
    });

    testWidgets('shows Enroll Now CTA when not enrolled', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CourseDetailScreen(courseId: 'fake-id-1'),
          repo: FakeCourseRepository(detail: fakeDetail, enrolled: false),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Enroll Now'), findsOneWidget);
    });

    testWidgets('shows Continue Learning CTA when enrolled', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CourseDetailScreen(courseId: 'fake-id-1'),
          repo: FakeCourseRepository(detail: fakeDetail, enrolled: true),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Continue Learning'), findsOneWidget);
      expect(find.text('Enrolled'), findsOneWidget);
    });

    testWidgets('shows curriculum section title', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CourseDetailScreen(courseId: 'fake-id-1'),
          repo: FakeCourseRepository(detail: fakeDetail),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Getting Started'), findsOneWidget);
    });

    testWidgets('shows error state on failure', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CourseDetailScreen(courseId: 'bad-id'),
          repo: FakeCourseRepository(shouldThrow: true),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.textContaining('Failed to load course'), findsOneWidget);
    });
  });
}
