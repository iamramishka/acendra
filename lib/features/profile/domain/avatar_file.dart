import 'dart:typed_data';

/// Maximum accepted avatar size (matches the `avatars` bucket limit).
const int kAvatarMaxBytes = 5 * 1024 * 1024;

const _contentTypes = <String, String>{
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
};

/// Browser `accept` value for the avatar picker.
const String kAvatarAccept = '.jpg,.jpeg,.png,.webp';

/// Returns a user-facing error, or null when [name]/[size] is acceptable.
String? avatarFileError(String name, int size) {
  if (avatarContentType(name) == null) {
    return 'Choose a JPG, PNG or WebP image.';
  }
  if (size <= 0) return 'That image is empty.';
  if (size > kAvatarMaxBytes) return 'Image must be 5 MB or smaller.';
  return null;
}

/// Content type for an allowed image extension, or null if unsupported.
String? avatarContentType(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return null;
  return _contentTypes[name.substring(dot + 1).toLowerCase()];
}

class AvatarFile {
  const AvatarFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  String? get contentType => avatarContentType(name);
}
