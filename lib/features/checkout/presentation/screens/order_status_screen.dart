import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/features/checkout/data/repositories/student_order_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A return URL is a locator, never evidence of payment or course access.
class OrderStatusScreen extends ConsumerWidget {
  const OrderStatusScreen({
    super.key,
    required this.orderId,
    this.expectedCourseId,
    this.onlineOnly = false,
    this.cancelledReturn = false,
  });
  final String? orderId;
  final String? expectedCourseId;
  final bool onlineOnly;
  final bool cancelledReturn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = orderId;
    final hasLocator = id != null && id.isNotEmpty && id.length <= 128;
    final value = hasLocator ? ref.watch(studentOrderProvider(id)) : null;
    Widget unavailable() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.info_outline, size: 64),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Payment details are unavailable. Open Order History to check your payment.',
          textAlign: TextAlign.center,
        ),
        if (hasLocator) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Retry',
            onPressed: () => ref.invalidate(studentOrderProvider(id)),
          ),
        ],
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.orders),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (value == null)
                  unavailable()
                else
                  value.when(
                    skipLoadingOnRefresh: false,
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, _) => unavailable(),
                    data: (order) {
                      if (order.id != id ||
                          (expectedCourseId != null &&
                              order.courseId != expectedCourseId) ||
                          (onlineOnly && order.method != 'online') ||
                          !{'online', 'bank_transfer'}.contains(order.method)) {
                        return unavailable();
                      }
                      return _OrderDetails(
                        order: order,
                        cancelledReturn: cancelledReturn,
                        refresh: () =>
                            ref.invalidate(studentOrderProvider(order.id)),
                      );
                    },
                  ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'View Order History',
                  variant: ButtonVariant.outlined,
                  onPressed: () => context.go(RouteNames.orders),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderDetails extends StatelessWidget {
  const _OrderDetails({
    required this.order,
    required this.cancelledReturn,
    required this.refresh,
  });
  final StudentOrder order;
  final bool cancelledReturn;
  final VoidCallback refresh;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final paid = order.status == 'paid';
    final retryable =
        order.method == 'online' &&
        const {'pending_payment', 'failed', 'cancelled'}.contains(order.status);
    final title = switch (order.status) {
      'paid' => 'Payment verified',
      'failed' => 'Payment failed',
      'cancelled' => 'Payment cancelled',
      'refunded' => 'Payment refunded',
      'created' || 'pending_payment' || 'pending_verification' =>
        order.isBank ? 'Awaiting verification' : 'Checking your payment',
      _ => 'Payment status unavailable',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          paid ? Icons.verified_user_outlined : Icons.shield_outlined,
          size: 72,
          color: paid ? cs.primary : cs.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: tt.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Chip(
            label: Text(
              order.isOpen ? 'Verification in progress' : order.statusLabel,
            ),
          ),
        ),
        if (cancelledReturn && order.isOpen) ...[
          const SizedBox(height: AppSpacing.md),
          const Text(
            'You returned from checkout without payment confirmation. Check the current status before trying again.',
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transaction Details', style: tt.titleLarge),
                const SizedBox(height: AppSpacing.md),
                Text(order.title, style: tt.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text('Order #${order.number}'),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  order.isBank ? 'Bank Transfer' : 'PayHere · Online Payment',
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(order.formattedAmount, style: tt.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(order.statusLabel),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Your course unlocks only after payment is independently verified and your enrollment is activated. Avoid starting another payment while verification is pending.',
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(label: 'Refresh Payment Status', onPressed: refresh),
        if (retryable) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label:
                cancelledReturn ||
                    order.status == 'failed' ||
                    order.status == 'cancelled'
                ? 'Try Again'
                : 'Continue Payment',
            variant: ButtonVariant.outlined,
            // Checkout re-reads the open order and resumes only payable orders.
            onPressed: () => context.go(
              RouteNames.checkout.replaceFirst(
                ':courseId',
                Uri.encodeComponent(order.courseId),
              ),
            ),
          ),
        ],
        if (paid) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Check My Courses',
            variant: ButtonVariant.outlined,
            onPressed: () => context.go(RouteNames.myCourses),
          ),
        ],
        if (order.isBank && order.status == 'pending_payment') ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Bank Transfer Instructions',
            variant: ButtonVariant.outlined,
            onPressed: () => context.go(
              RouteNames.bankTransfer.replaceFirst(
                ':orderId',
                Uri.encodeComponent(order.id),
              ),
            ),
          ),
        ],
        if (order.isBank && order.isOpen) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'View Receipt Status',
            variant: ButtonVariant.outlined,
            onPressed: () => context.push(
              RouteNames.receiptStatus.replaceFirst(
                ':orderId',
                Uri.encodeComponent(order.id),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: () => context.go(
            RouteNames.courseDetail.replaceFirst(
              ':courseId',
              Uri.encodeComponent(order.courseId),
            ),
          ),
          child: const Text('View Course'),
        ),
      ],
    );
  }
}
