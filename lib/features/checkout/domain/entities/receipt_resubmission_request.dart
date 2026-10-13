/// Domain entity representing a student's request to resubmit a bank transfer
/// receipt after it was rejected by the finance team.
///
/// The actual file bytes are handled separately via the upload flow
/// (see CSA-108 for the private receipt upload Edge Function).
class ReceiptResubmissionRequest {
  const ReceiptResubmissionRequest({
    required this.orderId,
    this.note = '',
  });

  /// The order ID for which a new receipt is being submitted.
  final String orderId;

  /// An optional note from the student explaining the resubmission
  /// (e.g. clarifying the transfer reference or correcting a mistake).
  final String note;

  ReceiptResubmissionRequest copyWith({
    String? orderId,
    String? note,
  }) {
    return ReceiptResubmissionRequest(
      orderId: orderId ?? this.orderId,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptResubmissionRequest &&
          runtimeType == other.runtimeType &&
          orderId == other.orderId &&
          note == other.note;

  @override
  int get hashCode => orderId.hashCode ^ note.hashCode;

  @override
  String toString() =>
      'ReceiptResubmissionRequest(orderId: $orderId, note: $note)';
}
