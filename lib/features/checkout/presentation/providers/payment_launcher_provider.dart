import 'package:acendra/features/checkout/domain/entities/payment_handoff.dart';
import 'package:acendra/features/checkout/presentation/services/payment_handoff.dart'
    if (dart.library.js_interop) 'package:acendra/features/checkout/presentation/services/payment_handoff_web.dart'
    as handoff;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final paymentLauncherProvider = Provider<Future<void> Function(PaymentHandoff)>(
  (ref) => handoff.launchPayment,
);
