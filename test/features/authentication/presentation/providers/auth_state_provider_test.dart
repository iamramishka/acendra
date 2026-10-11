import 'dart:async';

import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('session providers follow sign-in and sign-out events', () async {
    final controller = StreamController<AuthState>.broadcast();
    final container = ProviderContainer(
      overrides: [authStreamProvider.overrideWith((ref) => controller.stream)],
    );
    addTearDown(() async {
      container.dispose();
      await controller.close();
    });
    container.listen(authStreamProvider, (_, _) {});

    final session = Session(
      accessToken: 'synthetic-access-token',
      tokenType: 'bearer',
      user: const User(
        id: 'synthetic-user',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-10-11T00:00:00Z',
      ),
    );
    expect(container.read(isAuthenticatedProvider), isFalse);
    controller.add(AuthState(AuthChangeEvent.signedIn, session));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(currentSessionProvider), same(session));
    expect(container.read(isAuthenticatedProvider), isTrue);
    expect(container.read(sessionRestoredProvider), isTrue);

    controller.add(const AuthState(AuthChangeEvent.signedOut, null));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(currentSessionProvider), isNull);
    expect(container.read(isAuthenticatedProvider), isFalse);
  });

  test('auth stream failure does not grant a session', () {
    final container = ProviderContainer(
      overrides: [
        authStreamProvider.overrideWithValue(
          AsyncError<AuthState>(
            StateError('synthetic failure'),
            StackTrace.empty,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(currentSessionProvider), isNull);
    expect(container.read(isAuthenticatedProvider), isFalse);
    expect(container.read(sessionRestoredProvider), isFalse);
  });

  test('pending verification email retains explicit state updates', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(pendingVerificationEmailProvider), isNull);
    container.read(pendingVerificationEmailProvider.notifier).state =
        'student@example.test';
    expect(
      container.read(pendingVerificationEmailProvider),
      'student@example.test',
    );
    container.read(pendingVerificationEmailProvider.notifier).state = null;
    expect(container.read(pendingVerificationEmailProvider), isNull);
  });

  group('sessionRestoredProvider', () {
    test('returns false when auth stream has no value yet', () {
      final container = ProviderContainer(
        overrides: [
          authStreamProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(sessionRestoredProvider), isFalse);
    });

    test('returns true once auth stream emits a value', () async {
      final controller = StreamController<AuthState>.broadcast();
      final container = ProviderContainer(
        overrides: [
          authStreamProvider.overrideWith((ref) => controller.stream),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await controller.close();
      });
      container.listen(authStreamProvider, (_, _) {});

      expect(container.read(sessionRestoredProvider), isFalse);

      controller.add(const AuthState(AuthChangeEvent.signedOut, null));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(sessionRestoredProvider), isTrue);
    });
  });

  group('currentSessionProvider', () {
    test('returns null when auth stream has no session', () {
      final container = ProviderContainer(
        overrides: [
          authStreamProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(currentSessionProvider), isNull);
    });
  });

  group('isAuthenticatedProvider', () {
    test('returns false when stream has no value', () {
      final container = ProviderContainer(
        overrides: [
          authStreamProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(isAuthenticatedProvider), isFalse);
    });
  });
}
