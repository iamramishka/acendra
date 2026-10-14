import 'dart:async';
import 'package:acendra/features/bank_transfer/data/bank_transfer_repository.dart';
import 'package:acendra/features/bank_transfer/domain/entities/receipt_submission.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReceiptUploadNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;
  Future<void> upload({
    required String orderId,
    required String fileName,
    required List<int> bytes,
    required String idempotencyKey,
  }) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(bankTransferRepositoryProvider)
          .uploadReceipt(
            orderId: orderId,
            fileName: fileName,
            bytes: bytes,
            idempotencyKey: idempotencyKey,
          ),
    );
    ref.invalidate(receiptSubmissionProvider(orderId));
  }

  void reset() => state = const AsyncData(null);
}

final receiptUploadProvider =
    AsyncNotifierProvider<ReceiptUploadNotifier, void>(
      ReceiptUploadNotifier.new,
    );

class BankReviewNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;
  Future<void> approve({
    required String submissionId,
    required String verifiedCredit,
  }) async {
    // Legacy callers cannot approve with incomplete/free-text evidence.
    state = AsyncError(
      const BankTransferFailure(
        'Complete independently verified bank-credit evidence is required.',
      ),
      StackTrace.current,
    );
  }

  Future<void> reject({
    required String submissionId,
    required String rejectionReason,
  }) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(bankTransferRepositoryProvider)
          .review(submissionId: submissionId, rejectionReason: rejectionReason),
    );
    if (!state.hasError) ref.invalidate(financeQueueProvider);
  }

  void reset() => state = const AsyncData(null);
}

final bankReviewProvider = AsyncNotifierProvider<BankReviewNotifier, void>(
  BankReviewNotifier.new,
);
final receiptSubmissionProvider =
    FutureProvider.family<ReceiptSubmission, String>(
      (ref, orderId) =>
          ref.watch(bankTransferRepositoryProvider).status(orderId),
    );
final financeQueueProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.watch(bankTransferRepositoryProvider).queue(),
);
