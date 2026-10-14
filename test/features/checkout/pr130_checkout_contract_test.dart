import 'dart:convert';
import 'dart:io';
import 'package:acendra/features/checkout/data/repositories/supabase_checkout_repository.dart';
import 'package:acendra/features/checkout/domain/entities/payment_method.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  for (final status in [200, 201]) {
    test('checkout sends approved request and accepts $status', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final client = SupabaseClient(
        'http://127.0.0.1:${server.port}',
        'test-key',
      );
      addTearDown(() async {
        await client.dispose();
        await server.close(force: true);
      });
      String? key;
      Map<String, dynamic>? body;
      server.listen((request) async {
        key = request.headers.value('Idempotency-Key');
        body =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        request.response.headers.contentType = ContentType.json;
        request.response.statusCode = status;
        request.response.write(
          jsonEncode({
            'data': {
              'order_id': 'order',
              'order_number': 'ORD-1',
              'course': {'id': 'course', 'title': 'Course'},
              'amount_minor': 423456,
              'currency_code': 'LKR',
              'payment_method': 'bank_transfer',
              'status': 'pending_payment',
              'next_action': 'show_bank_instructions',
              'bank_instructions': {
                'bank_name': 'Bank',
                'account_holder': 'Holder',
                'account_number': '456',
                'branch_name': 'Real Branch',
                'currency_code': 'LKR',
              },
            },
          }),
        );
        await request.response.close();
      });
      final order = await SupabaseCheckoutRepository(client).createOrder(
        courseId: 'course',
        method: PaymentMethod.bankTransfer,
        idempotencyKey: 'stable-key',
      );
      expect(key, 'stable-key');
      expect(body, {'course_id': 'course', 'payment_method': 'bank_transfer'});
      expect(order.bankInstructions!.branch, 'Real Branch');
      expect(order.bankInstructions!.currency, 'LKR');
    });
  }
}
