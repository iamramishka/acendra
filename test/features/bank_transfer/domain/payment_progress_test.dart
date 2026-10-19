import 'package:acendra/features/bank_transfer/domain/entities/receipt_submission.dart';
import 'package:acendra/features/bank_transfer/domain/payment_progress.dart';
import 'package:flutter_test/flutter_test.dart';

List<ProgressState> _states(ReceiptStatus s) =>
    paymentProgressSteps(s).map((e) => e.state).toList();

void main() {
  test('always has the four prototype steps in order', () {
    for (final s in ReceiptStatus.values) {
      expect(paymentProgressSteps(s).map((e) => e.title), [
        'Order Created',
        'Receipt Submitted',
        'Bank Verification',
        'Enrollment Activated',
      ]);
    }
  });

  test('awaiting receipt: receipt step is current', () {
    expect(_states(ReceiptStatus.awaitingReceipt), [
      ProgressState.done,
      ProgressState.current,
      ProgressState.todo,
      ProgressState.todo,
    ]);
  });

  test('submitted and under review: verification is current', () {
    for (final s in [ReceiptStatus.submitted, ReceiptStatus.underReview]) {
      expect(_states(s), [
        ProgressState.done,
        ProgressState.done,
        ProgressState.current,
        ProgressState.todo,
      ]);
    }
  });

  test('approved: every step done', () {
    expect(_states(ReceiptStatus.approved), everyElement(ProgressState.done));
  });

  test('rejected: verification failed, enrollment not started', () {
    expect(_states(ReceiptStatus.rejected), [
      ProgressState.done,
      ProgressState.done,
      ProgressState.failed,
      ProgressState.todo,
    ]);
  });

  test('only an approved payment marks enrollment done', () {
    for (final s in ReceiptStatus.values.where(
      (s) => s != ReceiptStatus.approved,
    )) {
      expect(_states(s).last, isNot(ProgressState.done));
    }
  });
}
