import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/features/admin/domain/entities/receipt_review_item.dart';
import 'package:acendra/features/admin/presentation/widgets/receipt_review_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

// ---------------------------------------------------------------------------
// Filter state provider
// ---------------------------------------------------------------------------

/// Active filter for the finance review list.
enum _ReviewFilter { all, pending, approved, rejected }

final _reviewFilterProvider =
    StateProvider<_ReviewFilter>((_) => _ReviewFilter.all);

/// Tracks which receipt IDs are currently being processed (approve/reject).
final _processingProvider = StateProvider<Set<String>>((_) => {});

// ---------------------------------------------------------------------------
// Mock data provider
// ---------------------------------------------------------------------------

// TODO(CSA-111): Replace this mock provider with a real Supabase provider
// that fetches bank transfer receipts from the database.
// Security note: Receipt file access must use signed URLs from the trusted
// backend. Never expose permanent public storage links.
final _receiptListProvider =
    StateProvider<List<ReceiptReviewItem>>((_) => _mockReceipts);

final _mockReceipts = [
  ReceiptReviewItem(
    id: 'rec-001',
    orderId: 'ord-001',
    studentId: 'stu-001',
    studentEmail: 'alice@example.com',
    courseTitle: 'Advanced Flutter Development',
    amount: 149.99,
    currency: 'USD',
    submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
    status: ReceiptStatus.pending,
    receiptStoragePath: 'receipts/ord-001/bank_receipt.pdf',
  ),
  ReceiptReviewItem(
    id: 'rec-002',
    orderId: 'ord-002',
    studentId: 'stu-002',
    studentEmail: 'bob@example.com',
    courseTitle: 'Supabase Backend Masterclass',
    amount: 99.00,
    currency: 'USD',
    submittedAt: DateTime.now().subtract(const Duration(days: 1)),
    status: ReceiptStatus.approved,
    receiptStoragePath: 'receipts/ord-002/bank_receipt.jpg',
  ),
  ReceiptReviewItem(
    id: 'rec-003',
    orderId: 'ord-003',
    studentId: 'stu-003',
    studentEmail: 'carol@example.com',
    courseTitle: 'UI/UX Design Fundamentals',
    amount: 79.00,
    currency: 'USD',
    submittedAt: DateTime.now().subtract(const Duration(days: 3)),
    status: ReceiptStatus.rejected,
    rejectionReason:
        'Receipt image is illegible. Please resubmit a clearer copy.',
    receiptStoragePath: 'receipts/ord-003/bank_receipt.png',
  ),
  ReceiptReviewItem(
    id: 'rec-004',
    orderId: 'ord-004',
    studentId: 'stu-004',
    studentEmail: 'david@example.com',
    courseTitle: 'Advanced Flutter Development',
    amount: 149.99,
    currency: 'USD',
    submittedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    status: ReceiptStatus.pending,
    receiptStoragePath: 'receipts/ord-004/bank_receipt.pdf',
  ),
];

// ---------------------------------------------------------------------------
// Finance Review Screen
// ---------------------------------------------------------------------------

