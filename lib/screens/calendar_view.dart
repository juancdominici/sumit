import 'package:flutter/material.dart';
import 'package:june/june.dart';
import 'package:sumit/models/module.dart';
import 'package:sumit/state/module.dart';
import 'package:sumit/utils/translations_extension.dart';
import 'package:intl/intl.dart';

class CalendarView extends StatelessWidget {
  const CalendarView({super.key});

  DateTime _adjustDateForRecurringType(
    DateTime currentDate,
    RecurringType type,
  ) {
    switch (type) {
      case RecurringType.lastMonthDay:
        return DateTime(currentDate.year, currentDate.month + 1, 0);
      case RecurringType.lastBusinessDay:
        DateTime lastDay = DateTime(currentDate.year, currentDate.month + 1, 0);
        while (lastDay.weekday == DateTime.saturday ||
            lastDay.weekday == DateTime.sunday) {
          lastDay = lastDay.subtract(const Duration(days: 1));
        }
        return lastDay;
      case RecurringType.monthly:
        final int selectedDay = currentDate.day;
        final int lastDayOfMonth =
            DateTime(currentDate.year, currentDate.month + 1, 0).day;

        if (selectedDay > lastDayOfMonth) {
          return DateTime(currentDate.year, currentDate.month, lastDayOfMonth);
        }
        return currentDate;
      default:
        return currentDate;
    }
  }

  Widget _buildDateSelector(DisplayState displayState, BuildContext context) {
    switch (displayState.recurringExpenseType) {
      case RecurringType.none:
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    context.translate('calendar.recurring.none.title'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: displayState.date,
                        firstDate: DateTime(displayState.date.year - 20),
                        lastDate: DateTime(displayState.date.year + 20),
                      );
                      if (pickedDate != null) {
                        displayState.date = pickedDate;
                        displayState.setState();
                      }
                    },
                    child: Row(
                      children: [
                        Text(
                          DateFormat(
                            'dd/MM/yyyy',
                            Localizations.localeOf(context).languageCode,
                          ).format(displayState.date),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  context.translate('calendar.recurring.none.description'),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ),
            ],
          ),
        );

