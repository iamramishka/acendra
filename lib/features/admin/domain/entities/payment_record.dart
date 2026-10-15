library;

enum PaymentMethod { stripe, bankTransfer, adminGrant }

enum PaymentStatus { pending, approved, rejected, processing }

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.orderId,
    required this.studentId,
    required this.studentEmail,
    required this.courseId,
    required this.courseTitle,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.processorNote,
    this.receiptStoragePath,
  });

  final String id;
  final String orderId;
  final String studentId;
  final String studentEmail;
  final String courseId;
  final String courseTitle;
  final double amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? processorNote;

  // NOTE: The actual file URL is fetched via a signed URL from the trusted backend.
  final String? receiptStoragePath;

  PaymentRecord copyWith({
    String? id,
    String? orderId,
    String? studentId,
    String? studentEmail,
    String? courseId,
    String? courseTitle,
    double? amount,
    String? currency,
    PaymentMethod? paymentMethod,
    PaymentStatus? status,
    DateTime? createdAt,
    DateTime? processedAt,
    String? processorNote,
    String? receiptStoragePath,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      studentId: studentId ?? this.studentId,
      studentEmail: studentEmail ?? this.studentEmail,
      courseId: courseId ?? this.courseId,
      courseTitle: courseTitle ?? this.courseTitle,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      processorNote: processorNote ?? this.processorNote,
      receiptStoragePath: receiptStoragePath ?? this.receiptStoragePath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
