import 'dart:async';

import 'package:acendra/features/admin/data/repositories/admin_payment_repository.dart';
import 'package:acendra/features/admin/domain/entities/payment_record.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminPaymentRepositoryProvider = Provider<AdminPaymentRepository>(
  (_) => StubAdminPaymentRepository(),
);

/// Unfiltered counts shared by the dashboard and payments screen.
final adminPaymentCountsProvider = FutureProvider<Map<PaymentStatus, int>>((
  ref,
) async {
  final repo = ref.watch(adminPaymentRepositoryProvider);
  final counts = await Future.wait(
    PaymentStatus.values.map((status) => repo.countPayments(status: status)),
  );
  return Map.fromIterables(PaymentStatus.values, counts);
});

class AdminPaymentsFilter {
  const AdminPaymentsFilter({
    this.status,
    this.method,
    this.searchQuery,
    this.fromDate,
    this.toDate,
  });

  final PaymentStatus? status;
  final PaymentMethod? method;
  final String? searchQuery;
  final DateTime? fromDate;
  final DateTime? toDate;

  AdminPaymentsFilter copyWith({
    PaymentStatus? status,
    bool clearStatus = false,
    PaymentMethod? method,
    bool clearMethod = false,
    String? searchQuery,
    DateTime? fromDate,
    bool clearFromDate = false,
    DateTime? toDate,
    bool clearToDate = false,
  }) {
    return AdminPaymentsFilter(
      status: clearStatus ? null : (status ?? this.status),
      method: clearMethod ? null : (method ?? this.method),
      searchQuery: searchQuery ?? this.searchQuery,
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
    );
  }
}

class AdminPaymentsState {
  const AdminPaymentsState({
    this.records = const [],
    this.isLoading = false,
    this.error,
    this.filter = const AdminPaymentsFilter(),
    this.page = 0,
    this.hasMore = false,
    this.pendingCount = 0,
    this.approvedCount = 0,
    this.rejectedCount = 0,
    this.processingCount = 0,
  });

  final List<PaymentRecord> records;
  final bool isLoading;
  final Object? error;
  final AdminPaymentsFilter filter;
  final int page;
  final bool hasMore;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final int processingCount;
  int get totalCount =>
      pendingCount + processingCount + approvedCount + rejectedCount;

  AdminPaymentsState copyWith({
    List<PaymentRecord>? records,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    AdminPaymentsFilter? filter,
    int? page,
    bool? hasMore,
    int? pendingCount,
    int? approvedCount,
    int? rejectedCount,
    int? processingCount,
  }) {
    return AdminPaymentsState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filter: filter ?? this.filter,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      pendingCount: pendingCount ?? this.pendingCount,
      approvedCount: approvedCount ?? this.approvedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
      processingCount: processingCount ?? this.processingCount,
    );
  }
}

class AdminPaymentsNotifier extends AsyncNotifier<AdminPaymentsState> {
  static const _pageSize = 20;

  @override
  FutureOr<AdminPaymentsState> build() async {
    return _load(const AdminPaymentsFilter(), page: 0, existing: const []);
  }

  Future<AdminPaymentsState> _load(
    AdminPaymentsFilter filter, {
    required int page,
    required List<PaymentRecord> existing,
  }) async {
    final repo = ref.read(adminPaymentRepositoryProvider);
    final results = await repo.listPayments(
      status: filter.status,
      method: filter.method,
      searchQuery: filter.searchQuery,
      fromDate: filter.fromDate,
      toDate: filter.toDate,
      page: page,
      pageSize: _pageSize,
    );

    final counts = await ref.read(adminPaymentCountsProvider.future);

    return AdminPaymentsState(
      records: [...existing, ...results],
      isLoading: false,
      filter: filter,
      page: page,
      hasMore: results.length == _pageSize,
      pendingCount: counts[PaymentStatus.pending]!,
      approvedCount: counts[PaymentStatus.approved]!,
      rejectedCount: counts[PaymentStatus.rejected]!,
      processingCount: counts[PaymentStatus.processing]!,
    );
  }

  Future<void> applyFilter(AdminPaymentsFilter filter) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _load(filter, page: 0, existing: const []),
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoading) return;
    state = AsyncData(current.copyWith(isLoading: true));
    final next = await AsyncValue.guard(
      () => _load(
        current.filter,
        page: current.page + 1,
        existing: current.records,
      ),
    );
    state = next;
  }

  Future<void> refresh() async {
    ref.invalidate(adminPaymentCountsProvider);
    final current = state.asData?.value;
    final filter = current?.filter ?? const AdminPaymentsFilter();
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _load(filter, page: 0, existing: const []),
    );
  }
}

final adminPaymentsProvider =
    AsyncNotifierProvider<AdminPaymentsNotifier, AdminPaymentsState>(
      AdminPaymentsNotifier.new,
    );

// Provider for receipt review history (approved + rejected bank transfers).
final receiptHistoryProvider = FutureProvider.autoDispose
    .family<List<PaymentRecord>, AdminPaymentsFilter>((ref, filter) async {
      // TODO: Replace with Supabase query filtering processed bank transfer receipts.
      final repo = ref.read(adminPaymentRepositoryProvider);
      final all = await repo.listPayments(
        method: PaymentMethod.bankTransfer,
        status: filter.status,
        searchQuery: filter.searchQuery,
        fromDate: filter.fromDate,
        toDate: filter.toDate,
        pageSize: 100,
      );
      final reviewed =
          all
              .where(
                (r) =>
                    r.status == PaymentStatus.approved ||
                    r.status == PaymentStatus.rejected,
              )
              .toList()
            ..sort((a, b) {
              final aTime = a.processedAt ?? a.createdAt;
              final bTime = b.processedAt ?? b.createdAt;
              return bTime.compareTo(aTime);
            });
      return reviewed;
    });
