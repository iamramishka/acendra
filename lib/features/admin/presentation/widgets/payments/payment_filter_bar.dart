import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:acendra/features/admin/domain/entities/payment_record.dart';
import 'package:acendra/features/admin/presentation/providers/admin_payments_provider.dart';
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

  void _onStatusTap(PaymentStatus? status) {
    widget.onFilterChanged(
      widget.filter.copyWith(
        status: status,
        clearStatus: status == null,
      ),
    );
  }

  void _onMethodTap(PaymentMethod? method) {
    widget.onFilterChanged(
      widget.filter.copyWith(
        method: method,
        clearMethod: method == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Search',
          hint: 'Email or order ID',
          controller: _searchController,
          prefixIcon: const Icon(Icons.search_outlined, size: 20),
          onChanged: (value) {
            widget.onFilterChanged(
              widget.filter.copyWith(searchQuery: value),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Status', style: tt.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: widget.filter.status == null,
                onTap: () => _onStatusTap(null),
                cs: cs,
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterChip(
                label: 'Pending',
                selected: widget.filter.status == PaymentStatus.pending,
                onTap: () => _onStatusTap(PaymentStatus.pending),
                cs: cs,
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterChip(
                label: 'Approved',
                selected: widget.filter.status == PaymentStatus.approved,
                onTap: () => _onStatusTap(PaymentStatus.approved),
                cs: cs,
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterChip(
                label: 'Rejected',
                selected: widget.filter.status == PaymentStatus.rejected,
                onTap: () => _onStatusTap(PaymentStatus.rejected),
                cs: cs,
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterChip(
                label: 'Processing',
                selected: widget.filter.status == PaymentStatus.processing,
                onTap: () => _onStatusTap(PaymentStatus.processing),
                cs: cs,
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
              _FilterChip(
                label: 'All',
                selected: widget.filter.method == null,
                onTap: () => _onMethodTap(null),
                cs: cs,
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterChip(
                label: 'Stripe',
                selected: widget.filter.method == PaymentMethod.stripe,
                onTap: () => _onMethodTap(PaymentMethod.stripe),
                cs: cs,
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterChip(
                label: 'Bank Transfer',
                selected: widget.filter.method == PaymentMethod.bankTransfer,
                onTap: () => _onMethodTap(PaymentMethod.bankTransfer),
                cs: cs,
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterChip(
                label: 'Admin Grant',
                selected: widget.filter.method == PaymentMethod.adminGrant,
                onTap: () => _onMethodTap(PaymentMethod.adminGrant),
                cs: cs,
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
