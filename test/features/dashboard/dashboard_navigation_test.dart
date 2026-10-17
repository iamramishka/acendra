import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/core/widgets/navigation/student_shell.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/providers/navigation_access_provider.dart';
import 'package:acendra/features/dashboard/presentation/dashboard_copy.dart';
import 'package:acendra/features/dashboard/presentation/screens/dashboard_saved_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<GoRouter> _pump(
  WidgetTester tester, {
  double width = 390,
  double scale = 1,
  bool dark = false,
  String initial = RouteNames.dashboardHome,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      ShellRoute(
        builder: (_, _, child) => StudentShell(child: child),
        routes: [
          for (final path in [
            RouteNames.dashboardHome,
            RouteNames.myCourses,
            RouteNames.profile,
            RouteNames.profileEdit,
          ])
            GoRoute(path: path, builder: (_, _) => Text(path)),
          GoRoute(
            path: RouteNames.savedCourses,
            builder: (_, _) => const DashboardSavedScreen(),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.marketplace,
        builder: (_, _) => const Text('Catalog'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStreamProvider.overrideWith((ref) => const Stream.empty()),
        navigationAccessProvider.overrideWith((ref) async => false),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('student navigation $width dark=$dark scale=$scale', (
          tester,
        ) async {
          final router = await _pump(
            tester,
            width: width,
            dark: dark,
            scale: scale,
          );
          final compact = width < 1024 || scale > 1.5;
          expect(
            find.byType(NavigationBar),
            compact ? findsOneWidget : findsNothing,
          );
          if (compact) {
            expect(find.byType(NavigationDestination), findsNWidgets(4));
            for (final index in [1, 2, 3, 0]) {
              await tester.tap(find.byType(NavigationDestination).at(index));
              await tester.pumpAndSettle();
              expect(
                tester
                    .widget<NavigationBar>(find.byType(NavigationBar))
                    .selectedIndex,
                index,
              );
              expect(tester.takeException(), isNull);
            }
            router.go(RouteNames.profileEdit);
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<NavigationBar>(find.byType(NavigationBar))
                  .selectedIndex,
              3,
            );
          } else {
            await tester.tap(find.text(DashboardCopy.saved));
            await tester.pumpAndSettle();
            expect(
              router.routeInformationProvider.value.uri.path,
              RouteNames.savedCourses,
            );
            await tester.tap(find.text(DashboardCopy.home));
            await tester.pumpAndSettle();
            expect(
              router.routeInformationProvider.value.uri.path,
              RouteNames.dashboardHome,
            );
            expect(find.text('Explore'), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }

  testWidgets('Saved explicitly unavailable and marketplace action works', (
    tester,
  ) async {
    final router = await _pump(tester, initial: RouteNames.savedCourses);
    expect(find.text(DashboardCopy.savedComingSoon), findsOneWidget);
    expect(find.text(DashboardCopy.savedExplanation), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    await tester.tap(find.text(DashboardCopy.exploreCourses));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.marketplace,
    );
    expect(find.text('Catalog'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
