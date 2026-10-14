import 'dart:typed_data';
import 'package:acendra/features/checkout/data/repositories/checkout_submission_repository.dart';
import 'package:acendra/features/checkout/domain/entities/customer_info.dart';
import 'package:acendra/features/checkout/domain/entities/payment_handoff.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const order = '11111111-1111-4111-8111-111111111111';
const attempt = '22222222-2222-4222-8222-222222222222';
const customer = CustomerInfo(
  firstName: ' Sample ',
  lastName: 'Student',
  phone: '+94771234567',
  address: 'Test Street',
  city: 'Colombo',
  country: 'Sri Lanka',
);
Map<String, dynamic> handoff({
  String action = 'https://sandbox.payhere.lk/pay/checkout',
}) => {
  'order_id': order,
  'attempt_id': attempt,
  'status': 'pending_payment',
  'checkout': {
    'action': action,
    'fields': {
      'first_name': 'Sample',
      'last_name': 'Student',
      'email': 'sample@example.test',
      'phone': '+94771234567',
      'address': 'Test Street',
      'city': 'Colombo',
      'country': 'Sri Lanka',
      'return_url': 'https://app.example.test/return',
      'cancel_url': 'https://app.example.test/cancel',
      'notify_url': 'https://app.example.test/notify',
      'merchant_id': '123456',
      'order_id': attempt,
      'items': 'Sample Course',
      'currency': 'LKR',
      'amount': '123.45',
      'hash': 'a' * 32,
    },
  },
};
Future<PaymentHandoff> initialize(CheckoutSubmissionRepository repo) =>
    repo.initialize(
      orderId: order,
      amountMinor: 12345,
      customer: customer,
      key: 'online-replay',
    );

void main() {
  test(
    'initialization sends contact contract and replay key, returns only pending handoff',
    () async {
      final repo = CheckoutSubmissionRepository((name, headers, body) async {
        expect(name, 'initialize-checkout');
        expect(headers['Idempotency-Key'], 'online-replay');
        final request = body as Map;
        expect(request.keys, unorderedEquals(['order_id', 'customer']));
        expect((request['customer'] as Map)['first_name'], 'Sample');
        expect((request['customer'] as Map).containsKey('email'), false);
        return FunctionResponse(status: 201, data: {'data': handoff()});
      });
      final payment = await initialize(repo);
      expect(payment.action.host, 'sandbox.payhere.lk');
      expect(payment.fields['order_id'], attempt);
      expect(() => payment.fields['amount'] = '0.01', throwsUnsupportedError);
    },
  );
  for (final action in [
    'http://sandbox.payhere.lk/pay/checkout',
    'https://evil.test/pay/checkout',
    'https://sandbox.payhere.lk.evil.test/pay/checkout',
    'https://user@sandbox.payhere.lk/pay/checkout',
    'https://sandbox.payhere.lk/pay/checkout?redirect=evil',
    'https://sandbox.payhere.lk/other',
  ]) {
    test('rejects unsafe provider destination $action', () async {
      final repo = CheckoutSubmissionRepository(
        (_, headers, body) async => FunctionResponse(
          status: 200,
          data: {'data': handoff(action: action)},
        ),
      );
      await expectLater(
        initialize(repo),
        throwsA(isA<CheckoutFlowException>()),
      );
    });
  }
  for (final change in ['order', 'paid', 'amount', 'attempt', 'extra']) {
    test(
      'rejects mismatched or paid initialization response: $change',
      () async {
        final data = handoff();
        final fields = (data['checkout'] as Map)['fields'] as Map;
        switch (change) {
          case 'order':
            data['order_id'] = attempt;
          case 'paid':
            data['status'] = 'paid';
          case 'amount':
            fields['amount'] = '0.01';
          case 'attempt':
            fields['order_id'] = order;
          case 'extra':
            fields['submit'] = 'malicious';
        }
        final repo = CheckoutSubmissionRepository(
          (_, headers, body) async =>
              FunctionResponse(status: 200, data: {'data': data}),
        );
        await expectLater(
          initialize(repo),
          throwsA(isA<CheckoutFlowException>()),
        );
      },
    );
  }
  test(
    'binary receipt uses private handler contract and safe filename; replay key retained',
    () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      var calls = 0;
      final repo = CheckoutSubmissionRepository((name, headers, body) async {
        calls++;
        expect(name, 'upload-bank-receipt');
        expect(identical(body, bytes), true);
        expect(headers, {
          'Idempotency-Key': 'receipt-replay',
          'X-Order-Id': order,
          'X-Receipt-Name': 'receipt.jpg',
          'Content-Type': 'image/jpeg',
        });
        return FunctionResponse(
          status: calls == 1 ? 201 : 200,
          data: {
            'data': {
              'order_id': order,
              'submission_id': attempt,
              'status': 'submitted',
            },
          },
        );
      });
      for (var i = 0; i < 2; i++) {
        await repo.submitReceipt(
          orderId: order,
          name: 'private-name.jpg',
          bytes: bytes,
          key: 'receipt-replay',
        );
      }
      expect(calls, 2);
    },
  );
  test(
    'SDK gated failure is sanitized and cannot become submission success',
    () async {
      final repo = CheckoutSubmissionRepository(
        (_, headers, body) async => throw const FunctionException(
          status: 503,
          details: 'private storage/path and credential',
        ),
      );
      await expectLater(
        initialize(repo),
        throwsA(
          isA<CheckoutFlowException>()
              .having(
                (e) => e.message,
                'message',
                contains('temporarily unavailable'),
              )
              .having(
                (e) => e.message,
                'private details',
                isNot(contains('private')),
              ),
        ),
      );
    },
  );
  test(
    'receipt response cannot substitute another order or payment status',
    () async {
      for (final data in [
        {'order_id': attempt, 'submission_id': attempt, 'status': 'submitted'},
        {'order_id': order, 'submission_id': attempt, 'status': 'paid'},
      ]) {
        final repo = CheckoutSubmissionRepository(
          (_, headers, body) async =>
              FunctionResponse(status: 200, data: {'data': data}),
        );
        await expectLater(
          repo.submitReceipt(
            orderId: order,
            name: 'receipt.pdf',
            bytes: Uint8List(1),
            key: 'key',
          ),
          throwsA(isA<CheckoutFlowException>()),
        );
      }
    },
  );
}
