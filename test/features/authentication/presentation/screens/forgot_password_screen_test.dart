import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:acendra/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
        authRepositoryProvider
            .overrideWithValue(_FakeAuthRepository(shouldThrow: throws)),
      ],
      child: const MaterialApp(home: ForgotPasswordScreen()),
    );

void main() {
  testWidgets('renders email field and send button', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Send reset link'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('shows error when submitting empty field', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('Send reset link'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
  });

  testWidgets('shows error for invalid email format', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.enterText(find.byType(TextField), 'notanemail');
    await tester.tap(find.text('Send reset link'));
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('shows success view after sending reset email', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(find.text('Check your inbox'), findsOneWidget);
    expect(find.textContaining('user@example.com'), findsOneWidget);
  });

  testWidgets('shows snackbar on auth failure', (tester) async {
    await tester.pumpWidget(_wrap(throws: const NetworkError()));
    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(find.textContaining('internet connection'), findsOneWidget);
  });

  testWidgets('has back to sign in link', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Back to sign in'), findsOneWidget);
  });
}
