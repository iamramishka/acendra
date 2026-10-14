import 'dart:typed_data';
import 'package:acendra/features/checkout/domain/entities/customer_info.dart';
import 'package:acendra/features/checkout/domain/entities/payment_handoff.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef CheckoutInvoke =
    Future<FunctionResponse> Function(
      String name,
      Map<String, String> headers,
      Object body,
    );

/// Only authenticated Edge Functions accept financial submissions. The client
/// never writes orders, receipts, enrollments or private Storage objects.
class CheckoutSubmissionRepository {
  CheckoutSubmissionRepository(this.invoke);
  final CheckoutInvoke invoke;
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, String> headers,
    Object body,
  ) async {
    try {
      final response = await invoke(name, headers, body);
      if (response.status != 200 && response.status != 201) {
        throw const CheckoutFlowException(
          'Submission is temporarily unavailable. Please try again later.',
        );
      }
      final envelope = response.data;
      if (envelope is! Map || envelope['data'] is! Map<String, dynamic>) {
        throw const CheckoutFlowException(
          'The submission response could not be verified.',
        );
      }
      return envelope['data'] as Map<String, dynamic>;
    } on CheckoutFlowException {
      rethrow;
    } on FunctionException catch (error) {
      throw CheckoutFlowException(
        error.status == 503
            ? 'Submission is temporarily unavailable. Please try again later.'
            : error.status == 401
            ? 'Please sign in again before submitting.'
            : error.status == 409
            ? 'This order has changed. Check its current status before retrying.'
            : 'Submission could not be confirmed. Please retry.',
      );
    } catch (_) {
      // SDK errors may contain private server details. Never display them.
      throw const CheckoutFlowException(
        'Submission could not be confirmed. Please retry.',
      );
    }
  }

  Future<PaymentHandoff> initialize({
    required String orderId,
    required int amountMinor,
    required CustomerInfo customer,
    required String key,
  }) async {
    if (!_uuid.hasMatch(orderId)) {
      throw const CheckoutFlowException('Invalid checkout order.');
    }
    final data = await _call(
      'initialize-checkout',
      {'Idempotency-Key': key},
      {
        'order_id': orderId,
        'customer': {
          'first_name': customer.firstName.trim(),
          'last_name': customer.lastName.trim(),
          'phone': customer.phone.trim(),
          'address': customer.address.trim(),
          'city': customer.city.trim(),
          'country': customer.country.trim(),
        },
      },
    );
    final checkout = data['checkout'];
    final action = checkout is Map && checkout['action'] is String
        ? Uri.tryParse(checkout['action'] as String)
        : null;
    final rawFields = checkout is Map ? checkout['fields'] : null;
    if (data['order_id'] != orderId.toLowerCase() ||
        data['status'] != 'pending_payment' ||
        data['attempt_id'] is! String ||
        !_uuid.hasMatch(data['attempt_id'] as String) ||
        action == null ||
        action.scheme != 'https' ||
        action.userInfo.isNotEmpty ||
        action.hasPort ||
        !{'sandbox.payhere.lk', 'www.payhere.lk'}.contains(action.host) ||
        action.path != '/pay/checkout' ||
        action.hasQuery ||
        action.hasFragment ||
        rawFields is! Map ||
        rawFields.isEmpty ||
        rawFields.entries.any((e) => e.key is! String || e.value is! String)) {
      throw const CheckoutFlowException(
        'The payment handoff could not be verified.',
      );
    }
    final fields = Map<String, String>.from(rawFields);
    const expectedFields = {
      'first_name',
      'last_name',
      'email',
      'phone',
      'address',
      'city',
      'country',
      'return_url',
      'cancel_url',
      'notify_url',
      'merchant_id',
      'order_id',
      'items',
      'currency',
      'amount',
      'hash',
    };
    final expectedAmount =
        '${amountMinor ~/ 100}.${(amountMinor % 100).toString().padLeft(2, '0')}';
    if (amountMinor <= 0 ||
        fields.length != expectedFields.length ||
        !fields.keys.every(expectedFields.contains) ||
        fields.values.any(
          (value) =>
              value.isEmpty || RegExp(r'[\x00-\x1f\x7f]').hasMatch(value),
        ) ||
        fields['order_id'] != data['attempt_id'] ||
        fields['currency'] != 'LKR' ||
        fields['amount'] != expectedAmount) {
      throw const CheckoutFlowException(
        'The payment handoff could not be verified.',
      );
    }
    return PaymentHandoff(orderId: orderId, action: action, fields: fields);
  }

  Future<void> submitReceipt({
    required String orderId,
    required String name,
    required Uint8List bytes,
    required String key,
  }) async {
    final extension = name.split('.').last.toLowerCase();
    if (!_uuid.hasMatch(orderId) ||
        !{'jpg', 'jpeg', 'pdf'}.contains(extension) ||
        bytes.isEmpty ||
        bytes.length > 5 * 1024 * 1024) {
      throw const CheckoutFlowException(
        'Select a JPG or PDF receipt up to 5 MB.',
      );
    }
    // Send a safe ASCII transport filename, never a path or user-controlled header.
    final data = await _call('upload-bank-receipt', {
      'Idempotency-Key': key,
      'X-Order-Id': orderId,
      'X-Receipt-Name': 'receipt.$extension',
      'Content-Type': extension == 'pdf' ? 'application/pdf' : 'image/jpeg',
    }, bytes);
    if (data['order_id'] != orderId.toLowerCase() ||
        data['status'] != 'submitted' ||
        data['submission_id'] is! String ||
        !_uuid.hasMatch(data['submission_id'] as String)) {
      throw const CheckoutFlowException(
        'Receipt submission could not be confirmed.',
      );
    }
  }
}

final checkoutSubmissionRepositoryProvider =
    Provider<CheckoutSubmissionRepository>((ref) {
      final client = Supabase.instance.client;
      return CheckoutSubmissionRepository(
        (name, headers, body) =>
            client.functions.invoke(name, headers: headers, body: body),
      );
    });
