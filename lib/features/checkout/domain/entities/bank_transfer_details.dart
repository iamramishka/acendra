/// Immutable data class holding the bank account info shown to the student
/// when they choose "bank transfer" at checkout.
class BankTransferDetails {
  const BankTransferDetails({
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.branch,
    required this.amount,
    required this.currency,
    required this.referenceId,
  });

  final String bankName;
  final String accountName;
  final String accountNumber;
  final String branch;

  /// Exact amount the student must transfer.
  final double amount;

  /// ISO-4217 currency code, e.g. "LKR".
  final String currency;

  /// Unique per order — student must include this in their transfer description
  /// so the finance team can match the receipt.
  final String referenceId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankTransferDetails &&
          runtimeType == other.runtimeType &&
          bankName == other.bankName &&
          accountName == other.accountName &&
          accountNumber == other.accountNumber &&
          branch == other.branch &&
          amount == other.amount &&
          currency == other.currency &&
          referenceId == other.referenceId;

  @override
  int get hashCode => Object.hash(
        bankName,
        accountName,
        accountNumber,
        branch,
        amount,
        currency,
        referenceId,
      );

  @override
  String toString() => 'BankTransferDetails('
      'bankName: $bankName, '
      'accountName: $accountName, '
      'accountNumber: $accountNumber, '
      'branch: $branch, '
      'amount: $amount, '
      'currency: $currency, '
      'referenceId: $referenceId'
      ')';
}
