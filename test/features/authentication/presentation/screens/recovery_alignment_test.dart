import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/screens/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Auth extends AuthRepository {
  _Auth() : super.forTesting();
  int updates = 0;
  int signOuts = 0;

  @override
  Future<void> updatePassword({required String newPassword}) async {
    updates++;
  }

  @override
  Future<void> signOut() async {
    signOuts++;
  }
}

void main() {
  for (final changePassword in [false, true]) {
    testWidgets('password success preserves signed-in mode=$changePassword', (
      tester,
    ) async {
      final auth = _Auth();
      final session = Session(
        accessToken: 'synthetic',
        tokenType: 'bearer',
        user: const User(
          id: 'student-a',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-10-18',
        ),
      );
      final router = GoRouter(
        initialLocation: '/reset-password',
        routes: [
          GoRoute(
            path: '/reset-password',
            builder: (_, _) =>
                ResetPasswordScreen(changePassword: changePassword),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, _) =>
                const Scaffold(body: Text('Settings destination')),
          ),
          GoRoute(
            path: '/login',
            builder: (_, _) =>
                const Scaffold(body: Text('Sign-in destination')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            currentSessionProvider.overrideWithValue(session),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'abcdef');
      await tester.enterText(find.byType(TextField).at(1), 'abcdef');
      await tester.pump();
      await tester.ensureVisible(find.text('Update Password'));
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(auth.updates, 1);
      expect(auth.signOuts, changePassword ? 0 : 1);
      expect(
        router.routeInformationProvider.value.uri.path,
        changePassword ? '/settings' : '/login',
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('reset cannot submit short or mismatched passwords', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ResetPasswordScreen(),
        ),
      ),
    );
    AppButton submit() => tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Update Password'),
    );
    expect(submit().onPressed, isNull);
    await tester.enterText(find.byType(TextField).at(0), 'abcde');
    await tester.enterText(find.byType(TextField).at(1), 'abcde');
    await tester.pump();
    expect(submit().onPressed, isNull);
    await tester.enterText(find.byType(TextField).at(0), 'Learning123');
    await tester.enterText(find.byType(TextField).at(1), 'Learning124');
    await tester.pump();
    expect(submit().onPressed, isNull);
    await tester.enterText(find.byType(TextField).at(1), 'Learning123');
    await tester.pump();
    expect(submit().onPressed, isNotNull);
    expect(find.byTooltip('Show password'), findsNWidgets(2));
  });
}
