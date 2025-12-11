class Transaction {
  final String id;
  final String userId;
  final String note;
  final double amount;
  final int type;
  final String tId;
  final int tNo;
  final String createdAt;
  final String updatedAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.note,
    required this.amount,
    required this.type,
    required this.tId,
    required this.tNo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      note: json['note'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] ?? 0,
      tId: json['t_id'] ?? '',
      tNo: json['t_no'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}

class Income {
  final String userId;
  final String username;
  final double income;

  Income({
    required this.userId,
    required this.username,
    required this.income,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ChartData {
  final List<String> labels;
  final List<double> data;
  final List<String> backgroundColors;

  ChartData({
    required this.labels,
    required this.data,
    required this.backgroundColors,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      labels: List<String>.from(json['labels'] ?? []),
      data: List<double>.from((json['datasets']?[0]['data'] ?? []).map((e) => (e as num?)?.toDouble() ?? 0.0)),
      backgroundColors: List<String>.from(json['datasets']?[0]['backgroundColor'] ?? []),
    );
  }
}

class Analytics {
  final List<Transaction> transactionsType99;
  final List<Income> allUsersIncome;
  final List<Income> allBusinessPartnerIncome;
  final List<Income> allWarehousePartnerIncome;
  final Map<String, double> totalIncomeByCategory;
  final ChartData chartData;

  Analytics({
    required this.transactionsType99,
    required this.allUsersIncome,
    required this.allBusinessPartnerIncome,
    required this.allWarehousePartnerIncome,
    required this.totalIncomeByCategory,
    required this.chartData,
  });

  factory Analytics.fromJson(Map<String, dynamic> json) {
    return Analytics(
      transactionsType99: (json['transactionsType99'] as List<dynamic>?)
          ?.map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      allUsersIncome: (json['allUsersIncome'] as List<dynamic>?)
          ?.map((e) => Income.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      allBusinessPartnerIncome: (json['allBussinessPartnerIncome'] as List<dynamic>?)
          ?.map((e) => Income.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      allWarehousePartnerIncome: (json['allWarehousePartnerIncome'] as List<dynamic>?)
          ?.map((e) => Income.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      totalIncomeByCategory: Map<String, double>.from(
          (json['totalIncomeByCategory'] as Map<String, dynamic>?)?.map(
                (key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0.0),
          ) ?? {}),
      chartData: ChartData.fromJson(json['chartData'] ?? {}),
    );
  }
}