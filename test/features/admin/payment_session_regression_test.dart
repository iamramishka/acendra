import 'dart:async';
import 'package:acendra/features/admin/data/repositories/admin_payment_repository.dart';
import 'package:acendra/features/admin/domain/entities/payment_record.dart';
import 'package:acendra/features/admin/presentation/providers/admin_payments_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';

final _account = StateProvider<String?>((_) => 'first');

class _Payments extends StubAdminPaymentRepository {
  _Payments(this.account);
  final String account;
  Completer<List<PaymentRecord>>? pending;
  @override
  Future<List<PaymentRecord>> listPayments({
    PaymentStatus? status,
    PaymentMethod? method,
    String? searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    int pageSize = 20,
  }) async {
    if (searchQuery == 'slow') return pending!.future;
    return [(await super.listPayments()).first.copyWith(studentEmail: account)];
  }
}

void main() {
  test('account change and logout discard payments and history', () async {
    final container = ProviderContainer(
      overrides: [
        adminPaymentRepositoryProvider.overrideWith((ref) {
          final account = ref.watch(_account);
          return account == null
              ? const UnavailableAdminPaymentRepository()
              : _Payments(account);
        }),
      ],
    );
    addTearDown(container.dispose);
    container.listen(adminPaymentsProvider, (_, _) {});
    final history = receiptHistoryProvider(const AdminPaymentsFilter());
    container.listen(history, (_, _) {});
    expect(
      (await container.read(
        adminPaymentsProvider.future,
      )).records.single.studentEmail,
      'first',
    );
    await container.read(history.future);
    container.read(_account.notifier).state = 'second';
    expect(
      (await container.read(
        adminPaymentsProvider.future,
      )).records.single.studentEmail,
      'second',
    );
    container.read(_account.notifier).state = null;
    await expectLater(
      container.read(adminPaymentsProvider.future),
      throwsA(isA<PaymentReportingUnavailable>()),
    );
    await expectLater(
      container.read(history.future),
      throwsA(isA<PaymentReportingUnavailable>()),
    );
    expect(container.read(adminPaymentsProvider).asData, isNull);
  });
  test('late filter response cannot overwrite a newer result', () async {
    final repo = _Payments('current')
      ..pending = Completer<List<PaymentRecord>>();
    final container = ProviderContainer(
      overrides: [adminPaymentRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container.read(adminPaymentsProvider.future);
    final notifier = container.read(adminPaymentsProvider.notifier);
    final slow = notifier.applyFilter(
      const AdminPaymentsFilter(searchQuery: 'slow'),
    );
    await notifier.applyFilter(const AdminPaymentsFilter(searchQuery: 'new'));
    repo.pending!.complete([]);
    await slow;
    expect(
      container.read(adminPaymentsProvider).requireValue.filter.searchQuery,
      'new',
    );
    expect(
      container.read(adminPaymentsProvider).requireValue.records,
      hasLength(1),
    );
  });
}
