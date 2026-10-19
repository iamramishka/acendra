import 'package:acendra/app/providers/theme_mode_provider.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Auth extends AuthRepository {
  _Auth({this.fail = false}) : super.forTesting();
  final bool fail;
  int signOuts = 0;

  @override
  Future<void> signOut() async {
    signOuts++;
    if (fail) throw StateError('Synthetic sign-out failure');
  }
}

void main() {
  for (final fail in [false, true]) {
    testWidgets('sign-out handles failure=$fail', (tester) async {
      final auth = _Auth(fail: fail);
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
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
          overrides: [authRepositoryProvider.overrideWithValue(auth)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sign out'));
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(auth.signOuts, 1);
      expect(
        router.routeInformationProvider.value.uri.path,
        fail ? '/settings' : '/login',
      );
      if (fail) {
        expect(
          find.text('Could not sign out. Please try again.'),
          findsOneWidget,
        );
        expect(find.textContaining('Synthetic'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('theme control can select Light, Dark and System again', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.tap(find.text('Dark'));
    await tester.pump();
    expect(container.read(themeModeProvider), ThemeMode.dark);

    await tester.tap(find.text('Light'));
    await tester.pump();
    expect(container.read(themeModeProvider), ThemeMode.light);

    await tester.tap(find.text('System'));
    await tester.pump();
    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  testWidgets('shows change password and sign out', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );
    expect(find.text('Change password'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });
}
