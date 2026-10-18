import 'package:acendra/features/authentication/domain/auth_input_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validatePassword', () {
    test('rejects empty', () {
      expect(validatePassword(''), 'Enter a password');
    });

    test('rejects fewer than 5 characters', () {
      expect(validatePassword('abcd'), 'Use at least 5 characters');
    });

    test('accepts 5 characters of any kind', () {
      expect(validatePassword('abcde'), isNull);
      expect(validatePassword('12345'), isNull);
      expect(validatePassword('     '), isNull);
    });
  });

  group('isValidEmail', () {
    test('accepts a normal address', () {
      expect(isValidEmail('jane@example.com'), isTrue);
    });

    test('rejects missing domain suffix and spaces', () {
      expect(isValidEmail('jane@example'), isFalse);
      expect(isValidEmail('jane doe@example.com'), isFalse);
      expect(isValidEmail('@example.com'), isFalse);
      expect(isValidEmail('a@b.c'), isFalse);
    });
  });

  group('maskEmail', () {
    test('keeps two characters of the local part', () {
      expect(maskEmail('demo@example.com'), 'de••@example.com');
    });

    test('keeps one character for very short local parts', () {
      expect(maskEmail('ab@example.com'), 'a•@example.com');
    });

    test('returns the input when it is not an email', () {
      expect(maskEmail('nope'), 'nope');
    });
  });
}
