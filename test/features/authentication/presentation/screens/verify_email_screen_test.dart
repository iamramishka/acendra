import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/screens/verify_email_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super.forTesting();

  final List<String> resent = [];

  @override
  Future<void> resendVerification({required String email}) async {
    resent.add(email);
  }
}

late _FakeAuthRepository _fake;

Widget _wrap({String? email}) {
  _fake = _FakeAuthRepository();
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_fake),
      pendingVerificationEmailProvider.overrideWith((ref) => email),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const VerifyEmailScreen()),
  );
}

void main() {
  testWidgets('renders check your inbox heading and spam hint', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Check your inbox'), findsOneWidget);
    expect(find.textContaining("Didn't receive the email?"), findsOneWidget);
  });

  testWidgets('shows a masked email, never the full address', (tester) async {
    await tester.pumpWidget(_wrap(email: 'test@example.com'));
    expect(find.text('te••@example.com'), findsOneWidget);
    expect(find.textContaining('test@example.com'), findsNothing);
  });

  testWidgets('resend starts a cooldown that disables the button', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(email: 'test@example.com'));
    await tester.ensureVisible(find.text('Resend Verification Email'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resend Verification Email'));
    await tester.pump();
    await tester.pump();

    expect(_fake.resent, ['test@example.com']);
    expect(find.text('Resend available in 30s'), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Resend available in 20s'), findsOneWidget);

    await tester.pump(const Duration(seconds: 20));
    expect(find.text('Resend Verification Email'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('offers an email field to resend after a refresh', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'jane@example.com');
    await tester.ensureVisible(find.text('Resend Verification Email'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resend Verification Email'));
    await tester.pump();
    await tester.pump();
    expect(_fake.resent, ['jane@example.com']);
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
  });

  testWidgets('refuses to resend an invalid email', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.enterText(find.byType(TextField), 'nope');
    await tester.ensureVisible(find.text('Resend Verification Email'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resend Verification Email'));
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(_fake.resent, isEmpty);
  });

  testWidgets('shows back to sign in button', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Back to Sign In'), findsOneWidget);
  });
}
