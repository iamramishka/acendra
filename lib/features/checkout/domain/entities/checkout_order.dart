import 'package:acendra/features/checkout/domain/entities/payment_method.dart';
import 'package:flutter/foundation.dart';

@immutable
class CheckoutOrder {
  const CheckoutOrder({
    required this.orderId,
    required this.orderNumber,
    required this.courseId,
    required this.courseTitle,
    required this.amountMinor,
    required this.currencyCode,
    required this.paymentMethod,
    required this.status,
    required this.nextAction,
    this.bankInstructions,
  });

  final String orderId;
  final String orderNumber;
  final String courseId;
  final String courseTitle;
  final int amountMinor;
  final String currencyCode;
  final PaymentMethod paymentMethod;
  final String status;
  final String nextAction;
  final BankInstructions? bankInstructions;

  String get formattedAmount {
    final major = amountMinor ~/ 100;
    final cents = amountMinor % 100;
    final majorStr = major.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$currencyCode $majorStr.${cents.toString().padLeft(2, '0')}';
  }
}

@immutable
class BankInstructions {
  const BankInstructions({
    required this.bankName,
    required this.accountHolder,
    required this.accountNumber,
    required this.branch,
    required this.currency,
  });

  final String bankName;
  final String accountHolder;
  final String accountNumber;
  final String branch;
  final String currency;
}
