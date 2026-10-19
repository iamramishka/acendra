import 'package:acendra/features/checkout/data/repositories/student_order_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('order display preserves cents at the supported integer boundary', () {
    final order = StudentOrder.fromJson({
      'id': 'synthetic-order',
      'course_id': 'synthetic-course',
      'course_title_snapshot': 'Synthetic course',
      'order_number': 'SYNTHETIC',
      'amount_minor': 9007199254740990,
      'currency_code': 'LKR',
      'payment_method': 'online',
      'status': 'pending_payment',
    });
    expect(order.formattedAmount, 'LKR 90071992547409.90');
  });
}
