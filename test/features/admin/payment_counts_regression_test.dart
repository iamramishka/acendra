import 'package:acendra/features/admin/domain/entities/payment_record.dart';
import 'package:acendra/features/admin/presentation/providers/admin_dashboard_provider.dart';
import 'package:acendra/features/admin/presentation/providers/admin_payments_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'all statuses account for every payment and dashboard pending agrees',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final payments = await container.read(adminPaymentsProvider.future);
      final dashboard = await container.read(adminDashboardProvider.future);
      expect(payments.records, hasLength(6));
      expect(payments.pendingCount, 2);
      expect(payments.processingCount, 1);
      expect(payments.approvedCount, 2);
      expect(payments.rejectedCount, 1);
      expect(payments.totalCount, payments.records.length);
      expect(dashboard.pendingPayments, payments.pendingCount);
      expect(
        dashboard.recentPendingPayments.map((p) => p.id).toSet(),
        payments.records
            .where((p) => p.status == PaymentStatus.pending)
            .map((p) => p.id)
            .toSet(),
      );
    },
  );

  test('filtered results retain clearly global status totals', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(adminPaymentsProvider.future);
    await container
        .read(adminPaymentsProvider.notifier)
        .applyFilter(
          const AdminPaymentsFilter(status: PaymentStatus.processing),
        );
    final filtered = await container.read(adminPaymentsProvider.future);
    expect(filtered.records, hasLength(1));
    expect(filtered.records.single.status, PaymentStatus.processing);
    expect(filtered.totalCount, 6);
    expect(filtered.processingCount, 1);
  });
}
