import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:acendra/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:acendra/features/authentication/presentation/widgets/forgot_password_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.shouldThrow}) : super.forTesting();
  final AuthFailure? shouldThrow;

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (shouldThrow != null) throw shouldThrow!;
  }
}

Widget _wrap({AuthFailure? throws}) => ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWithValue(
      _FakeAuthRepository(shouldThrow: throws),
    ),
  ],
  child: MaterialApp(theme: AppTheme.light, home: const ForgotPasswordScreen()),
);

void main() {
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('hero and form fit $width, dark=$dark', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: const ForgotPasswordScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ForgotPasswordHero), findsOneWidget);
        final hero = tester.getRect(find.byType(ForgotPasswordHero));
        final heading = tester.getRect(find.text('Forgot your password?'));
        expect(hero.left, greaterThanOrEqualTo(0));
        expect(hero.right, lessThanOrEqualTo(width));
        expect(hero.bottom, lessThan(heading.top));
        expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
        expect(find.byIcon(Icons.send_outlined), findsOneWidget);
        await tester.ensureVisible(find.text('Back to Sign In'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('outlined back button returns to login', (tester) async {
    final router = GoRouter(
      initialLocation: '/forgot-password',
      routes: [
        GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Login destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Back to Sign In'));
    await tester.tap(find.text('Back to Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Login destination'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders email field and send button', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Send Reset Link'), findsOneWidget);
    expect(find.text('Forgot your password?'), findsOneWidget);
  });

  testWidgets('shows error when submitting empty field', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.ensureVisible(find.text('Send Reset Link'));
    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
  });

  testWidgets('shows error for invalid email format', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.enterText(find.byType(TextField), 'notanemail');
    await tester.ensureVisible(find.text('Send Reset Link'));
    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('shows success view after sending reset email', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.ensureVisible(find.text('Send Reset Link'));
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();
    expect(find.text('Check your inbox'), findsOneWidget);
    expect(find.textContaining('If an account exists'), findsOneWidget);
    expect(find.textContaining('user@example.com'), findsNothing);
    expect(find.byType(ForgotPasswordHero), findsOneWidget);
  });

  testWidgets('shows snackbar on auth failure', (tester) async {
    await tester.pumpWidget(_wrap(throws: const NetworkError()));
    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.ensureVisible(find.text('Send Reset Link'));
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();
    expect(find.textContaining('internet connection'), findsOneWidget);
  });

  testWidgets('has back to sign in link', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Back to Sign In'), findsOneWidget);
  });
}
