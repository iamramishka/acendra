import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/bank_transfer/data/models/receipt_submission_dto.dart';
import 'package:acendra/features/bank_transfer/presentation/widgets/payment_progress_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> record() => {
  'order_id': 'order',
  'order_number': 'AC-1',
  'course_title': 'Backend Course',
  'status': 'submitted',
  'amount_minor': '9007199254740993',
  'currency': 'LKR',
  'order_created_at': '2026-10-01T00:00:00Z',
  'submitted_at': '2026-10-26T00:00:00Z',
};

void main() {
  test('order amount remains exact beyond browser integer precision', () {
    final submission = receiptSubmissionFromJson(record(), 'order');
    expect(submission.formattedAmount, 'LKR 90071992547409.93');
    expect(submission.orderCreatedAt, DateTime.utc(2026, 10, 1));
  });
  test('old payload does not fabricate amount or ordered date', () {
    final value = record()
      ..remove('amount_minor')
      ..remove('currency')
      ..remove('order_created_at');
    final submission = receiptSubmissionFromJson(value, 'order');
    expect(submission.formattedAmount, isNull);
    expect(submission.orderCreatedAt, isNull);
  });
  for (final invalid in [
    {'order_id': 'other'},
    {'amount_minor': '1.2'},
    {'amount_minor': '-1'},
    {'amount_minor': 1.2},
    {'currency': 'invalid'},
    {'order_created_at': 'invalid'},
    {'status': 'unknown'},
  ]) {
    test('malformed order details fail closed: $invalid', () {
      expect(
        () => receiptSubmissionFromJson({...record(), ...invalid}, 'order'),
        throwsFormatException,
      );
    });
  }
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'bank details $width dark=$dark show order date, not receipt date',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: Scaffold(
                body: BankOrderDetailsCard(
                  submission: receiptSubmissionFromJson(record(), 'order'),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Amount'), findsOneWidget);
          expect(find.text('LKR 90071992547409.93'), findsOneWidget);
          expect(find.text('Ordered'), findsOneWidget);
          expect(find.text('1/10/2026'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