      case RecurringType.daily:
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    context.translate(
                      'calendar.recurring.date_selector.daily.starting_from',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final initialDate = displayState.date;
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: now.subtract(const Duration(days: 365)),
                        lastDate: now.add(const Duration(days: 365 * 5)),
                      );
                      if (pickedDate != null) {
                        displayState.date = pickedDate;
                        displayState.setState();
                      }
                    },
                    child: Text(
                      DateFormat(
                        'dd/MM/yyyy',
                        Localizations.localeOf(context).languageCode,
                      ).format(displayState.date),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  context.translate('calendar.recurring.daily.description'),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ),
            ],
          ),
        );

      case RecurringType.weekly:
        final weekDays = [
          context.translate('calendar.recurring.date_selector.weekdays.monday'),
          context.translate(
            'calendar.recurring.date_selector.weekdays.tuesday',
          ),
          context.translate(
            'calendar.recurring.date_selector.weekdays.wednesday',
          ),
          context.translate(
            'calendar.recurring.date_selector.weekdays.thursday',
          ),
          context.translate('calendar.recurring.date_selector.weekdays.friday'),
          context.translate(
            'calendar.recurring.date_selector.weekdays.saturday',
          ),
          context.translate('calendar.recurring.date_selector.weekdays.sunday'),
        ];
        final currentDayOfWeek = displayState.date.weekday;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    context.translate(
                      'calendar.recurring.date_selector.weekly.every_week',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: List.generate(7, (index) {
                    final dayIndex = index + 1;
                    return FilterChip(
                      backgroundColor: Colors.transparent,
                      shape: StadiumBorder(
                        side: BorderSide(color: Colors.black12),
                      ),
                      label: Text(
                        weekDays[index],
                        style: TextStyle(color: Colors.black54),
                      ),
                      selected: currentDayOfWeek == dayIndex,
                      onSelected: (selected) {
                        if (selected) {
                          final now = DateTime.now();
                          int daysToAdd = (dayIndex - now.weekday) % 7;
                          final nextDate = now.add(Duration(days: daysToAdd));
                          displayState.date = nextDate;
                          displayState.setState();
                        }
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    context.translate(
                      'calendar.recurring.date_selector.bi_weekly.starting_from',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final initialDate = displayState.date;
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: now.subtract(const Duration(days: 365)),
                        lastDate: now.add(const Duration(days: 365 * 2)),
                      );
                      if (pickedDate != null) {
                        final int weekday = displayState.date.weekday;
                        final int daysToAdd =
                            (weekday - pickedDate.weekday) % 7;
                        final newDate = pickedDate.add(
                          Duration(days: daysToAdd),
                        );
                        displayState.date = newDate;
                        displayState.setState();
                      }
                    },
                    child: Text(
                      DateFormat(
                        'dd/MM/yyyy',
                        Localizations.localeOf(context).languageCode,
                      ).format(displayState.date),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case RecurringType.monthly:
        final currentDay = displayState.date.day;
        final daysInMonth =
            DateTime(
              displayState.date.year,
              displayState.date.month + 1,
              0,
            ).day;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    context.translate('calendar.recurring.monthly.every'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(
                    width: 60,
                    child: DropdownButton<int>(
                      value: currentDay,
                      items: List.generate(daysInMonth, (index) {
                        final day = index + 1;
                        return DropdownMenuItem<int>(
                          value: day,
                          child: Text(day.toString()),
                        );
                      }),
                      onChanged: (day) {
                        if (day != null) {
                          final newDate = DateTime(
                            displayState.date.year,
                            displayState.date.month,
                            day,
                          );
                          displayState.date = newDate;
                          displayState.setState();
                        }
                      },
                      underline: Container(
                        height: 1,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      icon: Icon(Icons.arrow_drop_down),
                    ),
                  ),
                  Text(
                    context.translate(
                      'calendar.recurring.monthly.of_the_month',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.translate('calendar.recurring.monthly.warning'),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        );

      case RecurringType.yearly:
        final currentDay = displayState.date.day;
        final currentMonth = displayState.date.month;
        final monthNames = List.generate(12, (index) {
          return DateFormat(
            'MMMM',
            Localizations.localeOf(context).languageCode,
          ).format(DateTime(2022, index + 1));
        });

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    context.translate('calendar.recurring.yearly.every'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  DropdownButton<int>(
                    value: currentDay,
                    items: List.generate(
                      DateTime(
                        displayState.date.year,
                        displayState.date.month + 1,
                        0,
                      ).day,
                      (index) => DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        final newDate = DateTime(
                          displayState.date.year,
                          displayState.date.month,
                          value,
                        );
                        displayState.date = newDate;
                        displayState.setState();
                      }
                    },
                    underline: Container(
                      height: 1,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    icon: Icon(Icons.arrow_drop_down),
                  ),
                  DropdownButton<int>(
                    value: currentMonth,
                    items: List.generate(
                      12,
                      (index) => DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text(monthNames[index]),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        final daysInNewMonth =
                            DateTime(displayState.date.year, value + 1, 0).day;
                        final newDay =
                            currentDay > daysInNewMonth
                                ? daysInNewMonth
                                : currentDay;

                        final newDate = DateTime(
                          displayState.date.year,
                          value,
                          newDay,
                        );
                        displayState.date = newDate;
                        displayState.setState();
                      }
                    },
                    underline: Container(
                      height: 1,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    icon: Icon(Icons.arrow_drop_down),
                  ),
                ],
              ),
            ],
          ),
        );

      case RecurringType.biweekly:
        final weekDays = [
          context.translate('calendar.recurring.date_selector.weekdays.monday'),
          context.translate(
            'calendar.recurring.date_selector.weekdays.tuesday',
          ),
          context.translate(
            'calendar.recurring.date_selector.weekdays.wednesday',
          ),
          context.translate(
            'calendar.recurring.date_selector.weekdays.thursday',
          ),
          context.translate('calendar.recurring.date_selector.weekdays.friday'),
          context.translate(
            'calendar.recurring.date_selector.weekdays.saturday',
          ),
          context.translate('calendar.recurring.date_selector.weekdays.sunday'),
        ];
        final currentDayOfWeek = displayState.date.weekday;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    context.translate(
                      'calendar.recurring.date_selector.bi_weekly.every_two_weeks',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: List.generate(7, (index) {
                    final dayIndex = index + 1;
                    return FilterChip(
                      backgroundColor: Colors.transparent,
                      shape: StadiumBorder(
                        side: BorderSide(color: Colors.black12),
                      ),
                      label: Text(
                        weekDays[index],
                        style: TextStyle(color: Colors.black54),
                      ),
                      selected: currentDayOfWeek == dayIndex,
                      onSelected: (selected) {
                        if (selected) {
                          final now = DateTime.now();
                          int daysToAdd = (dayIndex - now.weekday) % 7;
                          if (daysToAdd == 0) daysToAdd = 7;
                          final nextDate = now.add(Duration(days: daysToAdd));
                          displayState.date = nextDate;
                          displayState.setState();
                        }
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    context.translate(
                      'calendar.recurring.date_selector.bi_weekly.starting_from',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final initialDate = displayState.date;
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: now.subtract(const Duration(days: 365 * 2)),
                        lastDate: now.add(const Duration(days: 365 * 2)),
                      );
                      if (pickedDate != null) {
                        final int weekday = displayState.date.weekday;
                        final int daysToAdd =
                            (weekday - pickedDate.weekday) % 7;
                        final newDate = pickedDate.add(
                          Duration(days: daysToAdd),
                        );
                        displayState.date = newDate;
                        displayState.setState();
                      }
                    },
                    child: Text(
                      DateFormat(
                        'dd/MM/yyyy',
                        Localizations.localeOf(context).languageCode,
                      ).format(displayState.date),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case RecurringType.lastMonthDay:
      case RecurringType.lastBusinessDay:
        final currentMonth = displayState.date.month;
        final monthNames = List.generate(12, (index) {
          return DateFormat(
            'MMMM',
            Localizations.localeOf(context).languageCode,
          ).format(DateTime(2022, index + 1));
        });

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    context.translate(
                      'calendar.recurring.${displayState.recurringExpenseType.name}.from',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  DropdownButton<int>(
                    value: currentMonth,
                    items: List.generate(
                      12,
                      (index) => DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text(monthNames[index]),
                      ),
                    ),
                    onChanged: (month) {
                      if (month != null) {
                        final newDate = DateTime(
                          displayState.date.year,
                          month,
                          1,
                        );
                        displayState.date = _adjustDateForRecurringType(
                          newDate,
                          displayState.recurringExpenseType,
                        );
                        displayState.setState();
                      }
                    },
                    underline: Container(
                      height: 1,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    icon: Icon(Icons.arrow_drop_down),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (displayState.recurringExpenseType ==
                  RecurringType.lastBusinessDay)
                Center(
                  child: Text(
                    context.translate(
                      'calendar.recurring.date_selector.last_business_day.note',
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                ),
              if (displayState.recurringExpenseType ==
                  RecurringType.lastMonthDay)
                Center(
                  child: Text(
                    context.translate(
                      'calendar.recurring.date_selector.last_month_day.note',
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return JuneBuilder(
      () => DisplayState(),
      builder:
          (displayState) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: 32,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: RecurringTypeSelector(
                      selectedType: displayState.recurringExpenseType,
                      onTypeSelected: (type) {
                        displayState.recurringExpenseType = type;
                        displayState.isRecurringExpense =
                            (type != RecurringType.none);
                        if (type == RecurringType.daily) {
                        } else if (type == RecurringType.lastMonthDay ||
                            type == RecurringType.lastBusinessDay ||
                            type == RecurringType.monthly) {
                          displayState.date = _adjustDateForRecurringType(
                            displayState.date,
                            type,
                          );
                        }

                        displayState.setState();
                      },
                    ),
                  ),
                ),
                _buildDateSelector(displayState, context),
              ],
            ),
          ),
    );
  }
}

class RecurringTypeSelector extends StatelessWidget {
  final RecurringType selectedType;
  final Function(RecurringType) onTypeSelected;

  const RecurringTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  String _getDescriptionForType(BuildContext context, RecurringType type) {
    return context.translate('calendar.recurring.${type.name}.description');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.80,
                ),
                builder:
                    (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Text(
                                context.translate('calendar.recurring.title'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            shrinkWrap: true,
                            children:
                                RecurringType.values
                                    .map(
                                      (type) => ListTile(
                                        title: Text(
                                          context.translate(
                                            'calendar.recurring.${type.name}.text',
                                          ),
                                          style: TextStyle(
                                            color:
                                                selectedType == type
                                                    ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                    : null,
                                            fontWeight:
                                                selectedType == type
                                                    ? FontWeight.bold
                                                    : null,
                                          ),
                                        ),
                                        subtitle: Text(
                                          _getDescriptionForType(context, type),
                                        ),
                                        selected: selectedType == type,
                                        onTap: () {
                                          onTypeSelected(type);
                                          Navigator.pop(context);
                                        },
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ],
                    ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.translate(
                      'calendar.recurring.${selectedType.name}.text',
                    ),
                    style: TextStyle(
                      color:
                          selectedType == RecurringType.none
                              ? Theme.of(context).textTheme.bodyMedium?.color
                              : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    color:
                        selectedType == RecurringType.none
                            ? Theme.of(context).textTheme.bodyMedium?.color
                            : Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
