enum RecurringType {
  none('none'),
  daily('daily'),
  weekly('weekly'),
  biweekly('bi_weekly'),
  lastMonthDay('last_month_day'),
  lastBusinessDay('last_business_day'),
  monthly('monthly'),
  yearly('yearly');

  final String value;
  const RecurringType(this.value);
}
