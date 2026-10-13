/// Review status of a bank transfer receipt submitted by a student.
enum ReceiptReviewStatus { pending, approved, rejected }

/// Represents a student's bank transfer receipt submission and its review state.
class ReceiptSubmission {
  const ReceiptSubmission({
    required this.id,
    required this.orderId,
    required this.status,
    required this.submittedAt,
    this.rejectionReason,
    this.reviewedAt,
  }) : assert(
         status != ReceiptReviewStatus.rejected || rejectionReason != null,
         'rejectionReason must be provided when status is rejected',
       );

  final String id;
  final String orderId;
  final ReceiptReviewStatus status;
  final DateTime submittedAt;

  /// Non-null when [status] is [ReceiptReviewStatus.rejected].
  final String? rejectionReason;

  /// Non-null once the receipt has been reviewed (approved or rejected).
  final DateTime? reviewedAt;
}
