import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/core/widgets/navigation/public_shell.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/providers/navigation_access_provider.dart';
import 'package:acendra/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _AuthRepository extends AuthRepository {
  _AuthRepository({this.fail = false}) : super.forTesting();
  final bool fail;
  int signOutCalls = 0;
  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (fail) throw StateError('synthetic logout error');
  }
}

Future<GoRouter> _pump(
  WidgetTester tester, {
  bool admin = false,
  bool roleError = false,
  bool authenticated = true,
  double width = 1440,
  Brightness brightness = Brightness.light,
  _AuthRepository? repository,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    initialLocation: RouteNames.marketplace,
    routes: [
      GoRoute(
        path: RouteNames.marketplace,
        builder: (_, _) => const PublicShell(child: Text('marketplace body')),
      ),
      for (final path in [
        RouteNames.profile,
        RouteNames.admin,
        RouteNames.login,
        RouteNames.myCourses,
      ])
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(body: Text('Destination $path')),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isAuthenticatedProvider.overrideWithValue(authenticated),
        displayNameProvider.overrideWithValue('Jane Learner'),
        navigationAccessProvider.overrideWith((_) async {
          if (roleError) throw StateError('offline');
          return admin;
        }),
        authRepositoryProvider.overrideWithValue(
          repository ?? _AuthRepository(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(brightness: brightness),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('account menu opens profile at $width in $brightness', (
        tester,
      ) async {
        final router = await _pump(
          tester,
          width: width,
          brightness: brightness,
        );
        expect(find.text('Sign in'), findsNothing);
        expect(find.text('J'), findsOneWidget);
        await tester.tap(find.byTooltip('Account menu'));
        await tester.pumpAndSettle();
        expect(find.text('Admin'), findsNothing);
        await tester.tap(
          find.ancestor(
            of: find.text('Profile'),
            matching: find.byWidgetPredicate(
              (widget) => widget is PopupMenuEntry<Object?>,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          RouteNames.profile,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final width in [390.0, 1440.0]) {
    testWidgets('staff reaches Admin at $width', (tester) async {
      final router = await _pump(tester, admin: true, width: width);
      if (width < 600) {
        await tester.tap(find.byTooltip('Account menu'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, RouteNames.admin);
    });
  }

  testWidgets('role failure hides Admin but profile menu still works', (
    tester,
  ) async {
    await _pump(tester, roleError: true);
    await tester.tap(find.byTooltip('Account menu'));
    await tester.pumpAndSettle();
    expect(find.text('Admin'), findsNothing);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('anonymous marketplace retains sign in navigation', (
    tester,
  ) async {
    await _pump(tester, authenticated: false);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byTooltip('Account menu'), findsNothing);
    expect(find.text('Admin'), findsNothing);
  });

  testWidgets('sign out invokes existing repository and navigates to login', (
    tester,
  ) async {
    final repository = _AuthRepository();
    final router = await _pump(tester, repository: repository);
    await tester.tap(find.byTooltip('Account menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(repository.signOutCalls, 1);
    expect(router.routeInformationProvider.value.uri.path, RouteNames.login);
  });

  testWidgets(
    'sign out failure shows retry message and retains current route',
    (tester) async {
      final router = await _pump(
        tester,
        repository: _AuthRepository(fail: true),
      );
      await tester.tap(find.byTooltip('Account menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not sign out. Please try again.'),
        findsOneWidget,
      );
      expect(
        router.routeInformationProvider.value.uri.path,
        RouteNames.marketplace,
      );
    },
  );
}
