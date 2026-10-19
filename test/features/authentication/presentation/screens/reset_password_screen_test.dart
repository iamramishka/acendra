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

  testWidgets('renders live checklist items', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('At least 5 characters'), findsOneWidget);
    expect(find.text('Passwords match'), findsOneWidget);
  });

  testWidgets('button is disabled until both rules pass', (tester) async {
    await tester.pumpWidget(_wrap());
    // Button disabled with empty fields
    final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(btn.onPressed, isNull);
  });

  testWidgets('button enables when length and match both pass', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.enterText(find.byType(TextField).first, 'abcde');
    await tester.enterText(find.byType(TextField).last, 'abcde');
    await tester.pump();
    final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('button stays disabled when passwords do not match', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.enterText(find.byType(TextField).first, 'abcde');
    await tester.enterText(find.byType(TextField).last, 'xxxxx');
    await tester.pump();
    final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(btn.onPressed, isNull);
  });

  testWidgets('button stays disabled when password is too short', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.enterText(find.byType(TextField).first, 'ab');
    await tester.enterText(find.byType(TextField).last, 'ab');
    await tester.pump();
    final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(btn.onPressed, isNull);
  });

  testWidgets('shows snackbar on auth failure', (tester) async {
    await tester.pumpWidget(_wrap(throws: const WeakPassword()));
    await tester.enterText(find.byType(TextField).first, 'abcde');
    await tester.enterText(find.byType(TextField).last, 'abcde');
    await tester.pump();
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();
    expect(find.textContaining('at least 5 characters'), findsOneWidget);
  });

  testWidgets('has back to sign in link', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Back to sign in'), findsOneWidget);
  });
}
