import 'dart:async';
import 'package:acendra/features/bank_transfer/data/bank_transfer_repository.dart';
import 'package:acendra/features/bank_transfer/domain/entities/receipt_submission.dart';
import 'package:acendra/features/bank_transfer/presentation/providers/bank_transfer_provider.dart';
import 'package:acendra/features/bank_transfer/presentation/screens/finance_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class ControlledRepository implements BankTransferRepository {
  final completion = Completer<void>();
  int calls = 0;
  String? reason;
  @override
  Future<void> review({
    required String submissionId,
    String? rejectionReason,
    Map<String, dynamic>? verifiedCredit,
  }) {
    calls++;
    reason = rejectionReason;
    return completion.future;
  }

  @override
  Future<List<Map<String, dynamic>>> queue() async => [
    {
      'submission_id': 'submission',
      'course_title': 'Course',
      'order_number': 'ACD-1',
      'amount_minor': '50000',
      'currency': 'LKR',
    },
  ];
  @override
  Future<ReceiptSubmission> status(String orderId) =>
      throw UnimplementedError();
  @override
  Future<void> uploadReceipt({
    required String orderId,
    required String fileName,
    required List<int> bytes,
    required String idempotencyKey,
  }) => throw UnimplementedError();
}

void main() {
  testWidgets(
    'rejection failure preserves input and pending operation blocks duplicates',
    (tester) async {
      final repository = ControlledRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bankSessionIdentityProvider.overrideWithValue('test-session'),
            bankTransferRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: Scaffold(body: FinanceReviewScreen())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        '  Amount does not match.  ',
      );
      await tester.tap(find.text('Record rejection'));
      await tester.pump();
      expect(repository.calls, 1);
      expect(repository.reason, 'Amount does not match.');
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      // AppButton renders ElevatedButton; only the busy action button is disabled.
      expect(
        tester
            .widgetList<ElevatedButton>(find.byType(ElevatedButton))
            .where((b) => b.onPressed == null)
            .length,
        1,
      );
      repository.completion.completeError(Exception('Unavailable'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '  Amount does not match.  ',
      );
      expect(find.textContaining('inputs are preserved'), findsOneWidget);
      expect(find.text('Decision recorded by the server.'), findsNothing);
    },
  );
}
