import 'package:acendra/features/checkout/domain/entities/checkout_order.dart';
import 'package:acendra/features/checkout/domain/entities/payment_method.dart';

abstract class CheckoutRepository {
  Future<CheckoutOrder> createOrder({
    required String courseId,
    required PaymentMethod method,
    required String idempotencyKey,
  });
}
