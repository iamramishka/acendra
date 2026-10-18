import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/features/orders/data/orders_repository.dart';
import 'package:acendra/features/orders/domain/order_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Student order history (COM-014 / UI-ST-022).
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final filter = ref.watch(orderFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => AppErrorState(
          message: 'Could not load your orders. Please try again.',
          actionLabel: 'Retry',
          onRetry: () => ref.invalidate(ordersProvider),
        ),
        data: (all) {
          final shown = all.where((o) => o.matches(filter)).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final f in OrderFilter.values)
                      ChoiceChip(
                        label: Text(_filterLabel(f)),
                        selected: f == filter,
                        onSelected: (_) =>
                            ref.read(orderFilterProvider.notifier).state = f,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: shown.isEmpty
                    ? AppEmptyState(
                        message: 'No orders here.',
                        actionLabel: 'Explore courses',
                        onAction: () => context.go(RouteNames.marketplace),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: shown.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => OrderCard(order: shown[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _filterLabel(OrderFilter f) => switch (f) {
    OrderFilter.all => 'All',
    OrderFilter.paid => 'Paid',
    OrderFilter.awaiting => 'Awaiting Payment',
  };
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final d = order.createdAt.toLocal();
    final date =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #${order.orderNumber}',
                    style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                Chip(
                  label: Text(order.statusLabel),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            Text(order.courseTitle, style: tt.titleMedium),
            const SizedBox(height: 4),
            Text(
              '$date  •  ${order.formattedAmount}',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (_action(context) case final action?) ...[
              const SizedBox(height: 12),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget? _action(BuildContext context) {
    if (order.isPaid) {
      return OutlinedButton(
        onPressed: () => context.go('/learn/${order.courseId}'),
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
        child: const Text('Go to Course'),
      );
    }
    if (!order.isAwaiting) return null;
    return OutlinedButton(
      onPressed: () => context.push(
        order.isBankTransfer
            ? '/bank-transfer/${order.id}/status'
            : '/checkout/${order.courseId}',
      ),
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
      child: Text(
        order.isBankTransfer ? 'View Payment Status' : 'Resume Checkout',
      ),
    );
  }
}
