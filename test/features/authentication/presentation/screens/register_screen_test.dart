import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:acendra/features/authentication/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.shouldThrow}) : super.forTesting();
  final AuthFailure? shouldThrow;
  int signUpCalls = 0;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    signUpCalls++;
    if (shouldThrow != null) throw shouldThrow!;
  }
}

late _FakeAuthRepository _fake;

Widget _wrap({AuthFailure? throws}) {
  _fake = _FakeAuthRepository(shouldThrow: throws);
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(_fake)],
    child: MaterialApp(theme: AppTheme.light, home: const RegisterScreen()),
  );
}

Future<void> _fill(
  WidgetTester tester, {
  String password = 'password123',
  String confirm = 'password123',
}) async {
  await tester.enterText(find.byType(TextField).at(0), 'Jane Doe');
  await tester.enterText(find.byType(TextField).at(1), 'jane@example.com');
  await tester.enterText(find.byType(TextField).at(2), password);
  await tester.enterText(find.byType(TextField).at(3), confirm);
}

Future<void> _tapCreate(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Create Account'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Create Account'));
  await tester.pumpAndSettle();
}

Future<void> _acceptTerms(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(Checkbox));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(Checkbox));
  await tester.pump();
}

void main() {
  testWidgets('renders hero, fields, consent and switch card', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Create your\naccount'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Already have an account? '), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
  });

  testWidgets('shows validation errors on empty submit', (tester) async {
    await tester.pumpWidget(_wrap());
    await _tapCreate(tester);
    expect(find.text('Enter your full name'), findsOneWidget);
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter a password'), findsOneWidget);
    expect(find.text('Accept the terms to create an account.'), findsOneWidget);
    expect(_fake.signUpCalls, 0);
  });

  testWidgets('rejects passwords shorter than 6 characters', (tester) async {
    await tester.pumpWidget(_wrap());
    await _fill(tester, password: 'abcde', confirm: 'abcde');
    await _acceptTerms(tester);
    await _tapCreate(tester);
    expect(find.text('Use at least 6 characters'), findsOneWidget);
    expect(_fake.signUpCalls, 0);
  });

  testWidgets('blocks sign-up until the terms are accepted', (tester) async {
    await tester.pumpWidget(_wrap());
    await _fill(tester);
    await _tapCreate(tester);
    expect(find.text('Accept the terms to create an account.'), findsOneWidget);
    expect(_fake.signUpCalls, 0);
  });

  testWidgets('shows password mismatch error', (tester) async {
    await tester.pumpWidget(_wrap());
    await _fill(tester, confirm: 'different1');
    await _acceptTerms(tester);
    await _tapCreate(tester);
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(_fake.signUpCalls, 0);
  });

  testWidgets('shows snackbar on email already in use error', (tester) async {
    await tester.pumpWidget(_wrap(throws: const EmailAlreadyInUse()));
    await _fill(tester);
    await _acceptTerms(tester);
    await _tapCreate(tester);
    expect(_fake.signUpCalls, 1);
    expect(
      find.text('An account with this email already exists.'),
      findsOneWidget,
    );
  });
}
