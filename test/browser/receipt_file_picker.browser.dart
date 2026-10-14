@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:acendra/features/checkout/presentation/services/receipt_file_picker_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

web.HTMLInputElement get input =>
    web.document.querySelector('input[type=file]')! as web.HTMLInputElement;

void select(String name, Uint8List bytes) {
  final transfer = web.DataTransfer();
  transfer.items.add(web.File([bytes.toJS].toJS, name));
  input.files = transfer.files;
  input.dispatchEvent(web.Event('change'));
}

void main() {
  test('browser picker reads exact bytes and removes the input', () async {
    final pending = pickReceiptFile();
    expect(input.accept, '.jpg,.jpeg,.pdf');
    select('receipt.jpg', Uint8List.fromList([255, 216, 255, 1]));
    final file = await pending;
    expect(file!.name, 'receipt.jpg');
    expect(file.bytes, [255, 216, 255, 1]);
    expect(web.document.querySelector('input[type=file]'), isNull);
  });
  test('browser cancel returns null and removes the input', () async {
    final pending = pickReceiptFile();
    input.dispatchEvent(web.Event('cancel'));
    expect(await pending, isNull);
    expect(web.document.querySelector('input[type=file]'), isNull);
  });
  test('browser invalid file fails and removes the input', () async {
    final pending = pickReceiptFile();
    final assertion = expectLater(pending, throwsFormatException);
    select('receipt.exe', Uint8List(1));
    await assertion;
    expect(web.document.querySelector('input[type=file]'), isNull);
  });
}
