import 'dart:async';

import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/checkout/data/repositories/student_order_repository.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_actor_provider.dart';
import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:acendra/features/marketplace/presentation/screens/course_detail_screen.dart';
import 'package:acendra/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fixtures/catalog_preview_fixtures.dart';

// Mutable repositories model changed server responses without production data,
// provider-result overrides, payment mutations or a Supabase connection.
class _Courses extends CatalogPreviewRepository {
  List<CourseSummary> courses = [...catalogPreviewCourses];
  int reads = 0;

  @override
  Future<List<CourseSummary>> listPublished() async {
    reads++;
    return [...courses];
  }
}

class _Orders implements StudentOrderRepository {
  Future<StudentOrder?> Function() response = () async => null;
  final List<(String, String)> requests = [];

  @override
  Future<StudentOrder?> findOpen(String actor, String courseId) {
    requests.add((actor, courseId));
    return response();
  }

  @override
  Future<StudentOrder> read(String actor, String orderId) =>
      throw UnimplementedError('The acceptance test must not read payments.');
}

StudentOrder _order(CourseSummary course, String status) => StudentOrder(
  id: 'synthetic-order-${course.id}',
  courseId: course.id,
  title: course.title,
  number: 'QA-${course.id}',
  amountMinor: course.priceMinor,
  currency: course.currencyCode,
  method: 'bank_transfer',
  status: status,
);

