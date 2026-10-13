import 'dart:typed_data';

const maxReceiptBytes = 5 * 1024 * 1024;

class ReceiptFile {
  const ReceiptFile({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}

typedef ReceiptFilePicker = Future<ReceiptFile?> Function();

/// Client validation is a UX guard; the backend must inspect receipt contents.
String? receiptFileError(String name, int size) {
  if (!['jpg', 'jpeg', 'pdf'].contains(name.split('.').last.toLowerCase())) {
    return 'Only JPG and PDF files are accepted.';
  }
  if (size == 0) return 'The selected file is empty.';
  if (size > maxReceiptBytes) return 'File is too large. Maximum size is 5 MB.';
  return null;
}
