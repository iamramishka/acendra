import 'package:acendra/features/checkout/domain/entities/payment_handoff.dart';

Future<void> launchPayment(PaymentHandoff payment) async {
  throw const CheckoutFlowException('Online payment requires a web browser.');
}
