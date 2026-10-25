import 'dart:typed_data';
import 'package:acendra/features/checkout/presentation/services/receipt_file.dart';
import 'package:acendra/features/checkout/data/repositories/checkout_submission_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('COM-012 permits JPEG PNG PDF through exactly 5 MiB', () {
    for (final name in [
      'receipt.jpg',
      'receipt.JPEG',
      'receipt.PNG',
      'receipt.pdf',
    ]) {
      expect(receiptFileError(name, maxReceiptBytes), isNull);
      expect(receiptFileError(name, maxReceiptBytes + 1), contains('5 MiB'));
      expect(receiptFileError(name, 0), isNotNull);
    }
    for (final name in ['receipt.svg', 'receipt.png.exe', 'receipt']) {
      expect(receiptFileError(name, 1), isNotNull);
    }
  });
  test(
    'COM-012 PNG upload uses image/png and safe transport filename',
    () async {
      const order = '11111111-1111-4111-8111-111111111111';
      var calls = 0;
      final repo = CheckoutSubmissionRepository((name, headers, body) async {
        calls++;
        expect(name, 'upload-bank-receipt');
        expect(headers['Content-Type'], 'image/png');
        expect(headers['X-Receipt-Name'], 'receipt.png');
        return const FunctionResponse(
          status: 201,
          data: {
            'data': {
              'order_id': order,
              'submission_id': '22222222-2222-4222-8222-222222222222',
              'status': 'submitted',
            },
          },
        );
      });
      await repo.submitReceipt(
        orderId: order,
        name: 'private.PNG',
        bytes: Uint8List(1),
        key: 'same-key',
      );
      expect(calls, 1);
    },
  );
}