Future<(GoRouter, ProviderContainer)> _mount(
  WidgetTester tester,
  _Courses courses,
  _Orders orders, {
  String location = '/marketplace',
}) async {
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      currentSessionProvider.overrideWith((ref) => null),
      checkoutActorProvider.overrideWith((ref) => 'synthetic-student'),
      courseRepositoryProvider.overrideWithValue(courses),
      studentOrderRepositoryProvider.overrideWithValue(orders),
    ],
  );
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/marketplace',
        builder: (_, _) => const Scaffold(body: MarketplaceScreen()),
      ),
      GoRoute(
        path: '/marketplace/:courseId',
        builder: (_, state) =>
            CourseDetailScreen(courseId: state.pathParameters['courseId']!),
      ),
      for (final path in ['/orders/:orderId', '/checkout/:courseId'])
        GoRoute(
          path: path,
          builder: (_, state) => Scaffold(body: Text(state.uri.path)),
        ),
    ],
  );
  addTearDown(() {
    router.dispose();
    container.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  // Bounded pumps also allow assertions while order requests are pending.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return (router, container);
}

void main() {
  testWidgets(
    'reopening details rechecks an order created since the last visit',
    (tester) async {
      final courses = _Courses();
      final course = courses.courses.first;
      final orders = _Orders();
      await _mount(tester, courses, orders);
      await tester.pumpAndSettle();
      await tester.tap(find.text(course.title));
      await tester.pumpAndSettle();
      expect(find.text('Buy Course'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      final order = _order(course, 'pending_verification');
      orders.response = () async => order;
      await tester.tap(find.text(course.title));
      await tester.pumpAndSettle();
      expect(find.text('Buy Course'), findsNothing);
      expect(find.text(order.statusLabel), findsOneWidget);
      expect(find.text('Payment Status'), findsOneWidget);
      expect(orders.requests.length, 2);
    },
  );

  testWidgets('combined search/categories survive detail and back navigation', (
    tester,
  ) async {
    final courses = _Courses();
    final (router, _) = await _mount(tester, courses, _Orders());
    await tester.pumpAndSettle();
    final course = courses.courses.first;
    final category = courses.categories.firstWhere(
      (category) => category.id == course.categoryId,
    );
    await tester.enterText(
      find.byType(SearchBar),
      '  ${course.title.toUpperCase()}  ',
    );
    await tester.tap(find.widgetWithText(FilterChip, category.name));
    await tester.pumpAndSettle();
    expect(find.text('1 Course'), findsOneWidget);
    await tester.tap(find.text(course.title));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/marketplace/${course.id}',
    );
    expect(find.text(course.title), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('1 Course'), findsOneWidget);
    expect(
      tester.widget<SearchBar>(find.byType(SearchBar)).controller!.text.trim(),
      course.title.toUpperCase(),
    );
    final otherCategory = courses.categories.firstWhere(
      (item) => item.id != category.id,
    );
    await tester.tap(find.widgetWithText(FilterChip, otherCategory.name));
    await tester.pumpAndSettle();
    expect(find.text('0 Courses'), findsOneWidget);
    expect(
      find.text('No courses found. Try a different word or category.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(SearchBar), '');
    await tester.tap(find.widgetWithText(FilterChip, 'All Courses'));
    await tester.pumpAndSettle();
    expect(find.text('${courses.courses.length} Courses'), findsOneWidget);
  });

  for (final status in ['created', 'pending_payment', 'pending_verification']) {
    testWidgets('$status order routes to its status and survives cold reload', (
      tester,
    ) async {
      final courses = _Courses();
      final course = courses.courses.last;
      final order = _order(course, status);
      final orders = _Orders()..response = () async => order;
      final location = '/marketplace/${course.id}';
      final (router, _) = await _mount(
        tester,
        courses,
        orders,
        location: location,
      );
      await tester.pumpAndSettle();
      expect(find.text('Buy Course'), findsNothing);
      expect(find.text(order.statusLabel), findsOneWidget);
      expect(orders.requests.single, ('synthetic-student', course.id));
      await tester.tap(find.widgetWithText(AppButton, 'Payment Status'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/orders/${order.id}',
      );

      // A fresh router and provider container at the same URL model a page
      // reload: no retained route extras, cached identity or in-memory order.
      await tester.pumpWidget(const SizedBox());
      await _mount(tester, courses, orders, location: location);
      await tester.pumpAndSettle();
      expect(find.text(course.title), findsOneWidget);
      expect(find.text('Payment Status'), findsOneWidget);
      expect(orders.requests.length, 2);
      expect(find.text('Buy Course'), findsNothing);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(MarketplaceScreen), findsOneWidget);
    });
  }

  testWidgets(
    'unknown order state blocks purchase and retry reads repository',
    (tester) async {
      final courses = _Courses();
      final orders = _Orders();
      final pending = Completer<StudentOrder?>();
      orders.response = () => pending.future;
      await _mount(
        tester,
        courses,
        orders,
        location: '/marketplace/${courses.courses.first.id}',
      );
      expect(
        tester
            .widget<AppButton>(
              find.widgetWithText(AppButton, 'Checking payment…'),
            )
            .onPressed,
        isNull,
      );
      pending.completeError(StateError('synthetic private order failure'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AppButton>(
              find.widgetWithText(AppButton, 'Payment status unavailable'),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.textContaining('synthetic private order failure'),
        findsNothing,
      );
      orders.response = () async => null;
      await tester.tap(find.text('Retry payment status'));
      await tester.pumpAndSettle();
      expect(find.text('Buy Course'), findsOneWidget);
      expect(orders.requests.length, 2);
    },
  );

  testWidgets(
    'catalog refresh and cold reload display changed repository data',
    (tester) async {
      final courses = _Courses();
      final orders = _Orders();
      final (_, container) = await _mount(tester, courses, orders);
      await tester.pumpAndSettle();
      final remaining = courses.courses.last;
      courses.courses = [remaining];
      await container.read(marketplaceProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(find.text('1 Course'), findsOneWidget);
      expect(find.text(remaining.title), findsOneWidget);
      expect(courses.reads, 2);
      await tester.pumpWidget(const SizedBox());
      await _mount(tester, courses, orders);
      await tester.pumpAndSettle();
      expect(find.text('1 Course'), findsOneWidget);
      expect(find.text(remaining.title), findsOneWidget);
      expect(courses.reads, 3);
    },
  );
}
