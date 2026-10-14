import 'dart:async';
import 'package:acendra/features/admin/presentation/screens/finance_review_screen.dart';
import 'package:acendra/features/bank_transfer/data/bank_transfer_repository.dart';
import 'package:acendra/features/bank_transfer/domain/entities/receipt_submission.dart';
import 'package:acendra/features/bank_transfer/presentation/providers/bank_transfer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:flutter_test/flutter_test.dart';

final identity = StateProvider<String?>((ref) => 'session-a');
final rows = StateProvider<List<Map<String, dynamic>>>(
  (ref) => [item('a'), item('b')],
);
Map<String, dynamic> item(String id) => {
  'submission_id': id,
  'course_title': 'Course $id',
  'order_number': 'ACD-$id',
  'amount_minor': '50000',
  'currency': 'LKR',
};

class Repository implements BankTransferRepository {
  final decision = Completer<void>();
  final staleQueue = Completer<List<Map<String, dynamic>>>();
  int reads = 0;
  @override
  Future<List<Map<String, dynamic>>> queue() =>
      ++reads == 1 ? staleQueue.future : Future.value([item('new')]);
  @override
  Future<void> review({
    required String submissionId,
    String? rejectionReason,
    Map<String, dynamic>? verifiedCredit,
  }) => decision.future;
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
  test(
    'account switch discards late finance queue and signout clears it',
    () async {
      final repository = Repository();
      final container = ProviderContainer(
        overrides: [
          bankSessionIdentityProvider.overrideWith(
            (ref) => ref.watch(identity),
          ),
          bankTransferRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final listener = container.listen(financeQueueProvider, (_, _) {});
      addTearDown(listener.close);
      container.read(financeQueueProvider);
      // Flush provider construction before switching identity so the controlled
      // first request belongs to session-a, rather than the rebuilt session-b.
      await container.pump();
      expect(repository.reads, 1);
      container.read(identity.notifier).state = 'session-b';
      await container.pump();
      expect(
        (await container.read(
          financeQueueRequestProvider('session-b').future,
        )).single['submission_id'],
        'new',
      );
      repository.staleQueue.complete([item('old-private')]);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(financeQueueProvider).value!.single['submission_id'],
        'new',
      );
      container.read(identity.notifier).state = null;
      await container.pump();
      expect(
        container.read(financeQueueProvider).error,
        isA<BankTransferFailure>(),
      );
      expect(container.read(financeQueueProvider).value, isNull);
    },
  );
  testWidgets(
    'reordered queue never transfers entered evidence to another receipt',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          bankSessionIdentityProvider.overrideWith(
            (ref) => ref.watch(identity),
          ),
          financeQueueRequestProvider.overrideWith(
            (ref, _) async => ref.watch(rows),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: FinanceReviewScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'PRIVATE reason for a',
      );
      container.read(rows.notifier).state = [item('b'), item('a')];
      await tester.pumpAndSettle();
      final first = tester.widget<TextField>(find.byType(TextField).first);
      expect(first.controller!.text, isNot('PRIVATE reason for a'));
    },
  );
  testWidgets(
    'account switch clears evidence and suppresses late decision success',
    (tester) async {
      final repository = Repository();
      final container = ProviderContainer(
        overrides: [
          bankSessionIdentityProvider.overrideWith(
            (ref) => ref.watch(identity),
          ),
          financeQueueRequestProvider.overrideWith(
            (ref, _) async => [item('a')],
          ),
          bankTransferRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: FinanceReviewScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'PRIVATE old account reason',
      );
      await tester.tap(find.text('Record rejection'));
      await tester.pump();
      container.read(identity.notifier).state = 'session-b';
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      repository.decision.complete();
      await tester.pumpAndSettle();
      expect(find.text('Decision recorded by the server.'), findsNothing);
    },
  );
}
