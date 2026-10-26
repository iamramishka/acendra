import 'package:acendra/features/bank_transfer/domain/entities/receipt_submission.dart';

/// An old backend may omit additive metadata; it must never be invented.
ReceiptSubmission receiptSubmissionFromJson(
  Map<String, dynamic> data,
  String orderId,
) {
  if (data['order_id'] != orderId) {
    throw const FormatException('Order mismatch');
  }
  final status = switch (data['status']) {
    'awaiting_receipt' => ReceiptStatus.awaitingReceipt,
    'submitted' => ReceiptStatus.submitted,
    'under_review' => ReceiptStatus.underReview,
    'approved' => ReceiptStatus.approved,
    'rejected' => ReceiptStatus.rejected,
    _ => throw const FormatException('Invalid receipt status'),
  };
  final rawAmount = data['amount_minor'];
  final currency = data['currency'];
  BigInt? amount;
  if (rawAmount != null || currency != null) {
    // The new contract uses decimal strings to retain every PostgreSQL bigint
    // digit. Do not accept rounded browser JSON numbers as financial evidence.
    if (rawAmount is! String ||
        !RegExp(r'^\d+$').hasMatch(rawAmount) ||
        currency is! String ||
        !RegExp(r'^[A-Z]{3}$').hasMatch(currency)) {
      throw const FormatException('Invalid order amount');
    }
    amount = BigInt.parse(rawAmount);
    if (amount > BigInt.parse('9223372036854775807')) {
      throw const FormatException('Invalid order amount');
    }
  }
  DateTime? date(String field) {
    final value = data[field];
    if (value == null) return null;
    final result = value is String ? DateTime.tryParse(value) : null;
    if (result == null) throw const FormatException('Invalid order date');
    return result;
  }

  return ReceiptSubmission(
    orderId: orderId,
    orderNumber: data['order_number'] as String,
    courseTitle: data['course_title'] as String,
    status: status,
    submissionId: data['submission_id'] as String?,
    rejectionReason: data['rejection_reason'] as String?,
    submittedAt: date('submitted_at'),
    amountMinor: amount,
    currency: currency as String?,
    orderCreatedAt: date('order_created_at'),
  );
}
