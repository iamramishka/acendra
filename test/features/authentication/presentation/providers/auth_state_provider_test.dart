import 'dart:async';

import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('sessionRestoredProvider', () {
    test('returns false when auth stream has no value yet', () {
      final container = ProviderContainer(
        overrides: [
          authStreamProvider.overrideWith(
            (ref) => const Stream.empty(),
          ),
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
      addTearDown(container.dispose);
      addTearDown(controller.close);

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
          authStreamProvider.overrideWith(
            (ref) => const Stream.empty(),
          ),
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
          authStreamProvider.overrideWith(
            (ref) => const Stream.empty(),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(isAuthenticatedProvider), isFalse);
    });
  });
}
