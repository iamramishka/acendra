import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:acendra/features/authentication/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.shouldThrow}) : super.forTesting();
  final AuthFailure? shouldThrow;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (shouldThrow != null) throw shouldThrow!;
  }
}

Widget _wrap({AuthFailure? throws}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        _FakeAuthRepository(shouldThrow: throws),
      ),
    ],
    child: const MaterialApp(home: RegisterScreen()),
  );
}

void main() {
  testWidgets('renders all form fields', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsWidgets);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('shows validation errors on empty submit', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(find.text('Enter your full name'), findsOneWidget);
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter a password'), findsOneWidget);
  });

  testWidgets('shows password mismatch error', (tester) async {
    await tester.pumpWidget(_wrap());
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    await tester.enterText(find.byType(TextField).at(0), 'Jane Doe');
    await tester.enterText(find.byType(TextField).at(1), 'jane@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.enterText(find.byType(TextField).at(3), 'different');
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(fields, isNotNull);
  });

  testWidgets('shows snackbar on email already in use error', (tester) async {
    await tester.pumpWidget(_wrap(throws: const EmailAlreadyInUse()));
    await tester.enterText(find.byType(TextField).at(0), 'Jane Doe');
    await tester.enterText(find.byType(TextField).at(1), 'jane@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.enterText(find.byType(TextField).at(3), 'password123');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(
      find.text('An account with this email already exists.'),
      findsOneWidget,
    );
  });

  testWidgets('has link to login screen', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Sign in'), findsOneWidget);
  });
}
