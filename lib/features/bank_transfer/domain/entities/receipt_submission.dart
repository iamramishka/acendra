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
  });

  final String orderId;
  final String orderNumber;
  final String courseTitle;
  final ReceiptStatus status;
  final String? submissionId;
  final String? rejectionReason;
  final DateTime? submittedAt;

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
