import 'dart:convert';
import 'dart:io';

import 'package:acendra/features/admin/data/repositories/admin_directory_client.dart';
import 'package:acendra/features/admin/data/repositories/supabase_admin_payment_repository.dart';
import 'package:acendra/features/admin/domain/entities/payment_record.dart';
import 'package:acendra/features/admin/data/repositories/admin_payment_repository.dart';
import 'package:acendra/features/admin/presentation/providers/admin_payments_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const paymentId = '00000000-0000-4000-8000-000000000001';
const stamp = '2026-10-19T00:00:00.123456Z';
Map<String, dynamic> item({String amount = '12345'}) => {
  'payment_id': paymentId,
  'order_id': paymentId,
  'order_number': 'ORD-2026-001',
  'course_id': '00000000-0000-4000-8000-000000000002',
  'course_title': 'Actual course',
  'amount_minor': amount,
  'currency_code': 'LKR',
  'method': 'online',
  'status': 'pending',
  'created_at': stamp,
  'updated_at': stamp,
  'settled_at': null,
};
Map<String, dynamic> page({String? cursor}) => {
  'items': [item()],
  'next_cursor': cursor,
  'counts': {
    'pending': '1',
    'processing': '2',
    'approved': '3',
    'rejected': '4',
    'total': '10',
  },
  'as_of': stamp,
  'count_as_of': stamp,
  'count_basis': 'current_snapshot',
};

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late SupabaseAdminPaymentRepository repository;
  late List<Map<String, dynamic>> requests;
  late Map<String, dynamic> response;
  var responseStatus = 200;
  setUp(() async {
    requests = [];
    response = page();
    responseStatus = 200;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'synthetic-key');
    repository = SupabaseAdminPaymentRepository(client);
    server.listen((request) async {
      expect(request.uri.path, '/functions/v1/admin-payment-list');
      requests.add(
        jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>,
      );
      request.response.headers.contentType = ContentType.json;
      request.response.statusCode = responseStatus;
      request.response.write(jsonEncode({'data': response}));
      await request.response.close();
    });
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });
  test(
    'loads authorized records without inventing buyer data and preserves exact money',
    () async {
      response['items'] = [item(amount: '9007199254740993123')];
      final result = (await repository.listPayments()).single;
      expect(result.id, paymentId);
      expect(result.orderId, paymentId);
      expect(result.orderNumber, 'ORD-2026-001');
      expect(result.studentEmail, isEmpty);
      expect(result.studentId, isEmpty);
      expect(result.paymentMethod, PaymentMethod.online);
      expect(result.formattedAmount, 'LKR 90071992547409931.23');
      expect(requests.single, {
        'mode': 'list',
        'page_size': 20,
        'cursor': null,
        'status': null,
        'method': null,
        'from': null,
        'to': null,
        'order_number_prefix': null,
      });
    },
  );
  test('passes signed cursor unchanged and resets it on refresh', () async {
    response = page(cursor: 'signed.cursor');
    await repository.listPayments(pageSize: 1);
    response = page();
    await repository.listPayments(page: 1, pageSize: 1);
    await repository.listPayments(pageSize: 1);
    expect(requests.map((r) => r['cursor']), [null, 'signed.cursor', null]);
  });
  test('counts use one unfiltered snapshot', () async {
    final counts = await repository.countAllStatuses();
    expect(counts, {
      PaymentStatus.pending: 1,
      PaymentStatus.processing: 2,
      PaymentStatus.approved: 3,
      PaymentStatus.rejected: 4,
    });
    expect(requests, hasLength(1));
    expect(requests.single['status'], isNull);
  });
  test(
    'order outcomes cannot be presented as receipt review audit history',
    () async {
      final container = ProviderContainer(
        overrides: [
          adminPaymentRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await expectLater(
        container.read(
          receiptHistoryProvider(const AdminPaymentsFilter()).future,
        ),
        throwsA(isA<PaymentReportingUnavailable>()),
      );
      expect(requests, isEmpty);
    },
  );
  test('uses terminal cursor rather than row count for Load more', () async {
    await repository.listPayments(pageSize: 1);
    expect(repository.hasMore(page: 0, pageSize: 1), isFalse);
    response = page(cursor: 'next.cursor');
    await repository.listPayments(pageSize: 1);
    expect(repository.hasMore(page: 0, pageSize: 1), isTrue);
  });
  test('splits history requests into API pages of at most 50', () async {
    response = page(cursor: 'history.cursor');
    response['items'] = List.generate(
      50,
      (index) => {
        ...item(),
        'payment_id':
            '00000000-0000-4000-8000-${index.toString().padLeft(12, '0')}',
        'order_id':
            '00000000-0000-4000-8000-${index.toString().padLeft(12, '0')}',
      },
    );
    // A single response is sufficient to demonstrate the per-request cap; an
    // echoed cursor on the next response must fail closed instead of looping.
    await expectLater(
      repository.listPayments(pageSize: 100),
      throwsA(isA<AdminDataException>()),
    );
    expect(requests.map((r) => r['page_size']), [50, 50]);
    expect(requests.last['cursor'], 'history.cursor');
  });
  test('supports real detail mode and preserves order identity', () async {
    response = {'item': item(), 'as_of': stamp};
    final record = await repository.getPayment(paymentId);
    expect(record.orderId, paymentId);
    expect(requests.single, {'mode': 'detail', 'payment_id': paymentId});
  });
  test('maps order prefix and method without email search', () async {
    await repository.listPayments(
      searchQuery: 'ORD-2026',
      method: PaymentMethod.online,
    );
    expect(requests.single['order_number_prefix'], 'ORD-2026');
    expect(requests.single['method'], 'online');
    await expectLater(
      repository.listPayments(searchQuery: 'buyer@example.test'),
      throwsA(isA<AdminDataException>()),
    );
    expect(requests, hasLength(1));
  });
  test(
    'rejects unknown cursor position instead of repeating the first page',
    () async {
      await expectLater(
        repository.listPayments(page: 1),
        throwsA(isA<AdminDataException>()),
      );
      expect(requests, isEmpty);
    },
  );
  for (final status in [401, 403, 503]) {
    test('fails closed on HTTP $status', () async {
      responseStatus = status;
      await expectLater(
        repository.listPayments(),
        throwsA(isA<AdminDataException>()),
      );
    });
  }
  test('rejects malformed financial rows and inconsistent counts', () async {
    response['items'] = [item(amount: '12.34')];
    await expectLater(
      repository.listPayments(),
      throwsA(isA<AdminDataException>()),
    );
    response = page();
    (response['counts'] as Map)['total'] = '9';
    await expectLater(
      repository.countAllStatuses(),
      throwsA(isA<AdminDataException>()),
    );
  });
  test(
    'rejects sandbox or unverified paid data without a settlement',
    () async {
      response['items'] = [
        {...item(), 'status': 'approved'},
      ];
      await expectLater(
        repository.listPayments(),
        throwsA(isA<AdminDataException>()),
      );
    },
  );
}
