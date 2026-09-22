class TransactionModel {
  final String id;
  final int amount;
  final String direction;
  final String description;
  final int date;
  final String? type;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.direction,
    required this.description,
    required this.date,
    this.type,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id']?.toString() ?? '',
      amount: json['amount'] ?? 0,
      direction: json['direction']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      date: json['date'] ?? 0,
      type: json['type'],
    );
  }

  bool get isDebit => direction == 'DEBIT';
  bool get isCredit => direction == 'CREDIT';

  DateTime get dateTime {
    return DateTime.fromMillisecondsSinceEpoch(date);
  }
}

class MonthlyStats {
  final int totalUnits;
  final int limit;
  final int remaining;
  final double percentage;

  MonthlyStats({
    required this.totalUnits,
    required this.limit,
    required this.remaining,
    required this.percentage,
  });

  factory MonthlyStats.empty() {
    return MonthlyStats(
      totalUnits: 0,
      limit: 2000,
      remaining: 2000,
      percentage: 0,
    );
  }

  bool get isLimitReached => remaining <= 0;
  bool get isLow => remaining < 500 && remaining > 0;
}
