/// Domain entity representing a bank transfer receipt submitted for finance review.
library;

enum ReceiptStatus { pending, approved, rejected }

class ReceiptReviewItem {
  const ReceiptReviewItem({
    required this.id,
    required this.orderId,
    required this.studentId,
    required this.studentEmail,
    required this.courseTitle,
    required this.amount,
    required this.currency,
    required this.submittedAt,
    required this.status,
    required this.receiptStoragePath,
    this.rejectionReason,
  });

  final String id;
  final String orderId;
  final String studentId;
  final String studentEmail;
  final String courseTitle;
  final double amount;
  final String currency;
  final DateTime submittedAt;
  final ReceiptStatus status;
  final String? rejectionReason;

  // NOTE: The actual file URL is fetched via a secure signed URL from the backend.
  // This model holds the receipt storage path reference, not a public URL.
  final String receiptStoragePath;

  ReceiptReviewItem copyWith({
    String? id,
    String? orderId,
    String? studentId,
    String? studentEmail,
    String? courseTitle,
    double? amount,
    String? currency,
    DateTime? submittedAt,
    ReceiptStatus? status,
    String? receiptStoragePath,
    String? rejectionReason,
  }) {
    return ReceiptReviewItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      studentId: studentId ?? this.studentId,
      studentEmail: studentEmail ?? this.studentEmail,
      courseTitle: courseTitle ?? this.courseTitle,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      receiptStoragePath: receiptStoragePath ?? this.receiptStoragePath,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptReviewItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
