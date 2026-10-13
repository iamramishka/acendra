import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/layout/responsive_container.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/bank_transfer_details.dart';
import '../widgets/bank_transfer_instructions_card.dart';

/// Screen that displays bank transfer instructions for a specific checkout order.
///
/// [courseId] and [orderId] are used to load the relevant order details.
///
/// TODO(CSA-107): Replace mock data with a real Riverpod provider that reads
/// the order from Supabase and exposes a [BankTransferDetails] instance.
/// The provider should accept [orderId] and [courseId] as parameters.
/// Enrollment is granted only after finance-role approval on the backend —
/// never trust client-supplied confirmation here.
class BankTransferScreen extends StatelessWidget {
  const BankTransferScreen({
    super.key,
    required this.courseId,
    required this.orderId,
  });

  final String courseId;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    // TODO(CSA-107): Remove mock data and wire to real provider.
    final mockDetails = BankTransferDetails(
      bankName: 'Bank of Ceylon',
      accountName: 'Acendra (Pvt) Ltd',
      accountNumber: '0123456789',
      branch: 'Colombo 03',
      amount: 12500.00,
      currency: 'LKR',
      referenceId: orderId.isNotEmpty ? orderId : 'ORD-MOCK-00001',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Payment'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: ResponsiveContainer(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: BankTransferInstructionsCard(
              details: mockDetails,
              // TODO(CSA-107): Wire to a provider action that records the
              // student's self-reported transfer and navigates to a
              // "pending approval" confirmation screen.
              onConfirmTransfer: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Transfer noted. We will review your receipt shortly.',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
