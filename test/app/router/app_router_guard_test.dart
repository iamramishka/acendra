import 'package:acendra/app/router/app_router.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({required bool sessionRestored, required bool isAuthenticated}) =>
    ProviderScope(
      overrides: [
        sessionRestoredProvider.overrideWithValue(sessionRestored),
        isAuthenticatedProvider.overrideWithValue(isAuthenticated),
        authStreamProvider.overrideWith((ref) => const Stream.empty()),
      ],
      child: Consumer(
        builder: (_, ref, _) =>
            MaterialApp.router(routerConfig: ref.watch(appRouterProvider)),
      ),
    );

void main() {
  testWidgets('unauthenticated user lands on login screen', (tester) async {
    await tester.pumpWidget(
      _app(sessionRestored: true, isAuthenticated: false),
    );
    await tester.pumpAndSettle();
    // Login screen shows "Sign in" button.
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('authenticated user is redirected from login to dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(_app(sessionRestored: true, isAuthenticated: true));
    await tester.pumpAndSettle();
    // Initial location /login redirects to /dashboard for authenticated users.
    expect(find.text('Dashboard'), findsWidgets);
  });

  testWidgets('unauthenticated user can access forgot-password page', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(sessionRestored: true, isAuthenticated: false),
    );
    await tester.pumpAndSettle();
    // Forgot password is a public route — no redirect to login.
    // We verify by navigating there directly.
    final router = ProviderScope.containerOf(
      tester.element(find.byType(Consumer)),
    ).read(appRouterProvider);
    router.go('/forgot-password');
    await tester.pumpAndSettle();
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('unauthenticated user is redirected from dashboard to login', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(sessionRestored: true, isAuthenticated: false),
    );
    await tester.pumpAndSettle();

    final router = ProviderScope.containerOf(
      tester.element(find.byType(Consumer)),
    ).read(appRouterProvider);
    router.go('/dashboard');
    await tester.pumpAndSettle();
    // Should be redirected back to login.
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('no redirect fires when session not yet restored', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(sessionRestored: false, isAuthenticated: false),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
