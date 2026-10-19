import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/core/widgets/navigation/public_shell.dart';
import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/features/marketplace/presentation/screens/course_detail_screen.dart';
import 'package:acendra/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fakes/fake_course_repository.dart';

void main() {
  Future<GoRouter> mount(WidgetTester tester, {bool deepLink = false}) async {
    final router = GoRouter(
      initialLocation: deepLink
          ? '/marketplace/fake-id-1'
          : RouteNames.marketplace,
      routes: [
        ShellRoute(
          builder: (_, _, child) => PublicShell(child: child),
          routes: [
            GoRoute(
              path: RouteNames.marketplace,
              builder: (_, _) => const MarketplaceScreen(),
            ),
            GoRoute(
              path: RouteNames.courseDetail,
              builder: (_, state) => CourseDetailScreen(
                courseId: state.pathParameters['courseId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: RouteNames.checkout,
          builder: (_, state) => Scaffold(
            body: Text('Checkout ${state.pathParameters['courseId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courseRepositoryProvider.overrideWithValue(
            FakeCourseRepository(result: [fakeCourse], detail: fakeDetail),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets(
    'catalog card shows real title and no fabricated app-name instructor',
    (tester) async {
      await mount(tester);
      expect(find.text('Fake Course').hitTestable(), findsOneWidget);
      expect(
        find.text('Acedra'),
        findsOneWidget,
      ); // Only the public navigation brand.
    },
  );

  testWidgets(
    'opening course updates route information and Courses returns to catalog',
    (tester) async {
      final router = await mount(tester);
      await tester.tap(find.text('Fake Course'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/marketplace/fake-id-1',
      );
      await tester.tap(find.text('Courses'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        RouteNames.marketplace,
      );
      expect(find.byType(MarketplaceScreen), findsOneWidget);
      expect(find.byType(CourseDetailScreen), findsNothing);
    },
  );

  testWidgets('deep-linked course back arrow returns to catalog', (
    tester,
  ) async {
    final router = await mount(tester, deepLink: true);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.marketplace,
    );
    expect(find.byType(MarketplaceScreen), findsOneWidget);
  });

  testWidgets('Buy Course works after opening course through public shell', (
    tester,
  ) async {
    final router = await mount(tester);
    await tester.tap(find.text('Fake Course'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buy Course'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/checkout/fake-id-1',
    );
    expect(find.text('Checkout fake-id-1'), findsOneWidget);
  });
}
