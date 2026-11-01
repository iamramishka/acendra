import 'dart:async';

import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:acendra/features/authentication/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.shouldThrow, this.pending}) : super.forTesting();
  final AuthFailure? shouldThrow;
  final Completer<void>? pending;
  int signInCalls = 0;

  // ignore: avoid_late_keyword
  late String lastEmail;
  // ignore: avoid_late_keyword
  late String lastPassword;

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls++;
    lastEmail = email;
    lastPassword = password;
    if (pending != null) await pending!.future;
    if (shouldThrow != null) throw shouldThrow!;
  }
}

Widget _wrap({AuthFailure? throws, _FakeAuthRepository? repository}) {
  final fake = repository ?? _FakeAuthRepository(shouldThrow: throws);
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(fake)],
    child: MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
  );
}

void main() {
  testWidgets('email Enter moves focus to password without signing in', (
    tester,
  ) async {
    final fake = _FakeAuthRepository();
    await tester.pumpWidget(_wrap(repository: fake));
    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    final password = tester.widget<EditableText>(
      find.byType(EditableText).last,
    );
    expect(password.focusNode.hasFocus, isTrue);
    expect(fake.signInCalls, 0);
  });

  testWidgets('password Enter signs in and navigates to dashboard', (
    tester,
  ) async {
    final fake = _FakeAuthRepository();
    final router = GoRouter(
      initialLocation: RouteNames.login,
      routes: [
        GoRoute(
          path: RouteNames.login,
          builder: (_, state) => const LoginScreen(),
        ),
        GoRoute(
          path: RouteNames.dashboard,
          builder: (_, state) =>
              const Scaffold(body: Text('Dashboard reached')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fake)],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.enterText(find.byType(TextField).first, ' test@example.com ');
    await tester.enterText(find.byType(TextField).last, ' password ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(fake.signInCalls, 1);
    expect(fake.lastEmail, 'test@example.com');
    expect(fake.lastPassword, ' password ');
    expect(find.text('Dashboard reached'), findsOneWidget);
  });

  testWidgets('password Enter validates empty and invalid input', (
    tester,
  ) async {
    final fake = _FakeAuthRepository();
    await tester.pumpWidget(_wrap(repository: fake));
    await tester.showKeyboard(find.byType(TextField).last);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byType(TextField).last)
          .decoration
          ?.errorText,
      'Enter your password',
    );
    await tester.enterText(find.byType(TextField).first, 'invalid');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(fake.signInCalls, 0);
  });

  testWidgets('repeated Enter while pending signs in once and permits retry', (
    tester,
  ) async {
    final pending = Completer<void>();
    final fake = _FakeAuthRepository(
      pending: pending,
      shouldThrow: const InvalidCredentials(),
    );
    await tester.pumpWidget(_wrap(repository: fake));
    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.showKeyboard(find.byType(TextField).last);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(fake.signInCalls, 1);

    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Invalid email or password.'), findsOneWidget);
    await tester.showKeyboard(find.byType(TextField).last);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(fake.signInCalls, 2);
  });

  testWidgets('renders email and password fields', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('shows validation errors when submitting empty form', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.ensureVisible(find.text('Sign In'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
    // The password hint uses the same words; assert the validation error itself.
    expect(
      tester
          .widget<TextField>(find.byType(TextField).last)
          .decoration
          ?.errorText,
      'Enter your password',
    );
  });

  testWidgets('shows error for invalid email format', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.enterText(find.byType(TextField).first, 'notanemail');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('shows snackbar on auth failure', (tester) async {
    await tester.pumpWidget(_wrap(throws: const InvalidCredentials()));
    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid email or password.'), findsOneWidget);
  });

  testWidgets('has link to register screen', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Create an account'), findsOneWidget);
  });

  testWidgets('has forgot password link', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Forgot password?'), findsOneWidget);
  });
}
