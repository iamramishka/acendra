import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:acendra/features/authentication/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.shouldThrow}) : super.forTesting();
  final AuthFailure? shouldThrow;

  // ignore: avoid_late_keyword
  late String lastEmail;
  // ignore: avoid_late_keyword
  late String lastPassword;

  @override
  Future<void> signIn({required String email, required String password}) async {
    lastEmail = email;
    lastPassword = password;
    if (shouldThrow != null) throw shouldThrow!;
  }
}

Widget _wrap({AuthFailure? throws}) {
  final fake = _FakeAuthRepository(shouldThrow: throws);
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(fake),
    ],
    child: const MaterialApp(
      home: LoginScreen(),
    ),
  );
}

void main() {
  testWidgets('renders email and password fields', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('shows validation errors when submitting empty form', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('shows error for invalid email format', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.enterText(find.byType(TextField).first, 'notanemail');
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('shows snackbar on auth failure', (tester) async {
    await tester.pumpWidget(_wrap(throws: const InvalidCredentials()));
    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid email or password.'), findsOneWidget);
  });

  testWidgets('has link to register screen', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Sign up'), findsOneWidget);
  });

  testWidgets('has forgot password link', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Forgot password?'), findsOneWidget);
  });
}
