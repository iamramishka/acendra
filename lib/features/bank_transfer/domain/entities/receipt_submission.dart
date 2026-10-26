import 'package:flutter/foundation.dart';

enum ReceiptStatus {
  awaitingReceipt,
  submitted,
  underReview,
  approved,
  rejected,
}

@immutable
class ReceiptSubmission {
  const ReceiptSubmission({
    required this.orderId,
    required this.orderNumber,
    required this.courseTitle,
    required this.status,
    this.submissionId,
    this.rejectionReason,
    this.submittedAt,
    this.amountMinor,
    this.currency,
    this.orderCreatedAt,
  });

  final String orderId;
  final String orderNumber;
  final String courseTitle;
  final ReceiptStatus status;
  final String? submissionId;
  final String? rejectionReason;
  final DateTime? submittedAt;

  /// Exact minor units: a JSON integer may exceed JavaScript's safe precision.
  final BigInt? amountMinor;
  final String? currency;
  final DateTime? orderCreatedAt;

  String? get formattedAmount {
    final amount = amountMinor;
    if (amount == null || currency == null) return null;
    final hundred = BigInt.from(100);
    return '$currency ${amount ~/ hundred}.${(amount % hundred).toString().padLeft(2, '0')}';
  }

  String get statusLabel {
    switch (status) {
      case ReceiptStatus.awaitingReceipt:
        return 'Awaiting Receipt';
      case ReceiptStatus.submitted:
        return 'Submitted';
      case ReceiptStatus.underReview:
        return 'Under Review';
      case ReceiptStatus.approved:
        return 'Approved';
      case ReceiptStatus.rejected:
        return 'Rejected';
    }
  }
}
