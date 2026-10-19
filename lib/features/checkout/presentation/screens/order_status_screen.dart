import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/features/checkout/data/repositories/student_order_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OrderStatusScreen extends ConsumerWidget {
  const OrderStatusScreen({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Payment Status'),
      leading: BackButton(onPressed: () => context.go(RouteNames.myCourses)),
    ),
    body: ref
        .watch(studentOrderProvider(orderId))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Order status is unavailable. Please retry.'),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(studentOrderProvider(orderId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (order) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Icon(
                    order.isOpen ? Icons.shield_outlined : Icons.receipt_long,
                    size: 64,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    order.statusLabel,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text('Order #${order.number}'),
                          Text(order.formattedAmount),
                          Text(
                            order.isBank ? 'Bank Transfer' : 'Online Payment',
                          ),
                          Text(order.statusLabel),
                        ],
                      ),
                    ),
                  ),
                  const Text(
                    'Course access starts only after payment is independently verified and your enrollment is activated. Avoid starting another payment while verification is pending.',
                  ),
                  const SizedBox(height: 16),
                  if (order.method == 'online' &&
                      order.status == 'pending_payment')
                    FilledButton(
                      onPressed: () => context.go(
                        RouteNames.checkout.replaceFirst(
                          ':courseId',
                          order.courseId,
                        ),
                      ),
                      child: const Text('Continue Payment'),
                    ),
                  if (order.isBank && order.status == 'pending_payment')
                    FilledButton(
                      onPressed: () => context.go(
                        RouteNames.bankTransfer.replaceFirst(
                          ':orderId',
                          order.id,
                        ),
                      ),
                      child: const Text('Bank Transfer Instructions'),
                    ),
                  OutlinedButton(
                    onPressed: () =>
                        ref.invalidate(studentOrderProvider(orderId)),
                    child: const Text('Refresh Payment Status'),
                  ),
                  if (order.isBank && order.isOpen)
                    OutlinedButton(
                      onPressed: () => context.push(
                        RouteNames.receiptStatus.replaceFirst(
                          ':orderId',
                          order.id,
                        ),
                      ),
                      child: const Text('View Receipt Status'),
                    ),
                  TextButton(
                    onPressed: () => context.go(
                      RouteNames.courseDetail.replaceFirst(
                        ':courseId',
                        order.courseId,
                      ),
                    ),
                    child: const Text('View Course'),
                  ),
                ],
              ),
            ),
          ),
        ),
  );
}
