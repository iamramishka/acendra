import 'package:acendra/features/checkout/data/models/checkout_order_dto.dart';
import 'package:acendra/features/checkout/domain/entities/checkout_order.dart';
import 'package:acendra/features/checkout/domain/entities/payment_method.dart';
import 'package:acendra/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCheckoutRepository implements CheckoutRepository {
  const SupabaseCheckoutRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<CheckoutOrder> createOrder({
    required String courseId,
    required PaymentMethod method,
    required String idempotencyKey,
  }) async {
    final paymentMethodValue = switch (method) {
      PaymentMethod.online => 'online',
      PaymentMethod.bankTransfer => 'bank_transfer',
    };

    final response = await _client.functions.invoke(
      'create-checkout-order',
      body: {
        'course_id': courseId,
        'payment_method': paymentMethodValue,
        'idempotency_key': idempotencyKey,
      },
    );

    if (response.status != 200) {
      throw Exception(
        'Failed to create checkout order. Status: ${response.status}',
      );
    }

    final data = response.data as Map<String, dynamic>;
    final dto = CheckoutOrderDto.fromJson(data);
    return dto.toEntity();
  }
}

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return SupabaseCheckoutRepository(Supabase.instance.client);
});
