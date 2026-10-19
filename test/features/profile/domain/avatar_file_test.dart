import 'package:acendra/features/profile/domain/avatar_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts jpg, jpeg, png, webp case-insensitively', () {
    for (final n in ['a.jpg', 'a.JPEG', 'a.png', 'a.WebP']) {
      expect(avatarFileError(n, 100), isNull, reason: n);
      expect(avatarContentType(n), isNotNull);
    }
    expect(avatarContentType('a.png'), 'image/png');
    expect(avatarContentType('a.jpg'), 'image/jpeg');
  });

  test('rejects non-image and extensionless files', () {
    for (final n in ['a.pdf', 'a.gif', 'a.svg', 'avatar', 'a.']) {
      expect(avatarFileError(n, 100), isNotNull, reason: n);
    }
  });

  test('enforces 5 MB limit and non-empty', () {
    expect(avatarFileError('a.png', kAvatarMaxBytes), isNull);
    expect(avatarFileError('a.png', kAvatarMaxBytes + 1), isNotNull);
    expect(avatarFileError('a.png', 0), isNotNull);
  });
}
