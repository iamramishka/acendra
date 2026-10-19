import 'dart:typed_data';

class MediaFile {
  const MediaFile({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
  String get extension => name.split('.').last.toLowerCase();
  String get mime => switch (extension) {
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'pdf' => 'application/pdf',
    _ => throw const FormatException('Choose a JPG, PNG or PDF file.'),
  };
}

String? mediaFileError(String name, int size, {required bool pdf}) {
  final extension = name.split('.').last.toLowerCase();
  if (!(pdf ? ['pdf'] : ['jpg', 'jpeg', 'png']).contains(extension)) {
    return pdf ? 'Choose a PDF file.' : 'Choose a JPG or PNG image.';
  }
  final limit = (pdf ? 50 : 5) * 1024 * 1024;
  if (size <= 0) return 'The file is empty.';
  if (size > limit) {
    return pdf ? 'Maximum file size is 50 MB.' : 'Maximum file size is 5 MB.';
  }
  return null;
}
