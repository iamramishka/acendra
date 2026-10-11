// CSA-076 — Complete authentication flow tests.
// These widget-level integration tests exercise the full auth UI flows
// end-to-end against fake repositories (no real Supabase needed).

import 'package:acendra/app/router/app_router.dart';
import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/providers/logout_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _SuccessAuthRepository extends AuthRepository {
  _SuccessAuthRepository() : super.forTesting();

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {}

  @override
  Future<void> resendVerification({required String email}) async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> signOut() async {}
}

class _FailAuthRepository extends AuthRepository {
  _FailAuthRepository(this._failure) : super.forTesting();
  final AuthFailure _failure;

  @override
  Future<void> signIn({required String email, required String password}) async {
    throw _failure;
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    throw _failure;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    throw _failure;
  }

  @override
  Future<void> signOut() async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _app({required AuthRepository repo, bool isAuthenticated = false}) =>
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        authStreamProvider.overrideWith((ref) => const Stream.empty()),
        sessionRestoredProvider.overrideWithValue(true),
        isAuthenticatedProvider.overrideWithValue(isAuthenticated),
        logoutProvider.overrideWith(LogoutNotifier.new),
      ],
      child: Consumer(
        builder: (_, ref, _) =>
            MaterialApp.router(routerConfig: ref.watch(appRouterProvider)),
      ),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Login flow', () {
    testWidgets('unauthenticated user sees login screen on start', (
      tester,
    ) async {
      await tester.pumpWidget(_app(repo: _SuccessAuthRepository()));
      await tester.pumpAndSettle();
      expect(find.text('Sign in'), findsWidgets);
    });

    testWidgets('login with empty fields shows validation errors', (
      tester,
    ) async {
      await tester.pumpWidget(_app(repo: _SuccessAuthRepository()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in'));
      await tester.pump();
      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('login with invalid credentials shows error snackbar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(repo: _FailAuthRepository(const InvalidCredentials())),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'bad@example.com');
      final passwordFields = find.byType(TextField);
      await tester.enterText(passwordFields.last, 'wrongpass');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text(const InvalidCredentials().message), findsOneWidget);
    });
  });

  group('Registration flow', () {
    testWidgets('can navigate from login to register', (tester) async {
      await tester.pumpWidget(_app(repo: _SuccessAuthRepository()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();
      expect(find.text('Create account'), findsOneWidget);
    });

    testWidgets('register with empty fields shows validation errors', (
      tester,
    ) async {
      await tester.pumpWidget(_app(repo: _SuccessAuthRepository()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create account'));
      await tester.pump();
      expect(find.text('Enter your full name'), findsOneWidget);
    });

    testWidgets('email already in use shows error snackbar', (tester) async {
      await tester.pumpWidget(
        _app(repo: _FailAuthRepository(const EmailAlreadyInUse())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Jane Doe');
      await tester.enterText(fields.at(1), 'jane@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password123');
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text(const EmailAlreadyInUse().message), findsOneWidget);
    });
  });

  group('Forgot password flow', () {
    testWidgets('can navigate from login to forgot password', (tester) async {
      await tester.pumpWidget(_app(repo: _SuccessAuthRepository()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.text('Forgot password?'), findsWidgets);
    });

    testWidgets('submitting empty email shows validation error', (
      tester,
    ) async {
      await tester.pumpWidget(_app(repo: _SuccessAuthRepository()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send reset link'));
      await tester.pump();
      expect(find.text('Enter your email'), findsOneWidget);
    });
  });

  group('Authenticated user routing', () {
    testWidgets('authenticated user is redirected away from login', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(repo: _SuccessAuthRepository(), isAuthenticated: true),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Sign in'), findsNothing);
    });
  });

  group('Logout', () {
    testWidgets('sign out button on profile screen calls logout', (
      tester,
    ) async {
      var signedOut = false;
      final repo = _SuccessAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
            authStreamProvider.overrideWith((ref) => const Stream.empty()),
            sessionRestoredProvider.overrideWithValue(true),
            isAuthenticatedProvider.overrideWithValue(true),
            logoutProvider.overrideWith(
              () => _TrackingLogoutNotifier(onLogout: () => signedOut = true),
            ),
          ],
          child: Consumer(
            builder: (_, ref, _) =>
                MaterialApp.router(routerConfig: ref.watch(appRouterProvider)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to profile.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer)),
      );
      container.read(appRouterProvider).go(RouteNames.profile);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(signedOut, isTrue);
    });
  });
}

// Tracks whether logout was called.
class _TrackingLogoutNotifier extends LogoutNotifier {
  _TrackingLogoutNotifier({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Future<void> logout() async {
    state = const AsyncLoading();
    onLogout();
    state = const AsyncData(null);
  }
}
