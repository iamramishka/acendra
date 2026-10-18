import 'dart:convert';
import 'dart:io';

import 'package:acendra/features/admin/data/repositories/admin_directory_client.dart';
import 'package:acendra/features/admin/data/repositories/admin_reporting_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, dynamic> _receipts({
  String gross = '1234567',
  String? confirmed,
  String currency = 'LKR',
  String basis = 'verified_settlement_receipts',
  String recognition = 'approved',
  String refunds = 'confirmed_adjustment_ledger_unavailable',
  String net = 'confirmed_adjustment_ledger_unavailable',
}) => {
  'basis': basis,
  'currency_code': currency,
  'confirmed_settlements': '3',
  'confirmed_amount_minor': confirmed ?? gross,
  'gross_receipts_minor': gross,
  'recognition_status': recognition,
  'refunds_status': refunds,
  'net_status': net,
};

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late List<Map<String, dynamic>> requests;
  late Map<String, dynamic> data;
  var status = 200;

  setUp(() async {
    status = 200;
    requests = [];
    data = {
      'pending_bank_reviews': '2',
      'confirmed_receipts': _receipts(),
      'period': 'last_30_days',
    };
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'synthetic-key');
    server.listen((request) async {
      expect(request.uri.path, '/functions/v1/admin-dashboard-stats');
      requests.add(
        jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>,
      );
      request.response.headers.contentType = ContentType.json;
      request.response.statusCode = status;
      request.response.write(
        jsonEncode(
          status == 200
              ? {'data': data}
              : {
                  'error': {'code': 'REPORTING_UNAVAILABLE'},
                },
        ),
      );
      await request.response.close();
    });
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  Future<ConfirmedReceipts> load() =>
      SupabaseAdminReportingRepository(client).confirmedReceipts();

  test('requests exactly the approved last_30_days period', () async {
    await load();
    expect(requests, [
      {'period': 'last_30_days'},
    ]);
  });

  test('parses exact gross receipts without floating point loss', () async {
    data['confirmed_receipts'] = _receipts(gross: '9007199254740993123');
    final receipts = await load();
    expect(receipts.grossReceiptsMinor, BigInt.parse('9007199254740993123'));
    expect(receipts.currency, 'LKR');
    expect(receipts.formattedGross, 'LKR 90,071,992,547,409,931.23');
  });

  test('formats minor units with two decimals', () {
    ConfirmedReceipts of(String minor) => ConfirmedReceipts(
      grossReceiptsMinor: BigInt.parse(minor),
      currency: 'LKR',
    );
    expect(of('0').formattedGross, 'LKR 0.00');
    expect(of('5').formattedGross, 'LKR 0.05');
    expect(of('100').formattedGross, 'LKR 1.00');
    expect(of('123456').formattedGross, 'LKR 1,234.56');
  });

  test('refund and net are never exposed as numbers', () async {
    final receipts = await load();
    expect(receipts.refundsAvailable, isFalse);
    expect(receipts.netAvailable, isFalse);
  });

  test('omitted receipts (role lacks finance) are unavailable, not zero', () {
    data.remove('confirmed_receipts');
    expect(load(), throwsA(isA<ReportingUnavailable>()));
  });

  test('disabled endpoint maps to a safe unavailable error', () {
    status = 503;
    expect(load(), throwsA(isA<AdminDataException>()));
  });

  for (final entry in <String, Map<String, dynamic>>{
    'non-numeric gross': _receipts(gross: '12.50'),
    'negative gross': _receipts(gross: '-5'),
    'numeric JSON instead of string': {
      ..._receipts(),
      'gross_receipts_minor': 5,
    },
    'gross differs from confirmed amount': _receipts(
      gross: '100',
      confirmed: '200',
    ),
    'foreign currency': _receipts(currency: 'USD'),
    'unrecognised basis': _receipts(basis: 'order_status'),
    'recognition not approved': _receipts(recognition: 'pending'),
    'refunds claimed available': _receipts(refunds: 'available'),
    'net claimed available': _receipts(net: 'available'),
  }.entries) {
    test('fails closed on ${entry.key}', () {
      data['confirmed_receipts'] = entry.value;
      expect(load(), throwsA(isA<AdminDataException>()));
    });
  }
}
