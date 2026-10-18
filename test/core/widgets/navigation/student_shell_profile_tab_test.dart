import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/core/widgets/navigation/student_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<void> _open(WidgetTester tester, String location) async {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      ShellRoute(
        builder: (_, _, child) => StudentShell(child: child),
        routes: [
          for (final path in [
            RouteNames.orders,
            RouteNames.settings,
            RouteNames.changePassword,
            RouteNames.marketplace,
          ])
            GoRoute(path: path, builder: (_, _) => Text('page $path')),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: router)),
  );
  await tester.pumpAndSettle();
}

int _selected(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

void main() {
  for (final path in [
    RouteNames.orders,
    RouteNames.settings,
    RouteNames.changePassword,
  ]) {
    testWidgets('$path highlights the Profile tab', (tester) async {
      await _open(tester, path);
      expect(_selected(tester), 3);
    });
  }

  testWidgets('Explore stays on its own tab', (tester) async {
    await _open(tester, RouteNames.marketplace);
    expect(_selected(tester), 1);
  });

  testWidgets('theme toggle lives in Settings, not the app bar', (
    tester,
  ) async {
    await _open(tester, RouteNames.marketplace);
    expect(find.byIcon(Icons.dark_mode), findsNothing);
    expect(find.byIcon(Icons.light_mode), findsNothing);
  });
}
