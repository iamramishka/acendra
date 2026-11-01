import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/bank_transfer/data/bank_transfer_repository.dart';
import 'package:acendra/features/bank_transfer/domain/entities/receipt_submission.dart';
import 'package:acendra/features/bank_transfer/presentation/providers/bank_transfer_provider.dart';
import 'package:acendra/features/bank_transfer/presentation/screens/receipt_status_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Repository implements BankTransferRepository {
  ReceiptStatus value = ReceiptStatus.awaitingReceipt;
  int reads = 0;
  @override
  Future<ReceiptSubmission> status(String orderId) async {
    reads++;
    return ReceiptSubmission(
      orderId: orderId,
      orderNumber: 'AC-1',
      courseTitle: 'Synthetic Course',
      status: value,
      rejectionReason: value == ReceiptStatus.rejected
          ? 'Unreadable reference'
          : null,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> queue() => throw UnimplementedError();
  @override
  Future<void> review({
    required String submissionId,
    String? rejectionReason,
    Map<String, dynamic>? verifiedCredit,
  }) => throw UnimplementedError();
  @override
  Future<void> uploadReceipt({
    required String orderId,
    required String fileName,
    required List<int> bytes,
    required String idempotencyKey,
  }) => throw UnimplementedError();
}

void main() {
  for (final rejected in [false, true]) {
    testWidgets(
      'missing/rejected receipt chooses the correct upload path: rejected=$rejected',
      (tester) async {
        final repo = _Repository()
          ..value = rejected
              ? ReceiptStatus.rejected
              : ReceiptStatus.awaitingReceipt;
        final router = GoRouter(
          initialLocation: '/status',
          routes: [
            GoRoute(
              path: '/status',
              builder: (_, _) => const ReceiptStatusScreen(orderId: 'order'),
            ),
            GoRoute(
              path: '/bank-transfer/:orderId',
              builder: (_, _) =>
                  const Scaffold(body: Text('Unified instructions/upload')),
            ),
            GoRoute(
              path: '/bank-transfer/:orderId/resubmit',
              builder: (_, _) =>
                  const Scaffold(body: Text('Rejected receipt resubmission')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bankSessionIdentityProvider.overrideWithValue(
                'synthetic-session',
              ),
              bankTransferRepositoryProvider.overrideWithValue(repo),
            ],
            child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final action = find.text(
          rejected ? 'Submit New Receipt' : 'Upload Receipt',
        );
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(
          find.text(
            rejected
                ? 'Rejected receipt resubmission'
                : 'Unified instructions/upload',
          ),
          findsOneWidget,
        );
      },
    );
  }
  testWidgets('refresh reads current backend status and updates the timeline', (
    tester,
  ) async {
    final repo = _Repository()..value = ReceiptStatus.submitted;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bankSessionIdentityProvider.overrideWithValue('synthetic-session'),
          bankTransferRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ReceiptStatusScreen(orderId: 'order'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Awaiting Verification'), findsOneWidget);
    expect(repo.reads, 1);
    repo.value = ReceiptStatus.approved;
    await tester.tap(find.byTooltip('Refresh Payment Status'));
    await tester.pumpAndSettle();
    expect(repo.reads, 2);
    expect(find.text('Payment Verified'), findsOneWidget);
    expect(find.text('Transfer confirmed'), findsOneWidget);
  });
}
