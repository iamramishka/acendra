import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/screens/verify_email_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super.forTesting();

  bool resenCalled = false;

  @override
  Future<void> resendVerification({required String email}) async {
    resenCalled = true;
  }
}

Widget _wrap({String? email}) {
  final fake = _FakeAuthRepository();
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(fake),
      pendingVerificationEmailProvider.overrideWith((ref) => email),
    ],
    child: const MaterialApp(home: VerifyEmailScreen()),
  );
}

void main() {
  testWidgets('renders verify your email heading', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Verify your email'), findsOneWidget);
  });

  testWidgets('shows email address when provided', (tester) async {
    await tester.pumpWidget(_wrap(email: 'test@example.com'));
    expect(find.textContaining('test@example.com'), findsOneWidget);
  });

  testWidgets('shows resend button when email is provided', (tester) async {
    await tester.pumpWidget(_wrap(email: 'test@example.com'));
    expect(find.text('Resend email'), findsOneWidget);
  });

  testWidgets('does not show resend button when email is null', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Resend email'), findsNothing);
  });

  testWidgets('shows back to sign in button', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Back to sign in'), findsOneWidget);
  });
}
