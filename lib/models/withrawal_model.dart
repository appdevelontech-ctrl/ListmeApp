class WithdrawalModel {
  final String id;
  final String userId;
  final String username;
  final double amount;
  final String transactionId;
  final int transactionNo;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  WithdrawalModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.amount,
    required this.transactionId,
    required this.transactionNo,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    try {
      final userIdData = json['userId'] as Map<String, dynamic>?;
      return WithdrawalModel(
        id: json['_id']?.toString() ?? '',
        userId: userIdData?['_id']?.toString() ?? '',
        username: userIdData?['username']?.toString() ?? 'Unknown User',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        transactionId: json['t_id']?.toString() ?? 'N/A', // Handle missing t_id
        transactionNo: (json['t_no'] as num?)?.toInt() ?? 0,
        status: _mapStatusToString(json['status'] ?? 0),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      );
    } catch (e, stackTrace) {
      print('WithdrawalModel: Error parsing JSON: $e');
      print('WithdrawalModel: JSON: $json');
      print('WithdrawalModel: StackTrace: $stackTrace');
      rethrow;
    }
  }

  static String _mapStatusToString(int status) {
    switch (status) {
      case 0:
        return 'Pending';
      case 1:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }
}