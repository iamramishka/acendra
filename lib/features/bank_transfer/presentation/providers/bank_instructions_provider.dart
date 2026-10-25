import 'package:acendra/features/checkout/data/models/checkout_order_dto.dart';
import 'package:acendra/features/checkout/data/repositories/checkout_submission_repository.dart';
import 'package:acendra/features/checkout/domain/entities/checkout_order.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_actor_provider.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// No browser storage of bank details; reloads recover the owner-bound snapshot.
final bankInstructionsProvider = FutureProvider.autoDispose
    .family<CheckoutOrder, String>((ref, orderId) async {
      final actor = ref.watch(checkoutActorProvider);
      CheckoutOrder? checkout;
      try {
        checkout = await ref.watch(checkoutProvider.future);
      } catch (_) {
        // A previous checkout failure must not prevent an owner-scoped read.
      }
      if (checkout != null && checkout.orderId == orderId) return checkout;
      if (actor == null) throw StateError('Sign in required');
      if (!ref.mounted) throw StateError('Instructions request expired');
      final response = await ref
          .read(checkoutSubmissionRepositoryProvider)
          .invoke('bank-transfer-read', {}, {
            'order_id': orderId,
            'instructions': true,
          });
      if (response.status != 200 || response.data is! Map<String, dynamic>) {
        throw StateError('Instructions unavailable');
      }
      final order = CheckoutOrderDto.fromJson(
        response.data as Map<String, dynamic>,
      ).toEntity();
      if (order.orderId != orderId) throw StateError('Order mismatch');
      return order;
    });
