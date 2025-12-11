class WalletTransaction {
  final String transactionNo;
  final String date;
  final String amountDesc;
  final int debitCredit; // negative = debit, positive = credit

  WalletTransaction({
    required this.transactionNo,
    required this.date,
    required this.amountDesc,
    required this.debitCredit,
  });
}
