import 'dart:async';

import 'package:acendra/features/bank_transfer/domain/entities/receipt_submission.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Receipt upload notifier ───────────────────────────────────────────────────
// Backend is hard-disabled (503 RECEIPT_UPLOAD_UNAVAILABLE). This notifier
// holds UI state and surfaces the disabled error gracefully.

class ReceiptUploadNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> upload({
    required String orderId,
    required String fileName,
    required List<int> bytes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      throw const _FeatureUnavailableException(
        'Receipt upload is temporarily unavailable. Please contact support.',
      );
    });
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final receiptUploadProvider =
    AsyncNotifierProvider<ReceiptUploadNotifier, void>(
      ReceiptUploadNotifier.new,
    );

// ── Admin bank review notifier ────────────────────────────────────────────────
// Backend is hard-disabled (503 BANK_REVIEW_UNAVAILABLE).

class BankReviewNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> approve({
    required String submissionId,
    required String verifiedCredit,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      throw const _FeatureUnavailableException(
        'Bank review is temporarily unavailable.',
      );
    });
  }

  Future<void> reject({
    required String submissionId,
    required String rejectionReason,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      throw const _FeatureUnavailableException(
        'Bank review is temporarily unavailable.',
      );
    });
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final bankReviewProvider = AsyncNotifierProvider<BankReviewNotifier, void>(
  BankReviewNotifier.new,
);

// ── Stub submission status provider ──────────────────────────────────────────
// Real status will come from Supabase once backend is enabled.
// Until then returns a local awaiting-receipt stub so the UI renders.

final receiptSubmissionProvider =
    FutureProvider.family<ReceiptSubmission, String>((ref, orderId) async {
      return ReceiptSubmission(
        orderId: orderId,
        orderNumber: '---',
        courseTitle: '',
        status: ReceiptStatus.awaitingReceipt,
      );
    });

// ── Internal ──────────────────────────────────────────────────────────────────

class _FeatureUnavailableException implements Exception {
  const _FeatureUnavailableException(this.message);
  final String message;

  @override
  String toString() => message;
}
