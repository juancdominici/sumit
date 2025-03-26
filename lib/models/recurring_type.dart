enum RecurringType {
  none('none'),
  daily('daily'),
  weekly('weekly'),
  bi_weekly('bi_weekly'),
  last_month_day('last_month_day'),
  last_business_day('last_business_day'),
  monthly('monthly'),
  yearly('yearly');

  final String value;
  const RecurringType(this.value);
}
