/// An initialized payment is pending until the trusted backend settles it.
class PaymentHandoff {
  PaymentHandoff({
    required this.orderId,
    required this.action,
    required Map<String, String> fields,
  }) : fields = Map.unmodifiable(fields);
  final String orderId;
  final Uri action;
  final Map<String, String> fields;
}

class CheckoutFlowException implements Exception {
  const CheckoutFlowException(this.message);
  final String message;
  @override
  String toString() => message;
}
