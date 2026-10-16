// CSA-177 — Registration journey integration tests.
// Full end-to-end widget tests for the registration flow against fake
// repositories (no real Supabase).
//
// These tests import app_router which depends on dart:js_interop (via
// pdf_progress_local.dart → package:web). Run on Chrome only:
//   flutter test --platform chrome test/features/authentication/integration/registration_journey_test.dart
@TestOn('chrome')
library;

import 'package:acendra/app/router/app_router.dart';
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

/// Fails on signUp; succeeds on everything else.
class _SignUpFailRepository extends AuthRepository {
  _SignUpFailRepository(this._failure) : super.forTesting();
  final AuthFailure _failure;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    throw _failure;
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> resendVerification({required String email}) async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> signOut() async {}
}

/// Succeeds on signUp; fails on resendVerification.
class _ResendFailRepository extends AuthRepository {
  _ResendFailRepository(this._failure) : super.forTesting();
  final AuthFailure _failure;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {}

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> resendVerification({required String email}) async {
    throw _failure;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> signOut() async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _app({required AuthRepository repo}) => ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWithValue(repo),
    authStreamProvider.overrideWith((ref) => const Stream.empty()),
    sessionRestoredProvider.overrideWithValue(true),
    isAuthenticatedProvider.overrideWithValue(false),
    logoutProvider.overrideWith(LogoutNotifier.new),
  ],
  child: Consumer(
    builder: (_, ref, _) =>
        MaterialApp.router(routerConfig: ref.watch(appRouterProvider)),
  ),
);

/// Navigates from the login screen to the register screen.
Future<void> _goToRegister(WidgetTester tester) async {
  await tester.tap(find.text('Sign up'));
  await tester.pumpAndSettle();
}

