import 'dart:async';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/bank_transfer/data/bank_transfer_repository.dart';
import 'package:acendra/features/bank_transfer/domain/entities/receipt_submission.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Token is used only for identity equality; never exposed in widget keys or text.
final bankSessionIdentityProvider = Provider<String?>((ref) {
  return ref.watch(currentSessionProvider)?.accessToken;
});
final bankSessionWidgetKeyProvider = Provider<Object>((ref) {
  ref.watch(bankSessionIdentityProvider);
  return Object();
});

class ReceiptUploadNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    ref.watch(bankSessionIdentityProvider);
    return null;
  }

  Future<void> upload({
    required String orderId,
    required String fileName,
    required List<int> bytes,
    required String idempotencyKey,
  }) async {
    if (state.isLoading) return;
    final identity = ref.read(bankSessionIdentityProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(bankTransferRepositoryProvider)
          .uploadReceipt(
            orderId: orderId,
            fileName: fileName,
            bytes: bytes,
            idempotencyKey: idempotencyKey,
          ),
    );
    if (!ref.mounted || ref.read(bankSessionIdentityProvider) != identity)
      return;
    state = result;
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
  FutureOr<void> build() {
    ref.watch(bankSessionIdentityProvider);
    return null;
  }

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
    final identity = ref.read(bankSessionIdentityProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(bankTransferRepositoryProvider)
          .review(submissionId: submissionId, rejectionReason: rejectionReason),
    );
    if (!ref.mounted || ref.read(bankSessionIdentityProvider) != identity)
      return;
    state = result;
    if (!state.hasError) ref.invalidate(financeQueueProvider);
  }

  void reset() => state = const AsyncData(null);
}

final bankReviewProvider = AsyncNotifierProvider<BankReviewNotifier, void>(
  BankReviewNotifier.new,
);
final receiptSubmissionProvider =
    FutureProvider.family<ReceiptSubmission, String>((ref, orderId) async {
      final identity = ref.watch(bankSessionIdentityProvider);
      if (identity == null)
        throw const BankTransferFailure('Sign in to view transfer status.');
      final value = await ref
          .watch(bankTransferRepositoryProvider)
          .status(orderId);
      if (!ref.mounted || ref.read(bankSessionIdentityProvider) != identity) {
        throw const BankTransferFailure(
          'Your session changed. Refresh transfer status.',
        );
      }
      return value;
    });
final financeQueueProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final identity = ref.watch(bankSessionIdentityProvider);
  if (identity == null)
    throw const BankTransferFailure(
      'Sign in with an authorized finance account and MFA.',
    );
  final value = await ref.watch(bankTransferRepositoryProvider).queue();
  if (!ref.mounted || ref.read(bankSessionIdentityProvider) != identity) {
    throw const BankTransferFailure(
      'Your session changed. Refresh the finance queue.',
    );
  }
  return value;
});
