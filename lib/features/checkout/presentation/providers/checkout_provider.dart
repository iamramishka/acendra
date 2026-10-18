import 'package:acendra/features/checkout/data/repositories/supabase_checkout_repository.dart';
import 'package:acendra/features/checkout/domain/entities/checkout_order.dart';
import 'package:acendra/features/checkout/domain/entities/customer_info.dart';
import 'package:acendra/features/checkout/domain/entities/payment_method.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_actor_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

export 'package:acendra/features/checkout/data/repositories/supabase_checkout_repository.dart'
    show checkoutRepositoryProvider;

// ── Checkout order notifier ───────────────────────────────────────────────────

class CheckoutNotifier extends AsyncNotifier<CheckoutOrder?> {
  final Map<String, String> _requestKeys = {};
  int _generation = 0;
  @override
  Future<CheckoutOrder?> build() async {
    ref.watch(checkoutActorProvider);
    _generation++;
    _requestKeys.clear();
    return null;
  }

  Future<void> createOrder({
    required String courseId,
    required PaymentMethod method,
  }) async {
    if (state.isLoading) return;
    final generation = _generation;
    final actor = ref.read(checkoutActorProvider);
    state = const AsyncLoading();

    final idempotencyKey = _requestKeys.putIfAbsent(
      '$courseId:${method.name}',
      () => 'checkout-${DateTime.now().microsecondsSinceEpoch}',
    );

    final result = await AsyncValue.guard(() async {
      final repo = ref.read(checkoutRepositoryProvider);
      return repo.createOrder(
        courseId: courseId,
        method: method,
        idempotencyKey: idempotencyKey,
      );
    });
    if (ref.mounted &&
        generation == _generation &&
        actor == ref.read(checkoutActorProvider)) {
      state = result;
    }
  }

  void reset() {
    _generation++;
    state = const AsyncData(null);
  }
}

final checkoutProvider =
    AsyncNotifierProvider<CheckoutNotifier, CheckoutOrder?>(
      CheckoutNotifier.new,
    );

// ── Selected payment method ───────────────────────────────────────────────────

final selectedPaymentMethodProvider = StateProvider<PaymentMethod>(
  (ref) => PaymentMethod.online,
);

// ── Customer info notifier ────────────────────────────────────────────────────

class CustomerInfoNotifier extends Notifier<CustomerInfo> {
  @override
  CustomerInfo build() => const CustomerInfo(
    firstName: '',
    lastName: '',
    phone: '',
    address: '',
    city: '',
    country: '',
  );

  void update({
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    String? city,
    String? country,
  }) {
    state = state.copyWith(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      address: address,
      city: city,
      country: country,
    );
  }

  void reset() {
    state = const CustomerInfo(
      firstName: '',
      lastName: '',
      phone: '',
      address: '',
      city: '',
      country: '',
    );
  }
}

final customerInfoProvider =
    NotifierProvider<CustomerInfoNotifier, CustomerInfo>(
      CustomerInfoNotifier.new,
    );
