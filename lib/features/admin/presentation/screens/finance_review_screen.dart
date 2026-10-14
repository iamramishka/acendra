import 'package:acendra/features/bank_transfer/data/bank_transfer_repository.dart';
import 'package:acendra/features/bank_transfer/presentation/providers/bank_transfer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FinanceReviewScreen extends ConsumerWidget {
  const FinanceReviewScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Finance Receipt Review'),
      actions: [
        IconButton(
          tooltip: 'Refresh queue',
          onPressed: () {
            final identity = ref.read(bankSessionIdentityProvider);
            if (identity != null) {
              ref.invalidate(financeQueueRequestProvider(identity));
            }
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ref
        .watch(financeQueueProvider)
        .when(
          skipLoadingOnReload: false,
          skipLoadingOnRefresh: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(
            child: Text(
              'Finance review is unavailable. Sign in with an authorized finance account and MFA, or try again later.',
            ),
          ),
          data: (items) => items.isEmpty
              ? const Center(child: Text('No receipts to review'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: items
                      .map(
                        (item) => _ReviewCard(
                          key: ValueKey((
                            item['submission_id'],
                            ref.watch(bankSessionWidgetKeyProvider),
                          )),
                          item: item,
                        ),
                      )
                      .toList(),
                ),
        ),
  );
}

class _ReviewCard extends ConsumerStatefulWidget {
  const _ReviewCard({super.key, required this.item});
  final Map<String, dynamic> item;
  @override
  ConsumerState<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<_ReviewCard> {
  final reason = TextEditingController();
  final fields = List.generate(5, (_) => TextEditingController());
  bool busy = false, confirmed = false, approve = false;
  String source = 'bank_portal';
  String? message;
  @override
  void dispose() {
    reason.dispose();
    for (final field in fields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> decide() async {
    if (busy) {
      return;
    }
    final identity = ref.read(bankSessionIdentityProvider);
    if (identity == null) {
      setState(
        () => message = 'Sign in with an authorized finance account and MFA.',
      );
      return;
    }
    final item = widget.item;
    if (approve &&
        (!confirmed || fields.any((field) => field.text.trim().isEmpty))) {
      setState(
        () => message =
            'Complete the independent bank-credit evidence and confirmation.',
      );
      return;
    }
    if (!approve && reason.text.trim().isEmpty) {
      setState(() => message = 'Enter a student-safe rejection reason.');
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await ref
          .read(bankTransferRepositoryProvider)
          .review(
            submissionId: item['submission_id'] as String,
            rejectionReason: approve ? null : reason.text.trim(),
            verifiedCredit: approve
                ? {
                    'bank_credit_confirmed': true,
                    'destination_account_id': fields[0].text.trim(),
                    'bank_transaction_id': fields[1].text.trim(),
                    'amount_minor': fields[2].text.trim(),
                    'currency': 'LKR',
                    'settled_at': fields[3].text.trim(),
                    'source': source,
                    'order_reference': fields[4].text.trim(),
                  }
                : null,
          );
      if (!mounted || ref.read(bankSessionIdentityProvider) != identity) {
        return;
      }
      ref.invalidate(financeQueueRequestProvider(identity));
      setState(() {
        message = 'Decision recorded by the server.';
        reason.clear();
      });
    } catch (_) {
      if (mounted && ref.read(bankSessionIdentityProvider) == identity) {
        setState(
          () => message =
              'The decision was not confirmed. Your inputs are preserved. Refresh before retrying.',
        );
      }
    } finally {
      if (mounted && ref.read(bankSessionIdentityProvider) == identity) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Destination account ID',
      'Independent bank transaction ID',
      'Exact amount in minor units',
      'Settled date and time (ISO 8601)',
      'Stored order reference',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.item['course_title'] as String),
            Text('Order ${widget.item['order_number']}'),
            Text(
              '${widget.item['currency']} ${widget.item['amount_minor']} minor units',
            ),
            const Text(
              'Verify settled funds in the business-controlled bank source. A receipt alone does not prove payment.',
            ),
            SwitchListTile(
              title: const Text('Approve with independent bank evidence'),
              value: approve,
              onChanged: busy
                  ? null
                  : (value) => setState(() => approve = value),
            ),
            if (approve) ...[
              for (var i = 0; i < labels.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: fields[i],
                    enabled: !busy,
                    decoration: InputDecoration(labelText: labels[i]),
                  ),
                ),
              DropdownButtonFormField<String>(
                initialValue: source,
                items: const [
                  DropdownMenuItem(
                    value: 'bank_portal',
                    child: Text('Bank portal'),
                  ),
                  DropdownMenuItem(
                    value: 'bank_statement',
                    child: Text('Bank statement'),
                  ),
                  DropdownMenuItem(
                    value: 'authenticated_bank_feed',
                    child: Text('Authenticated bank feed'),
                  ),
                ],
                onChanged: busy
                    ? null
                    : (value) => setState(() => source = value!),
              ),
              CheckboxListTile(
                title: const Text(
                  'I independently verified this settled credit in the bank source',
                ),
                value: confirmed,
                onChanged: busy
                    ? null
                    : (value) => setState(() => confirmed = value ?? false),
              ),
            ] else
              TextField(
                controller: reason,
                enabled: !busy,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Student-safe rejection reason',
                ),
              ),
            if (message != null) Text(message!),
            FilledButton(
              onPressed: busy ? null : decide,
              child: Text(
                busy
                    ? 'Recording…'
                    : approve
                    ? 'Record approval'
                    : 'Record rejection',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
