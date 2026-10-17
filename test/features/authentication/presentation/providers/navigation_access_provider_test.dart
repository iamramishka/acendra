import 'dart:async';

import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/providers/navigation_access_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Session _session(String id) => Session(
  accessToken: 'synthetic-token',
  tokenType: 'bearer',
  user: User(
    id: id,
    appMetadata: const {'role': 'super_admin'},
    userMetadata: const {'role': 'super_admin'},
    aud: 'authenticated',
    createdAt: '2026-10-17T00:00:00Z',
  ),
);

void main() {
  for (final role in [
    'student',
    'unknown',
    'content_manager',
    'finance_admin',
    'super_admin',
  ]) {
    test(
      'navigation for $role uses current database roles, not metadata',
      () async {
        final container = ProviderContainer(
          overrides: [
            currentSessionProvider.overrideWithValue(_session('user-one')),
            navigationRolesLoaderProvider.overrideWithValue((userId) async {
              expect(userId, 'user-one');
              return {role};
            }),
          ],
        );
        addTearDown(container.dispose);
        expect(
          await container.read(navigationAccessProvider.future),
          ['content_manager', 'finance_admin', 'super_admin'].contains(role),
        );
      },
    );
  }

  test('signed out never queries roles', () async {
    final container = ProviderContainer(
      overrides: [
        currentSessionProvider.overrideWithValue(null),
        navigationRolesLoaderProvider.overrideWithValue(
          (_) => throw StateError('must not query'),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(await container.read(navigationAccessProvider.future), isFalse);
  });

  test('role lookup errors never produce admin navigation', () async {
    final container = ProviderContainer(
      overrides: [
        currentSessionProvider.overrideWithValue(_session('user-one')),
        navigationRolesLoaderProvider.overrideWithValue(
          (_) async => throw StateError('offline'),
        ),
      ],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(navigationAccessProvider.future),
      throwsStateError,
    );
    expect(
      container.read(navigationAccessProvider).asData?.value ?? false,
      isFalse,
    );
  });

  test('sign out clears previously loaded admin access', () async {
    final controller = StreamController<AuthState>();
    final container = ProviderContainer(
      overrides: [
        authStreamProvider.overrideWith((_) => controller.stream),
        navigationRolesLoaderProvider.overrideWithValue(
          (_) async => {'super_admin'},
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await controller.close();
    });
    container.listen(navigationAccessProvider, (_, _) {});
    controller.add(AuthState(AuthChangeEvent.signedIn, _session('user-one')));
    await Future<void>.delayed(Duration.zero);
    expect(await container.read(navigationAccessProvider.future), isTrue);
    controller.add(const AuthState(AuthChangeEvent.signedOut, null));
    await Future<void>.delayed(Duration.zero);
    expect(await container.read(navigationAccessProvider.future), isFalse);
  });
}
