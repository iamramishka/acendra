import 'dart:async';

import 'package:acendra/features/admin/data/repositories/admin_payment_repository.dart';
import 'package:acendra/features/admin/data/repositories/supabase_admin_payment_repository.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/admin/domain/entities/payment_record.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final adminPaymentRepositoryProvider = Provider<AdminPaymentRepository>((ref) {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    return const UnavailableAdminPaymentRepository();
  }
  return SupabaseAdminPaymentRepository(Supabase.instance.client);
});

/// Unfiltered counts shared by the dashboard and payments screen.
/// Uses a single atomic query to avoid count skew across statuses.
final adminPaymentCountsProvider = FutureProvider<Map<PaymentStatus, int>>((
  ref,
) async {
  final repo = ref.watch(adminPaymentRepositoryProvider);
  return repo.countAllStatuses();
}, retry: (retryCount, error) => null);

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
  int _generation = 0;

  @override
  FutureOr<AdminPaymentsState> build() async {
    ref.watch(adminPaymentRepositoryProvider);
    _generation++;
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
      records: [
        ...existing,
        ...results.where(
          (row) => !existing.any((previous) => previous.id == row.id),
        ),
      ],
      isLoading: false,
      filter: filter,
      page: page,
      hasMore: repo is SupabaseAdminPaymentRepository
          ? repo.hasMore(
              status: filter.status,
              method: filter.method,
              searchQuery: filter.searchQuery,
              fromDate: filter.fromDate,
              toDate: filter.toDate,
              page: page,
              pageSize: _pageSize,
            )
          : results.length == _pageSize,
      pendingCount: counts[PaymentStatus.pending]!,
      approvedCount: counts[PaymentStatus.approved]!,
      rejectedCount: counts[PaymentStatus.rejected]!,
      processingCount: counts[PaymentStatus.processing]!,
    );
  }

  Future<void> applyFilter(AdminPaymentsFilter filter) async {
    final generation = ++_generation;
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => _load(filter, page: 0, existing: const []),
    );
    if (ref.mounted && generation == _generation) state = next;
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoading) return;
    final generation = ++_generation;
    state = AsyncData(current.copyWith(isLoading: true));
    final next = await AsyncValue.guard(
      () => _load(
        current.filter,
        page: current.page + 1,
        existing: current.records,
      ),
    );
    if (ref.mounted && generation == _generation) state = next;
  }

  Future<void> refresh() async {
    ref.invalidate(adminPaymentCountsProvider);
    final current = state.asData?.value;
    final filter = current?.filter ?? const AdminPaymentsFilter();
    await applyFilter(filter);
  }
}

final adminPaymentsProvider =
    AsyncNotifierProvider<AdminPaymentsNotifier, AdminPaymentsState>(
      AdminPaymentsNotifier.new,
      retry: (retryCount, error) => null,
    );

// Provider for receipt review history (approved + rejected bank transfers).
final receiptHistoryProvider = FutureProvider.autoDispose
    .family<List<PaymentRecord>, AdminPaymentsFilter>((ref, filter) async {
      final repo = ref.watch(adminPaymentRepositoryProvider);
      // The order-status projection omits review decisions, reviewers and
      // rejection timestamps. It cannot establish a receipt audit history.
      if (repo is SupabaseAdminPaymentRepository) {
        throw const PaymentReportingUnavailable();
      }
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
    }, retry: (retryCount, error) => null);
