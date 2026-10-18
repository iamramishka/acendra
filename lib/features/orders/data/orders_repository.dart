import 'package:acendra/features/orders/domain/order_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class OrdersRepository {
  Future<List<OrderSummary>> listOwn();
}

/// Reads the signed-in student's orders. RLS (csa092_orders_read_own)
/// enforces ownership; the explicit buyer filter is defense in depth.
class SupabaseOrdersRepository implements OrdersRepository {
  const SupabaseOrdersRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<OrderSummary>> listOwn() async {
    final user = _client.auth.currentUser;
    var query = _client
        .from('orders')
        .select(
          'id, order_number, course_id, course_title_snapshot, amount_minor, '
          'currency_code, payment_method, status, created_at',
        );
    if (user != null) query = query.eq('buyer_id', user.id);
    final rows = await query.order('created_at', ascending: false).limit(100);
    return (rows as List<dynamic>)
        .map((r) => OrderSummary.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => SupabaseOrdersRepository(Supabase.instance.client),
);

final ordersProvider = FutureProvider.autoDispose<List<OrderSummary>>(
  (ref) => ref.read(ordersRepositoryProvider).listOwn(),
);

final orderFilterProvider = StateProvider.autoDispose<OrderFilter>(
  (ref) => OrderFilter.all,
);