/// Fills all four registration fields.
/// Fields are ordered: Full name (0), Email (1), Password (2), Confirm (3).
Future<void> _fillRegisterForm(
  WidgetTester tester, {
  String name = 'Jane Doe',
  String email = 'jane@example.com',
  String password = 'password123',
  String? confirmPassword,
}) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), name);
  await tester.enterText(fields.at(1), email);
  await tester.enterText(fields.at(2), password);
  await tester.enterText(fields.at(3), confirmPassword ?? password);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Registration — happy path', () {
    testWidgets(
      'filling form and submitting navigates to verify-email screen',
      (tester) async {
        await tester.pumpWidget(_app(repo: _SuccessAuthRepository()));
        await tester.pumpAndSettle();
        await _goToRegister(tester);

        expect(find.text('Create your account'), findsOneWidget);

        await _fillRegisterForm(tester);
        await tester.tap(find.text('Create account'));
        await tester.pumpAndSettle();

        expect(find.text('Verify your email'), findsOneWidget);
        expect(find.text('Create your account'), findsNothing);
      },
    );

    testWidgets('verify-email screen shows the registered email address', (
      tester,
    ) async {
      await tester.pumpWidget(_app(repo: _SuccessAuthRepository()));
      await tester.pumpAndSettle();
      await _goToRegister(tester);

      await _fillRegisterForm(tester, email: 'unique@example.com');
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.textContaining('unique@example.com'), findsOneWidget);
    });

    testWidgets('resend verification shows success snackbar', (tester) async {
      await tester.pumpWidget(_app(repo: _SuccessAuthRepository()));
      await tester.pumpAndSettle();
      await _goToRegister(tester);

      await _fillRegisterForm(tester);
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Resend email'), findsOneWidget);
      await tester.tap(find.text('Resend email'));
      await tester.pumpAndSettle();

      expect(find.text('Verification email sent.'), findsOneWidget);
    });
  });

  group('Registration — validation errors', () {
    testWidgets('empty form shows full-name error', (tester) async {
      await tester.pumpWidget(_app(repo: _SuccessAuthRepository()));
      await tester.pumpAndSettle();
      await _goToRegister(tester);

      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(find.text('Enter your full name'), findsOneWidget);
      expect(find.text('Verify your email'), findsNothing);
    });

    testWidgets('empty email shows email error', (tester) async {
      await tester.pumpWidget(_app(repo: _SuccessAuthRepository()));
      await tester.pumpAndSettle();
      await _goToRegister(tester);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Jane Doe');
      // Leave email empty.
      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Verify your email'), findsNothing);
    });

    testWidgets('invalid email format shows validation error', (tester) async {
      await tester.pumpWidget(_app(repo: _SuccessAuthRepository()));
      await tester.pumpAndSettle();
      await _goToRegister(tester);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Jane Doe');
      await tester.enterText(fields.at(1), 'not-an-email');
      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Verify your email'), findsNothing);
    });

    testWidgets('password shorter than 6 characters shows error', (
      tester,
    ) async {
      await tester.pumpWidget(_app(repo: _SuccessAuthRepository()));
      await tester.pumpAndSettle();
      await _goToRegister(tester);

      await _fillRegisterForm(tester, password: 'abc', confirmPassword: 'abc');
      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
      expect(find.text('Verify your email'), findsNothing);
    });

    testWidgets('mismatched passwords shows confirm-password error', (
      tester,
    ) async {
      await tester.pumpWidget(_app(repo: _SuccessAuthRepository()));
      await tester.pumpAndSettle();
      await _goToRegister(tester);

      await _fillRegisterForm(
        tester,
        password: 'password123',
        confirmPassword: 'different456',
      );
      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(find.text('Verify your email'), findsNothing);
    });
  });

  group('Registration — server errors', () {
    testWidgets(
      'unexpected server error shows error snackbar and stays on register screen',
      (tester) async {
        await tester.pumpWidget(
          _app(
            repo: _SignUpFailRepository(
              const UnexpectedAuthError('Internal server error.'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _goToRegister(tester);

        await _fillRegisterForm(tester);
        await tester.tap(find.text('Create account'));
        await tester.pumpAndSettle();

        expect(find.text('Internal server error.'), findsOneWidget);
        expect(find.text('Create your account'), findsOneWidget);
        expect(find.text('Verify your email'), findsNothing);
      },
    );

    testWidgets(
      'network error shows error snackbar and stays on register screen',
      (tester) async {
        await tester.pumpWidget(
          _app(repo: _SignUpFailRepository(const NetworkError())),
        );
        await tester.pumpAndSettle();
        await _goToRegister(tester);

        await _fillRegisterForm(tester);
        await tester.tap(find.text('Create account'));
        await tester.pumpAndSettle();

        expect(find.text(const NetworkError().message), findsOneWidget);
        expect(find.text('Verify your email'), findsNothing);
      },
    );
  });

  group('Registration — email already in use', () {
    testWidgets(
      'email-already-in-use error shows error snackbar and stays on register screen',
      (tester) async {
        await tester.pumpWidget(
          _app(repo: _SignUpFailRepository(const EmailAlreadyInUse())),
        );
        await tester.pumpAndSettle();
        await _goToRegister(tester);

        await _fillRegisterForm(tester);
        await tester.tap(find.text('Create account'));
        await tester.pumpAndSettle();

        expect(find.text(const EmailAlreadyInUse().message), findsOneWidget);
        expect(find.text('Create your account'), findsOneWidget);
        expect(find.text('Verify your email'), findsNothing);
      },
    );
  });

  group('Verify-email screen', () {
    testWidgets('resend failure shows error snackbar', (tester) async {
      await tester.pumpWidget(
        _app(repo: _ResendFailRepository(const NetworkError())),
      );
      await tester.pumpAndSettle();
      await _goToRegister(tester);

      await _fillRegisterForm(tester);
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Resend email'), findsOneWidget);
      await tester.tap(find.text('Resend email'));
      await tester.pumpAndSettle();

      expect(find.text(const NetworkError().message), findsOneWidget);
      expect(find.text('Verify your email'), findsOneWidget);
    });

    testWidgets('tapping Back to sign in navigates to login screen', (
      tester,
    ) async {
      await tester.pumpWidget(_app(repo: _SuccessAuthRepository()));
      await tester.pumpAndSettle();
      await _goToRegister(tester);

      await _fillRegisterForm(tester);
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Verify your email'), findsOneWidget);

      await tester.tap(find.text('Back to sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsWidgets);
      expect(find.text('Verify your email'), findsNothing);
    });
  });
}
