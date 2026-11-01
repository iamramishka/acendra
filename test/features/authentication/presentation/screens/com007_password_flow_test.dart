import 'dart:async';

import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/screens/reset_password_screen.dart';
import 'package:acendra/features/profile/presentation/providers/profile_provider.dart';
import 'package:acendra/features/settings/presentation/screens/change_password_screen.dart';
import 'package:acendra/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _sessionState = StateProvider<Session?>((ref) => null);

Session _session(String id) => Session(
  accessToken: 'synthetic-$id',
  tokenType: 'bearer',
  user: User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-10-22',
  ),
);

class _Auth extends AuthRepository {
  _Auth() : super.forTesting();
  int updates = 0;
  int signOuts = 0;
  Future<void>? response;
  AuthFailure? failure;
  VoidCallback? onSignOut;

  @override
  Future<void> updatePassword({required String newPassword}) async {
    updates++;
    await response;
    if (failure != null) throw failure!;
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    onSignOut?.call();
  }
}

Future<({ProviderContainer container, GoRouter router, _Auth auth})> _pump(
  WidgetTester tester, {
  bool change = false,
  bool fromSettings = false,
  String? actor = 'student-a',
  _Auth? auth,
  ThemeData? theme,
}) async {
  final repository = auth ?? _Auth();
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      currentSessionProvider.overrideWith((ref) => ref.watch(_sessionState)),
      userPreferencesProvider.overrideWith(
        (ref) async => const UserPreferences(),
      ),
    ],
  );
  container.read(_sessionState.notifier).state = actor == null
      ? null
      : _session(actor);
  final router = GoRouter(
    initialLocation: fromSettings
        ? RouteNames.settings
        : change
        ? RouteNames.changePassword
        : RouteNames.resetPassword,
    routes: [
      GoRoute(
        path: RouteNames.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.changePassword,
        builder: (_, _) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.resetPassword,
        builder: (_, _) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (_, _) => const Scaffold(body: Text('Sign-in destination')),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (_, _) =>
            const Scaffold(body: Text('Request-link destination')),
      ),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: theme ?? AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (container: container, router: router, auth: repository);
}

Finder get _submitFinder => find.byWidgetPredicate(
  (widget) => widget is AppButton && widget.label == 'Update Password',
);

AppButton _submit(WidgetTester tester) =>
    tester.widget<AppButton>(_submitFinder);

Future<void> _fill(WidgetTester tester, [String password = 'abcdef']) async {
  await tester.enterText(find.byType(TextField).first, password);
  await tester.enterText(find.byType(TextField).last, password);
  await tester.pump();
}

Future<void> _tapSubmit(WidgetTester tester) async {
  await tester.ensureVisible(_submitFinder);
  await tester.tap(_submitFinder);
  await tester.pump();
}

void main() {
  testWidgets('checklist follows six-character policy and matching input', (
    tester,
  ) async {
    await _pump(tester);
    expect(_submit(tester).onPressed, isNull);
    await _fill(tester, 'abcde');
    expect(_submit(tester).onPressed, isNull);
    await _fill(tester);
    expect(_submit(tester).onPressed, isNotNull);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).last, 'abcdeg');
    await tester.pump();
    expect(_submit(tester).onPressed, isNull);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets(
    'visibility toggles operate independently without changing input',
    (tester) async {
      await _pump(tester);
      await _fill(tester);
      await tester.ensureVisible(find.byTooltip('Show password').first);
      await tester.tap(find.byTooltip('Show password').first);
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).obscureText,
        isFalse,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isTrue,
      );
      await tester.ensureVisible(find.byTooltip('Show password'));
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(find.byTooltip('Hide password'), findsNWidgets(2));
      await tester.ensureVisible(find.byTooltip('Hide password').first);
      await tester.tap(find.byTooltip('Hide password').first);
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).obscureText,
        isTrue,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isFalse,
      );
      expect(_submit(tester).onPressed, isNotNull);
    },
  );

  testWidgets('Settings change succeeds and preserves the signed-in session', (
    tester,
  ) async {
    final app = await _pump(tester, fromSettings: true);
    await tester.ensureVisible(find.text('Change password'));
    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();
    expect(app.router.state.uri.path, RouteNames.changePassword);
    expect(find.text('Change your password'), findsOneWidget);
    expect(find.text('Back to Sign In'), findsNothing);
    await _fill(tester);
    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    expect(app.auth.updates, 1);
    expect(app.auth.signOuts, 0);
    expect(app.container.read(currentSessionProvider)?.user.id, 'student-a');
    expect(
      app.router.routeInformationProvider.value.uri.path,
      RouteNames.settings,
    );
    expect(find.text('Password updated.'), findsOneWidget);
  });

  testWidgets('email recovery signs out and returns to sign in', (
    tester,
  ) async {
    final app = await _pump(tester);
    app.auth.onSignOut = () =>
        app.container.read(_sessionState.notifier).state = null;
    await _fill(tester);
    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    expect(app.auth.updates, 1);
    expect(app.auth.signOuts, 1);
    expect(app.container.read(currentSessionProvider), isNull);
    expect(
      app.router.routeInformationProvider.value.uri.path,
      RouteNames.login,
    );
  });

  testWidgets('pending update disables duplicate submission and allows retry', (
    tester,
  ) async {
    final gate = Completer<void>();
    final auth = _Auth()..response = gate.future;
    await _pump(tester, change: true, auth: auth);
    await _fill(tester);
    await _tapSubmit(tester);
    expect(_submit(tester).onPressed, isNull);
    expect(_submit(tester).isLoading, isTrue);
    await _tapSubmit(tester);
    expect(auth.updates, 1);
    auth.failure = const NetworkError();
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Password updated.'), findsNothing);
    expect(_submit(tester).onPressed, isNotNull);
    auth.failure = null;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    expect(auth.updates, 2);
    expect(auth.signOuts, 0);
  });

  testWidgets('expired recovery session cannot dispatch a password update', (
    tester,
  ) async {
    final app = await _pump(tester, actor: null);
    await _fill(tester);
    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    expect(app.auth.updates, 0);
    expect(app.auth.signOuts, 0);
    expect(find.text('Password updated.'), findsNothing);
    expect(find.textContaining('session has expired'), findsOneWidget);
    await tester.ensureVisible(find.text('Request a new reset link'));
    await tester.tap(find.text('Request a new reset link'));
    await tester.pumpAndSettle();
    expect(app.router.state.uri.path, RouteNames.forgotPassword);
    expect(find.text('Request-link destination'), findsOneWidget);
    expect(app.auth.updates, 0);
  });

  testWidgets(
    'account change clears both inputs and hides revealed passwords',
    (tester) async {
      final app = await _pump(tester, change: true);
      await _fill(tester);
      await tester.ensureVisible(find.byTooltip('Show password').first);
      await tester.tap(find.byTooltip('Show password').first);
      await tester.pump();
      app.container.read(_sessionState.notifier).state = _session('student-b');
      await tester.pump();
      for (final field in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(field.controller!.text, isEmpty);
        expect(field.obscureText, isTrue);
      }
      expect(_submit(tester).onPressed, isNull);
      expect(app.auth.updates, 0);
    },
  );

  for (final fail in [false, true]) {
    testWidgets(
      'late ${fail ? 'error' : 'success'} is ignored after A-B-A session changes',
      (tester) async {
        final gate = Completer<void>();
        final auth = _Auth()..response = gate.future;
        final app = await _pump(tester, auth: auth);
        await _fill(tester);
        await _tapSubmit(tester);
        app.container.read(_sessionState.notifier).state = _session(
          'student-b',
        );
        await tester.pump();
        app.container.read(_sessionState.notifier).state = _session(
          'student-a',
        );
        await tester.pump();
        if (fail) auth.failure = const WeakPassword();
        gate.complete();
        await tester.pumpAndSettle();
        expect(
          app.router.routeInformationProvider.value.uri.path,
          RouteNames.resetPassword,
        );
        expect(auth.signOuts, 0);
        expect(find.byType(SnackBar), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('password controls fit width=$width dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _pump(tester, theme: dark ? AppTheme.dark : AppTheme.light);
        await _fill(tester);
        await tester.ensureVisible(find.text('Update Password'));
        expect(_submit(tester).onPressed, isNotNull);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
