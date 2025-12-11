class WalletModel {
  final double balance;
  final List<WalletTransaction> transactions;

  WalletModel({
    required this.balance,
    required this.transactions,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final List transactionsJson = json['Transaction'] ?? [];
    // Calculate balance by summing transaction amounts
    final double balance = transactionsJson.fold(0.0, (sum, tx) => sum + (tx['amount'] as num).toDouble());
    return WalletModel(
      balance: balance,
      transactions: transactionsJson
          .map((e) => WalletTransaction.fromJson(e))
          .toList(),
    );
  }
}

class WalletTransaction {
  final String id;
  final String userId;
  final String note;
  final double amount;
  final int type;
  final String transactionId;
  final int transactionNo;
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.note,
    required this.amount,
    required this.type,
    required this.transactionId,
    required this.transactionNo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      note: json['note'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] ?? 0,
      transactionId: json['t_id'] ?? '',
      transactionNo: json['t_no'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'note': note,
      'amount': amount,
      'type': type,
      't_id': transactionId,
      't_no': transactionNo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}