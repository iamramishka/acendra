@TestOn('browser')
library;

import 'package:acendra/app/router/app_router.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  ProviderContainer makeContainer({
    bool sessionRestored = true,
    bool isAuthenticated = false,
  }) {
    return ProviderContainer(
      overrides: [
        sessionRestoredProvider.overrideWithValue(sessionRestored),
        isAuthenticatedProvider.overrideWithValue(isAuthenticated),
      ],
    );
  }

  test('router routes contain ShellRoute wrappers', () {
    final container = makeContainer();
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    final hasShellRoute = router.configuration.routes
        .whereType<ShellRoute>()
        .isNotEmpty;
    expect(hasShellRoute, isTrue);
  });

  test('at least 4 shell groups exist (public, auth, student, admin)', () {
    final container = makeContainer();
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    final shellCount = router.configuration.routes
        .whereType<ShellRoute>()
        .length;
    expect(shellCount, greaterThanOrEqualTo(4));
  });

  test('router is created without throwing', () {
    final container = makeContainer(
      sessionRestored: true,
      isAuthenticated: false,
    );
    addTearDown(container.dispose);
    expect(() => container.read(appRouterProvider), returnsNormally);
  });
}
