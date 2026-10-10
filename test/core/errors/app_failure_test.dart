import 'package:acendra/core/errors/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFailure', () {
    test('NetworkFailure holds message', () {
      const f = NetworkFailure('timeout');
      expect(f.message, 'timeout');
    });

    test('AuthFailure holds message', () {
      const f = AuthFailure('invalid credentials');
      expect(f.message, 'invalid credentials');
    });

    test('switch exhaustiveness covers all subtypes', () {
      final failures = <AppFailure>[
        const NetworkFailure('a'),
        const AuthFailure('b'),
        const NotFoundFailure('c'),
        const PermissionFailure('d'),
        const ValidationFailure('e'),
        const ServerFailure('f'),
        const UnknownFailure('g'),
      ];
      for (final f in failures) {
        final label = switch (f) {
          NetworkFailure() => 'network',
          AuthFailure() => 'auth',
          NotFoundFailure() => 'notFound',
          PermissionFailure() => 'permission',
          ValidationFailure() => 'validation',
          ServerFailure() => 'server',
          UnknownFailure() => 'unknown',
        };
        expect(label, isNotEmpty);
      }
    });
  });
}
