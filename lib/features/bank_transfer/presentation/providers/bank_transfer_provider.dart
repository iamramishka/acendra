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
    if (state.isLoading) {
      return;
    }
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
    if (!ref.mounted || ref.read(bankSessionIdentityProvider) != identity) {
      return;
    }
    state = result;
    if (identity != null) {
      ref.invalidate(receiptSubmissionRequestProvider((identity, orderId)));
    }
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
    if (state.isLoading) {
      return;
    }
    final identity = ref.read(bankSessionIdentityProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(bankTransferRepositoryProvider)
          .review(submissionId: submissionId, rejectionReason: rejectionReason),
    );
    if (!ref.mounted || ref.read(bankSessionIdentityProvider) != identity) {
      return;
    }
    state = result;
    if (!state.hasError) {
      if (identity != null) {
        ref.invalidate(financeQueueRequestProvider(identity));
      }
    }
  }

  void reset() => state = const AsyncData(null);
}

final bankReviewProvider = AsyncNotifierProvider<BankReviewNotifier, void>(
  BankReviewNotifier.new,
);
final receiptSubmissionRequestProvider = FutureProvider.autoDispose
    .family<ReceiptSubmission, (String, String)>((ref, key) async {
      final value = await ref
          .watch(bankTransferRepositoryProvider)
          .status(key.$2);
      if (!ref.mounted || ref.read(bankSessionIdentityProvider) != key.$1) {
        throw const BankTransferFailure(
          'Your session changed. Refresh transfer status.',
        );
      }
      return value;
    }, retry: (retryCount, error) => null);
final receiptSubmissionProvider =
    Provider.family<AsyncValue<ReceiptSubmission>, String>((ref, orderId) {
      final identity = ref.watch(bankSessionIdentityProvider);
      if (identity == null) {
        return AsyncError(
          const BankTransferFailure('Sign in to view transfer status.'),
          StackTrace.current,
        );
      }
      return ref.watch(receiptSubmissionRequestProvider((identity, orderId)));
    });
final financeQueueRequestProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, identity) async {
      final value = await ref.watch(bankTransferRepositoryProvider).queue();
      if (!ref.mounted || ref.read(bankSessionIdentityProvider) != identity) {
        throw const BankTransferFailure(
          'Your session changed. Refresh the finance queue.',
        );
      }
      return value;
    }, retry: (retryCount, error) => null);
final financeQueueProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((
  ref,
) {
  final identity = ref.watch(bankSessionIdentityProvider);
  if (identity == null) {
    return AsyncError(
      const BankTransferFailure(
        'Sign in with an authorized finance account and MFA.',
      ),
      StackTrace.current,
    );
  }
  return ref.watch(financeQueueRequestProvider(identity));
});
