import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/screens/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    currentSessionProvider.overrideWithValue(
      Session(
        accessToken: 'synthetic-recovery',
        tokenType: 'bearer',
        user: const User(
          id: 'student-a',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-10-22',
        ),
      ),
    ),
    authRepositoryProvider.overrideWithValue(
      _FakeAuthRepository(shouldThrow: throws),
    ),
  ],
  child: MaterialApp(theme: AppTheme.light, home: const ResetPasswordScreen()),
);

void main() {
  testWidgets('renders password fields and update button', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('New password'), findsOneWidget);
    expect(find.text('Confirm new password'), findsOneWidget);
    expect(find.text('Update Password'), findsOneWidget);
  });

  testWidgets('empty passwords cannot be submitted', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Update Password'))
          .onPressed,
      isNull,
    );
    expect(find.text('Both passwords match'), findsOneWidget);
  });

  testWidgets('shows error when password is too short', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.enterText(find.byType(TextField).first, 'abc');
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Update Password'))
          .onPressed,
      isNull,
    );
    expect(find.text('At least 6 characters'), findsOneWidget);
  });

  testWidgets('shows error when passwords do not match', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.enterText(find.byType(TextField).first, 'password123');
    await tester.enterText(find.byType(TextField).last, 'different');
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Update Password'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('shows snackbar on auth failure', (tester) async {
    await tester.pumpWidget(_wrap(throws: const WeakPassword()));
    await tester.enterText(find.byType(TextField).first, 'password123');
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.pump();
    await tester.ensureVisible(find.text('Update Password'));
    await tester.tap(find.text('Update Password'));
    await tester.pumpAndSettle();
    expect(find.textContaining('at least 6 characters'), findsOneWidget);
  });

  testWidgets('has back to sign in link', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Back to Sign In'), findsOneWidget);
  });
}
