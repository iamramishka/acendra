import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:acendra/features/admin/domain/entities/payment_record.dart';
import 'package:acendra/features/admin/presentation/providers/admin_payments_provider.dart';
import 'package:acendra/features/admin/presentation/widgets/admin_filter_chip.dart';
import 'package:flutter/material.dart';

class PaymentFilterBar extends StatefulWidget {
  const PaymentFilterBar({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  final AdminPaymentsFilter filter;
  final ValueChanged<AdminPaymentsFilter> onFilterChanged;

  @override
  State<PaymentFilterBar> createState() => _PaymentFilterBarState();
}

class _PaymentFilterBarState extends State<PaymentFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.filter.searchQuery ?? '',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PaymentFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the field in sync when filters are cleared elsewhere (for example
    // the empty-state 'Clear filters' action).
    if ((widget.filter.searchQuery ?? '').isEmpty &&
        _searchController.text.isNotEmpty) {
      _searchController.clear();
    }
  }

  void _onStatusTap(PaymentStatus? status) {
    widget.onFilterChanged(
      widget.filter.copyWith(status: status, clearStatus: status == null),
    );
  }

  void _onMethodTap(PaymentMethod? method) {
    widget.onFilterChanged(
      widget.filter.copyWith(method: method, clearMethod: method == null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Search',
          hint: 'Order number starts with',
          controller: _searchController,
          prefixIcon: const Icon(Icons.search_outlined, size: 20),
          onChanged: (value) {
            widget.onFilterChanged(widget.filter.copyWith(searchQuery: value));
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Status', style: tt.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              AdminFilterChip(
                label: 'All',
                selected: widget.filter.status == null,
                onTap: () => _onStatusTap(null),
              ),
              const SizedBox(width: AppSpacing.sm),
              AdminFilterChip(
                label: 'Pending',
                selected: widget.filter.status == PaymentStatus.pending,
                onTap: () => _onStatusTap(PaymentStatus.pending),
              ),
              const SizedBox(width: AppSpacing.sm),
              AdminFilterChip(
                label: 'Approved',
                selected: widget.filter.status == PaymentStatus.approved,
                onTap: () => _onStatusTap(PaymentStatus.approved),
              ),
              const SizedBox(width: AppSpacing.sm),
              AdminFilterChip(
                label: 'Rejected',
                selected: widget.filter.status == PaymentStatus.rejected,
                onTap: () => _onStatusTap(PaymentStatus.rejected),
              ),
              const SizedBox(width: AppSpacing.sm),
              AdminFilterChip(
                label: 'Processing',
                selected: widget.filter.status == PaymentStatus.processing,
                onTap: () => _onStatusTap(PaymentStatus.processing),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Payment Method', style: tt.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              AdminFilterChip(
                label: 'All',
                selected: widget.filter.method == null,
                onTap: () => _onMethodTap(null),
              ),
              const SizedBox(width: AppSpacing.sm),
              AdminFilterChip(
                label: 'Online',
                selected: widget.filter.method == PaymentMethod.online,
                onTap: () => _onMethodTap(PaymentMethod.online),
              ),
              const SizedBox(width: AppSpacing.sm),
              AdminFilterChip(
                label: 'Bank Transfer',
                selected: widget.filter.method == PaymentMethod.bankTransfer,
                onTap: () => _onMethodTap(PaymentMethod.bankTransfer),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'From date',
                hint: 'YYYY-MM-DD',
                enabled: false,
                suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                // TODO: Integrate date picker
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                label: 'To date',
                hint: 'YYYY-MM-DD',
                enabled: false,
                suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                // TODO: Integrate date picker
              ),
            ),
          ],
        ),
      ],
    );
  }
}
