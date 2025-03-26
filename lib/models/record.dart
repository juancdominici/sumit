import 'package:sumit/models/recurring_type.dart';

class Record {
  final String id;
  final String tag;
  final String amount;
  final DateTime date;
  final bool isRecurring;
  final String recurringType;
  final String userId;
  final DateTime? deleted;

  Record({
    required this.id,
    required this.tag,
    required this.amount,
    required this.date,
    required this.isRecurring,
    required this.recurringType,
    required this.userId,
    this.deleted,
  });

  factory Record.fromMap(Map<String, dynamic> map) {
    String amountStr;
    final dynamic rawAmount = map['amount'];
    if (rawAmount is num) {
      amountStr = rawAmount.toString();
    } else if (rawAmount is String) {
      amountStr = rawAmount;
    } else {
      amountStr = '0';
    }

    DateTime? deletedDate;
    if (map['deleted'] != null) {
      deletedDate = DateTime.parse(map['deleted'].toString());
    }

    return Record(
      id: map['id'].toString(),
      tag: map['tag'] as String? ?? '',
      amount: amountStr,
      date: DateTime.parse(map['date'].toString()),
      isRecurring: map['is_recurring'] as bool? ?? false,
      recurringType: map['recurring_type'] as String? ?? 'none',
      userId: map['user_id'].toString(),
      deleted: deletedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tag': tag,
      'amount': amount,
      'date': date.toUtc().toString(),
      'is_recurring': isRecurring,
      'recurring_type': recurringType,
      'user_id': userId,
      'deleted': deleted?.toUtc().toString(),
    };
  }

  Record copyWith({
    String? id,
    String? tag,
    String? amount,
    DateTime? date,
    bool? isRecurring,
    String? recurringType,
    String? userId,
    DateTime? deleted,
  }) {
    return Record(
      id: id ?? this.id,
      tag: tag ?? this.tag,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringType: recurringType ?? this.recurringType,
      userId: userId ?? this.userId,
      deleted: deleted ?? this.deleted,
    );
  }

  bool get isNegative => amount.startsWith('-');

  String get amountValue => isNegative ? amount.substring(1) : amount;

  RecurringType get recurringTypeEnum {
    switch (recurringType) {
      case 'daily':
        return RecurringType.daily;
      case 'weekly':
        return RecurringType.weekly;
      case 'bi_weekly':
        return RecurringType.bi_weekly;
      case 'monthly':
        return RecurringType.monthly;
      case 'yearly':
        return RecurringType.yearly;
      case 'last_month_day':
        return RecurringType.last_month_day;
      case 'last_business_day':
        return RecurringType.last_business_day;
      default:
        return RecurringType.none;
    }
  }

  bool get isDeleted => deleted != null;
}
