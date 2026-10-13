import 'package:flutter/material.dart';

enum PaymentMethod {
  online, // PayHere hosted checkout
  bankTransfer, // Manual bank deposit + receipt
}

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.online => 'Online Payment',
    PaymentMethod.bankTransfer => 'Bank Transfer',
  };

  String get description => switch (this) {
    PaymentMethod.online =>
      'Pay instantly with a credit or debit card via PayHere.',
    PaymentMethod.bankTransfer =>
      'Deposit to our bank account and submit your receipt.',
  };

  IconData get icon => switch (this) {
    PaymentMethod.online => Icons.credit_card_outlined,
    PaymentMethod.bankTransfer => Icons.account_balance_outlined,
  };
}
