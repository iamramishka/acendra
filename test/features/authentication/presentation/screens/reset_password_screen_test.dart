import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:acendra/features/authentication/presentation/screens/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.shouldThrow}) : super.forTesting();
  final AuthFailure? shouldThrow;

  @override
  Future<void> updatePassword({required String newPassword}) async {
    if (shouldThrow != null) throw shouldThrow!;
  }
}

Widget _wrap({AuthFailure? throws}) => ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWithValue(
      _FakeAuthRepository(shouldThrow: throws),
    ),
  ],
  child: const MaterialApp(home: ResetPasswordScreen()),
);

void main() {
  testWidgets('renders password fields and update button', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('New password'), findsOneWidget);
    expect(find.text('Confirm new password'), findsOneWidget);
    expect(find.text('Update password'), findsOneWidget);
  });

  testWidgets('shows errors when submitting empty fields', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('Update password'));
    await tester.pump();
    expect(find.text('Enter a new password'), findsOneWidget);
    expect(find.text('Confirm your password'), findsOneWidget);
  });

  testWidgets('shows error when password is too short', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.enterText(find.byType(TextField).first, 'abcd');
    await tester.tap(find.text('Update password'));
    await tester.pump();
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });

  testWidgets('shows error when passwords do not match', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.enterText(find.byType(TextField).first, 'password123');
    await tester.enterText(find.byType(TextField).last, 'different');
    await tester.tap(find.text('Update password'));
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('shows snackbar on auth failure', (tester) async {
    await tester.pumpWidget(_wrap(throws: const WeakPassword()));
    await tester.enterText(find.byType(TextField).first, 'password123');
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();
    expect(find.textContaining('at least 6 characters'), findsOneWidget);
  });

  testWidgets('has back to sign in link', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Back to sign in'), findsOneWidget);
  });
}
