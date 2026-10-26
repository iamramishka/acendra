import 'dart:typed_data';
import 'package:acendra/features/bank_transfer/data/models/receipt_submission_dto.dart';
import 'package:acendra/features/bank_transfer/domain/entities/receipt_submission.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BankTransferFailure implements Exception {
  const BankTransferFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class BankTransferRepository {
  Future<ReceiptSubmission> status(String orderId);
  Future<List<Map<String, dynamic>>> queue();
  Future<void> review({
    required String submissionId,
    String? rejectionReason,
    Map<String, dynamic>? verifiedCredit,
  });
  Future<void> uploadReceipt({
    required String orderId,
    required String fileName,
    required List<int> bytes,
    required String idempotencyKey,
  });
}

class SupabaseBankTransferRepository implements BankTransferRepository {
  const SupabaseBankTransferRepository(this.client);
  final SupabaseClient client;

  Future<Map<String, dynamic>> _request(
    String function,
    Map<String, dynamic> body, {
    String? key,
  }) async {
    if (client.auth.currentSession == null) {
      throw const BankTransferFailure('Sign in to continue.');
    }
    try {
      final response = await client.functions.invoke(
        function,
        body: body,
        headers: key == null ? null : {'Idempotency-Key': key},
      );
      if (response.status != 200 && response.status != 201) {
        throw bankTransferHttpFailure(response.status);
      }
      final payload = response.data;
      if (payload is! Map || payload['data'] is! Map) {
        throw const BankTransferFailure(
          'The operation could not be confirmed.',
        );
      }
      return Map<String, dynamic>.from(payload['data'] as Map);
    } on FunctionException catch (e) {
      throw bankTransferHttpFailure(e.status);
    } on BankTransferFailure {
      rethrow;
    } catch (_) {
      throw const BankTransferFailure(
        'The operation could not be confirmed. Refresh before retrying.',
      );
    }
  }

  @override
  Future<ReceiptSubmission> status(String orderId) async {
    final data = await _request('bank-transfer-read', {'order_id': orderId});
    try {
      return receiptSubmissionFromJson(data, orderId);
    } catch (_) {
      throw const BankTransferFailure('Order status could not be confirmed.');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> queue() async {
    final data = await _request('bank-transfer-read', {'queue': true});
    if (data['items'] is! List) {
      throw const BankTransferFailure('Finance queue could not be confirmed.');
    }
    return (data['items'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  @override
  Future<void> review({
    required String submissionId,
    String? rejectionReason,
    Map<String, dynamic>? verifiedCredit,
  }) async {
    final reject = rejectionReason != null;
    if (reject == (verifiedCredit != null)) {
      throw const BankTransferFailure(
        'Choose one decision with complete evidence.',
      );
    }
    if (reject &&
        (rejectionReason.trim().isEmpty || rejectionReason.length > 1000)) {
      throw const BankTransferFailure('Enter a student-safe rejection reason.');
    }
    final data = await _request(
      'admin-review-bank-transfer',
      {
        'submission_id': submissionId,
        'decision': reject ? 'reject' : 'approve',
        if (reject) 'rejection_reason': rejectionReason.trim(),
        if (!reject) 'verified_credit': verifiedCredit,
      },
      key: 'bank-review-$submissionId-${reject ? 'reject' : 'approve'}',
    );
    if (data['submission_id'] != submissionId ||
        data['submission_status'] != (reject ? 'rejected' : 'approved')) {
      throw const BankTransferFailure(
        'The decision could not be confirmed. Refresh before retrying.',
      );
    }
  }

  @override
  Future<void> uploadReceipt({
    required String orderId,
    required String fileName,
    required List<int> bytes,
    required String idempotencyKey,
  }) async {
    if (client.auth.currentSession == null) {
      throw const BankTransferFailure('Sign in to submit a receipt.');
    }
    final extension = fileName.split('.').last.toLowerCase();
    final mime = switch (extension) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      _ => null,
    };
    if (mime == null ||
        bytes.isEmpty ||
        bytes.length > 5 * 1024 * 1024 ||
        fileName.contains(RegExp(r'[\x00-\x1f\x7f]'))) {
      throw const BankTransferFailure(
        'Choose a PDF, JPG or PNG receipt up to 5 MB.',
      );
    }
    try {
      final response = await client.functions.invoke(
        'upload-bank-receipt',
        headers: {
          'Idempotency-Key': idempotencyKey,
          'X-Order-Id': orderId,
          'X-Receipt-Name': fileName,
          'Content-Type': mime,
        },
        body: Uint8List.fromList(bytes),
      );
      if (response.status != 200 && response.status != 201) {
        throw bankTransferHttpFailure(response.status);
      }
      final payload = response.data;
      final data = payload is Map ? payload['data'] : null;
      if (data is! Map ||
          data['order_id'] != orderId ||
          data['status'] != 'submitted' ||
          data['submission_id'] is! String) {
        throw const BankTransferFailure(
          'Receipt submission could not be confirmed. Refresh the order before retrying.',
        );
      }
    } on FunctionException catch (error) {
      throw bankTransferHttpFailure(error.status);
    } on BankTransferFailure {
      rethrow;
    } catch (_) {
      throw const BankTransferFailure(
        'Receipt submission could not be confirmed. Refresh the order before retrying.',
      );
    }
  }
}

BankTransferFailure bankTransferHttpFailure(int status) => switch (status) {
  401 => const BankTransferFailure('Sign in to submit a receipt.'),
  403 => const BankTransferFailure(
    'You do not have permission to submit this receipt.',
  ),
  409 => const BankTransferFailure(
    'This order or receipt changed. Refresh the order before retrying.',
  ),
  413 => const BankTransferFailure('The receipt file is too large.'),
  422 => const BankTransferFailure(
    'The receipt could not pass file inspection.',
  ),
  503 => const BankTransferFailure(
    'Bank transfer service is temporarily unavailable. No change was confirmed.',
  ),
  _ => const BankTransferFailure(
    'Receipt submission could not be confirmed. Refresh the order before retrying.',
  ),
};

final bankTransferRepositoryProvider = Provider<BankTransferRepository>((ref) {
  return SupabaseBankTransferRepository(Supabase.instance.client);
});
