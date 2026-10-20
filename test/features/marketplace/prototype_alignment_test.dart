import 'dart:async';
import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/features/checkout/data/repositories/student_order_repository.dart';
import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:acendra/features/marketplace/presentation/screens/course_detail_screen.dart';
import 'package:acendra/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'fakes/fake_course_repository.dart';

const cheaper = CourseSummary(
  id: 'cheap',
  slug: 'cheap',
  title: 'Less expensive',
  shortDescription: 'Synthetic',
  priceMinor: 100,
  currencyCode: 'LKR',
  publishedAt: '2026-01-01',
);
const openOrder = StudentOrder(
  id: 'order-a',
  courseId: 'fake-id-1',
  title: 'Fake Course',
  number: 'TEST-A',
  amountMinor: 125000,
  currency: 'LKR',
  method: 'online',
  status: 'pending_verification',
);

void main() {
  test('price sorting preserves source list and respects filters', () async {
    final source = [fakeCourse, cheaper];
    final container = ProviderContainer(
      overrides: [
        courseRepositoryProvider.overrideWithValue(
          FakeCourseRepository(result: source),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(marketplaceProvider.future);
    container.read(courseSortProvider.notifier).state = CourseSort.priceLow;
    expect(
      container.read(filteredCoursesProvider).requireValue.first.id,
      'cheap',
    );
    container.read(courseSortProvider.notifier).state = CourseSort.priceHigh;
    expect(
      container.read(filteredCoursesProvider).requireValue.first.id,
      fakeCourse.id,
    );
    container.read(searchQueryProvider.notifier).state = 'Less expensive';
    expect(
      container.read(filteredCoursesProvider).requireValue.single.id,
      'cheap',
    );
    expect(source.first.id, fakeCourse.id);
  });

  testWidgets('search miss is different from an empty catalog', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courseRepositoryProvider.overrideWithValue(
            FakeCourseRepository(result: [fakeCourse]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: MarketplaceScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'no-matching-course');
    await tester.pumpAndSettle();
    expect(
      find.text('No courses found. Try a different word or category.'),
      findsOneWidget,
    );
    expect(find.text('No courses available yet.'), findsNothing);
  });

  testWidgets(
    'pending-order action opens authoritative status instead of checkout',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/course',
        routes: [
          GoRoute(
            path: '/course',
            builder: (_, _) => CourseDetailScreen(courseId: fakeCourse.id),
          ),
          GoRoute(
            path: '/orders/:orderId',
            builder: (_, state) => Scaffold(
              body: Text('Status ${state.pathParameters['orderId']}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            courseRepositoryProvider.overrideWithValue(
              FakeCourseRepository(detail: fakeDetail),
            ),
            openCourseOrderProvider(
              fakeCourse.id,
            ).overrideWith((ref) async => openOrder),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Buy Course'), findsNothing);
      await tester.tap(find.text('Payment Status'));
      await tester.pumpAndSettle();
      expect(find.text('Status order-a'), findsOneWidget);
    },
  );

  testWidgets('unknown open-order state never enables another purchase', (
    tester,
  ) async {
    final pending = Completer<StudentOrder?>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courseRepositoryProvider.overrideWithValue(
            FakeCourseRepository(detail: fakeDetail),
          ),
          openCourseOrderProvider(
            fakeCourse.id,
          ).overrideWith((ref) => pending.future),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: CourseDetailScreen(courseId: fakeCourse.id),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.widgetWithText(AppButton, 'Checking payment…'),
          )
          .onPressed,
      isNull,
    );
    pending.completeError(StateError('private error'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AppButton>(
            find.widgetWithText(AppButton, 'Payment status unavailable'),
          )
          .onPressed,
      isNull,
    );
    expect(find.textContaining('private error'), findsNothing);
  });

  for (final dark in [false, true]) {
    for (final width in [320.0, 390.0, 768.0, 1440.0]) {
      testWidgets('course details renders at $width dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              courseRepositoryProvider.overrideWithValue(
                FakeCourseRepository(detail: fakeDetail),
              ),
            ],
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: CourseDetailScreen(courseId: fakeCourse.id),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Buy Course'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
