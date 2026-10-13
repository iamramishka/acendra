import 'package:acendra/features/checkout/domain/entities/checkout_order.dart';
import 'package:acendra/features/checkout/domain/entities/payment_method.dart';

class CheckoutOrderDto {
  const CheckoutOrderDto({
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
  final BankInstructionsDto? bankInstructions;

  factory CheckoutOrderDto.fromJson(Map<String, dynamic> json) {
    // The backend wraps the payload in a "data" key.
    final data = json['data'] as Map<String, dynamic>? ?? json;

    final courseMap = data['course'] as Map<String, dynamic>? ?? const {};
    final paymentMethodRaw = data['payment_method'] as String? ?? 'online';

    PaymentMethod paymentMethod;
    switch (paymentMethodRaw) {
      case 'bank_transfer':
        paymentMethod = PaymentMethod.bankTransfer;
        break;
      case 'online':
      default:
        paymentMethod = PaymentMethod.online;
    }

    BankInstructionsDto? bankInstructions;
    final bankMap = data['bank_instructions'] as Map<String, dynamic>?;
    if (bankMap != null) {
      bankInstructions = BankInstructionsDto.fromJson(bankMap);
    }

    return CheckoutOrderDto(
      orderId: data['order_id'] as String,
      orderNumber: data['order_number'] as String,
      courseId: courseMap['id'] as String? ?? '',
      courseTitle: courseMap['title'] as String? ?? '',
      amountMinor: data['amount_minor'] as int,
      currencyCode: data['currency_code'] as String? ?? 'LKR',
      paymentMethod: paymentMethod,
      status: data['status'] as String? ?? 'pending_payment',
      nextAction: data['next_action'] as String? ?? '',
      bankInstructions: bankInstructions,
    );
  }

  CheckoutOrder toEntity() {
    return CheckoutOrder(
      orderId: orderId,
      orderNumber: orderNumber,
      courseId: courseId,
      courseTitle: courseTitle,
      amountMinor: amountMinor,
      currencyCode: currencyCode,
      paymentMethod: paymentMethod,
      status: status,
      nextAction: nextAction,
      bankInstructions: bankInstructions?.toEntity(),
    );
  }
}

class BankInstructionsDto {
  const BankInstructionsDto({
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

  factory BankInstructionsDto.fromJson(Map<String, dynamic> json) {
    return BankInstructionsDto(
      bankName: json['bank_name'] as String? ?? '',
      accountHolder: json['account_holder'] as String? ?? '',
      accountNumber: json['account_number'] as String? ?? '',
      branch: json['branch'] as String? ?? '',
      currency: json['currency'] as String? ?? '',
    );
  }

  BankInstructions toEntity() {
    return BankInstructions(
      bankName: bankName,
      accountHolder: accountHolder,
      accountNumber: accountNumber,
      branch: branch,
      currency: currency,
    );
  }
}