/// Admin screen that allows finance staff to review submitted bank transfer
/// receipts and approve or reject them.
///
/// Security note: Receipt file access must use signed URLs from the trusted
/// backend. Never expose permanent public storage links.
class FinanceReviewScreen extends ConsumerWidget {
  const FinanceReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_reviewFilterProvider);
    final allReceipts = ref.watch(_receiptListProvider);
    final processing = ref.watch(_processingProvider);

    final filteredReceipts = switch (filter) {
      _ReviewFilter.all => allReceipts,
      _ReviewFilter.pending =>
        allReceipts.where((r) => r.status == ReceiptStatus.pending).toList(),
      _ReviewFilter.approved =>
        allReceipts.where((r) => r.status == ReceiptStatus.approved).toList(),
      _ReviewFilter.rejected =>
        allReceipts.where((r) => r.status == ReceiptStatus.rejected).toList(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Receipt Review'),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter chips
          _FilterRow(
            selected: filter,
            onSelected: (f) =>
                ref.read(_reviewFilterProvider.notifier).state = f,
            counts: _buildCounts(allReceipts),
          ),
          // List
          Expanded(
            child: filteredReceipts.isEmpty
                ? const AppEmptyState(message: 'No receipts to review')
                : _ReceiptList(
                    receipts: filteredReceipts,
                    processing: processing,
                    onApprove: (item) =>
                        _handleApprove(context, ref, item),
                    onReject: (item) =>
                        _handleReject(context, ref, item),
                    onViewReceipt: (item) =>
                        _handleViewReceipt(context, item),
                  ),
          ),
        ],
      ),
    );
  }

  Map<_ReviewFilter, int> _buildCounts(List<ReceiptReviewItem> all) {
    return {
      _ReviewFilter.all: all.length,
      _ReviewFilter.pending:
          all.where((r) => r.status == ReceiptStatus.pending).length,
      _ReviewFilter.approved:
          all.where((r) => r.status == ReceiptStatus.approved).length,
      _ReviewFilter.rejected:
          all.where((r) => r.status == ReceiptStatus.rejected).length,
    };
  }

  Future<void> _handleApprove(
    BuildContext context,
    WidgetRef ref,
    ReceiptReviewItem item,
  ) async {
    // Mark as processing
    ref.read(_processingProvider.notifier).update(
          (s) => <String>{...s, item.id},
        );

    // TODO(CSA-111): Call the Supabase Edge Function / RPC to approve the
    // bank transfer. Only the trusted backend may grant course enrollment.
    await Future<void>.delayed(const Duration(milliseconds: 800));

    // Update local mock state
    ref.read(_receiptListProvider.notifier).update(
          (list) => list
              .map(
                (r) => r.id == item.id
                    ? r.copyWith(status: ReceiptStatus.approved)
                    : r,
              )
              .toList(),
        );

    ref.read(_processingProvider.notifier).update(
          (s) => s.where((id) => id != item.id).toSet(),
        );

    if (context.mounted) {
      AppSnackbar.show(context, 'Receipt approved successfully.');
    }
  }

  Future<void> _handleReject(
    BuildContext context,
    WidgetRef ref,
    ReceiptReviewItem item,
  ) async {
    // Mark as processing
    ref.read(_processingProvider.notifier).update(
          (s) => <String>{...s, item.id},
        );

    // TODO(CSA-111): Call the Supabase Edge Function / RPC to reject the
    // bank transfer with the provided rejection reason.
    await Future<void>.delayed(const Duration(milliseconds: 800));

    // Update local mock state (rejection reason captured in tile dialog)
    ref.read(_receiptListProvider.notifier).update(
          (list) => list
              .map(
                (r) => r.id == item.id
                    ? r.copyWith(
                        status: ReceiptStatus.rejected,
                        rejectionReason: 'Rejected by finance officer.',
                      )
                    : r,
              )
              .toList(),
        );

    ref.read(_processingProvider.notifier).update(
          (s) => s.where((id) => id != item.id).toSet(),
        );

    if (context.mounted) {
      AppSnackbar.show(context, 'Receipt rejected.');
    }
  }

  void _handleViewReceipt(BuildContext context, ReceiptReviewItem item) {
    // TODO(CSA-111): Fetch a short-lived signed URL from the trusted backend
    // and open it in a new tab or viewer.
    // Security note: Receipt file access must use signed URLs from the trusted
    // backend. Never expose permanent public storage links.
    AppSnackbar.show(
      context,
      'Opening receipt viewer… (signed URL fetch not yet implemented)',
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selected,
    required this.onSelected,
    required this.counts,
  });

  final _ReviewFilter selected;
  final ValueChanged<_ReviewFilter> onSelected;
  final Map<_ReviewFilter, int> counts;

  @override
  Widget build(BuildContext context) {
    const filters = _ReviewFilter.values;
    final labels = {
      _ReviewFilter.all: 'All',
      _ReviewFilter.pending: 'Pending',
      _ReviewFilter.approved: 'Approved',
      _ReviewFilter.rejected: 'Rejected',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: filters.map((f) {
          final label = '${labels[f]!} (${counts[f] ?? 0})';
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: Text(label),
              selected: selected == f,
              onSelected: (_) => onSelected(f),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReceiptList extends StatelessWidget {
  const _ReceiptList({
    required this.receipts,
    required this.processing,
    required this.onApprove,
    required this.onReject,
    required this.onViewReceipt,
  });

  final List<ReceiptReviewItem> receipts;
  final Set<String> processing;
  final ValueChanged<ReceiptReviewItem> onApprove;
  final ValueChanged<ReceiptReviewItem> onReject;
  final ValueChanged<ReceiptReviewItem> onViewReceipt;

  @override
  Widget build(BuildContext context) {
    // Responsive: constrain width on large screens (finance uses desktop/tablet)
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: receipts.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final item = receipts[index];
            return ReceiptReviewTile(
              item: item,
              isProcessing: processing.contains(item.id),
              onApprove: () => onApprove(item),
              onReject: () => onReject(item),
              onViewReceipt: () => onViewReceipt(item),
            );
          },
        ),
      ),
    );
  }
}
