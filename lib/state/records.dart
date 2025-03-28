import 'package:june/june.dart';
import 'package:sumit/models/module.dart';
import 'package:sumit/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart' show Locale;

class RecordsState extends JuneState {
  bool isLoading = true;
  bool isLoadingMore = false;
  List<Record> records = [];
  DateTime? oldestLoadedMonth;
  Map<String, dynamic> metrics = {
    'income': 0.0,
    'expenses': 0.0,
    'balance': 0.0,
  };

  RecordsState() {
    fetchRecords();
  }

  Future<void> fetchRecords() async {
    isLoading = true;
    setState();

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Get current month bounds
      final now = DateTime.now();
      oldestLoadedMonth = DateTime(now.year, now.month, 1);

      // Clear previous records when explicitly fetching from scratch
      records = [];

      await _loadRecordsForMonth(oldestLoadedMonth!);
    } catch (e) {
      logger.d('Error fetching records: $e');
    } finally {
      isLoading = false;
      setState();
    }
  }

  Future<void> loadMoreRecords() async {
    if (isLoadingMore || oldestLoadedMonth == null) return;

    isLoadingMore = true;
    setState();

    try {
      // Calculate the previous month
      final previousMonth = DateTime(
        oldestLoadedMonth!.year,
        oldestLoadedMonth!.month - 1,
        1,
      );
      oldestLoadedMonth = previousMonth;

      await _loadRecordsForMonth(previousMonth);
    } catch (e) {
      logger.d('Error loading more records: $e');
    } finally {
      isLoadingMore = false;
      setState();
    }
  }

  Future<void> _loadRecordsForMonth(DateTime targetMonth) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final startDate = DateTime(targetMonth.year, targetMonth.month, 1);
    final endDate = DateTime(targetMonth.year, targetMonth.month + 1, 0);

    try {
      // Fetch all records from the beginning up to the end of the target month
      final response = await Supabase.instance.client
          .from('records')
          .select()
          .eq('user_id', userId)
          .gte(
            'date',
            startDate.toIso8601String(),
          ) // Records from start of month
          .lte('date', endDate.toIso8601String()) // Records up to end of month
          .order('date', ascending: false);

      List<Record> allRecords = List<Map<String, dynamic>>.from(
        response,
      ).map((map) => Record.fromMap(map)).toList();

      // Get all recurring records (we need all of them to generate instances correctly)
      final recurringResponse = await Supabase.instance.client
          .from('records')
          .select()
          .eq('user_id', userId)
          .eq('is_recurring', true)
          .lte(
            'date',
            endDate.toIso8601String(),
          ) // Only get recurring records created up to this month
          .order('date', ascending: false);

      List<Record> allRecurringRecords = List<Map<String, dynamic>>.from(
        recurringResponse,
      ).map((map) => Record.fromMap(map)).toList();

      // Filter non-recurring records for the target month
      List<Record> monthRecords =
          allRecords.where((record) => !record.isRecurring).toList();

      // Find the full date range to generate recurring records for
      DateTime oldestDate = startDate;
      DateTime newestDate = endDate;

      // If we have existing records, consider their date range
      if (records.isNotEmpty) {
        // Find the oldest and newest dates in the existing records
        records.sort((a, b) => a.date.compareTo(b.date));
        final existingOldest = records.first.date;
        final existingNewest = records.last.date;

        // Expand the range if needed
        if (existingOldest.isBefore(oldestDate)) {
          oldestDate = DateTime(existingOldest.year, existingOldest.month, 1);
        }
        if (existingNewest.isAfter(newestDate)) {
          newestDate = DateTime(
            existingNewest.year,
            existingNewest.month + 1,
            0,
          );
        }
      }

      // Generate recurring records for the entire date range
      List<Record> recurringRecords = _generateRecurringRecordsForDateRange(
        allRecurringRecords,
        oldestDate,
        newestDate,
      );

      // Add new records to the existing list
      List<Record> newRecords = [
        ...records, // Keep existing records
        ...monthRecords,
        ...recurringRecords,
      ];

      // Remove any duplicates that might occur during pagination
      final uniqueRecords = <String, Record>{};
      for (var record in newRecords) {
        uniqueRecords[record.id] = record;
      }

      // Update records with unique entries
      records = uniqueRecords.values.toList();

      // Sort all records by date descending
      records.sort((a, b) => b.date.compareTo(a.date));

      // Recalculate metrics for all loaded records
      calculateMetrics();
      setState();
    } catch (e) {
      logger.d('Error in _loadRecordsForMonth: $e');
    }
  }

  Future<void> filterByDate(DateTime date) async {
    isLoading = true;
    setState();

    try {
      oldestLoadedMonth = DateTime(date.year, date.month, 1);
      records = []; // Clear only when explicitly filtering
      await _loadRecordsForMonth(oldestLoadedMonth!);
    } catch (e) {
      logger.d('Error filtering records: $e');
    } finally {
      isLoading = false;
      setState();
    }
  }

  void calculateMetrics() {
    double income = 0.0;
    double expenses = 0.0;

    for (var record in records.where((r) => !r.isDeleted)) {
      try {
        if (record.isNegative) {
          expenses += double.parse(record.amountValue);
        } else {
          income += double.parse(record.amount);
        }
      } catch (e) {
        logger.d('Error calculating metrics for record ${record.id}: $e');
      }
    }

    metrics = {
      'income': income,
      'expenses': expenses,
      'balance': income - expenses,
    };
  }

  List<Record> _generateRecurringRecordsForDateRange(
    List<Record> recurringRecords,
    DateTime startDate,
    DateTime endDate,
  ) {
    List<Record> generatedRecords = [];
    Set<String> existingDates = {}; // Track unique dates

    for (var baseRecord in recurringRecords) {
      final baseDate = baseRecord.date;
      final recurringType = baseRecord.recurringTypeEnum;

      // Skip if the record is not recurring or if it starts after the end date
      if (recurringType == RecurringType.none || baseDate.isAfter(endDate)) {
        continue;
      }

      // Calculate current date and month increments needed
      DateTime currentDate = startDate;

      // Generate dates for the entire range month by month
      while (!currentDate.isAfter(endDate)) {
        final currentMonthEnd = DateTime(
          currentDate.year,
          currentDate.month + 1,
          0,
        );
        final monthEndDate =
            currentMonthEnd.isAfter(endDate) ? endDate : currentMonthEnd;

        // Generate dates for this recurring record for the current month
        List<DateTime> occurrenceDates = _generateOccurrenceDatesForMonth(
          baseDate,
          recurringType,
          currentDate,
          monthEndDate,
        );

        // Create virtual records for each occurrence
        for (var occurrenceDate in occurrenceDates) {
          // Skip dates before the record's creation date
          if (occurrenceDate.isBefore(baseDate)) continue;

          // Create a unique identifier for this date
          String dateKey =
              "${baseRecord.id}_${DateFormat('yyyyMMdd').format(occurrenceDate)}";

          // Skip if we already have a record for this date
          if (existingDates.contains(dateKey)) continue;

          existingDates.add(dateKey);

          // Create a virtual record for this occurrence
          generatedRecords.add(
            baseRecord.copyWith(id: dateKey, date: occurrenceDate),
          );
        }

        // Move to the next month
        currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
      }
    }

    return generatedRecords;
  }

  // Generate dates when a recurring record would occur in the specified month
  List<DateTime> _generateOccurrenceDatesForMonth(
    DateTime baseDate,
    RecurringType recurringType,
    DateTime startDate,
    DateTime endDate,
  ) {
    List<DateTime> dates = [];

    switch (recurringType) {
      case RecurringType.daily:
        // For daily, add each day in the month
        for (var day = startDate;
            day.isBefore(endDate.add(const Duration(days: 1)));
            day = day.add(const Duration(days: 1))) {
          dates.add(day);
        }
        break;

      case RecurringType.weekly:
        // For weekly, add matching weekdays in the month
        for (var day = startDate;
            day.isBefore(endDate.add(const Duration(days: 1)));
            day = day.add(const Duration(days: 1))) {
          if (day.weekday == baseDate.weekday) {
            dates.add(day);
          }
        }
        break;

      case RecurringType.biweekly:
        // For bi-weekly, add matching weekdays every other week
        // Find the first occurrence in or before the start date
        DateTime biWeeklyDate = baseDate;
        while (biWeeklyDate.isAfter(
          startDate.subtract(const Duration(days: 14)),
        )) {
          biWeeklyDate = biWeeklyDate.subtract(const Duration(days: 14));
        }

        // Now add bi-weekly dates starting from the reference point
        while (biWeeklyDate.isBefore(endDate.add(const Duration(days: 1)))) {
          if (biWeeklyDate.isAfter(
            startDate.subtract(const Duration(days: 1)),
          )) {
            dates.add(biWeeklyDate);
          }
          biWeeklyDate = biWeeklyDate.add(const Duration(days: 14));
        }
        break;

      case RecurringType.monthly:
        // Check if the base day exists in the current month
        int baseDay = baseDate.day;
        int currentMonthLastDay = endDate.day;
        int actualDay =
            baseDay <= currentMonthLastDay ? baseDay : currentMonthLastDay;

        // Add the date for the current month
        dates.add(DateTime(startDate.year, startDate.month, actualDay));
        break;

      case RecurringType.yearly:
        // Check if the base month and day fall within the current month
        if (baseDate.month == startDate.month) {
          // Check if day exists in this month (e.g., handle Feb 29 in non-leap years)
          int baseDay = baseDate.day;
          int currentMonthLastDay = endDate.day;
          int actualDay =
              baseDay <= currentMonthLastDay ? baseDay : currentMonthLastDay;

          dates.add(DateTime(startDate.year, startDate.month, actualDay));
        }
        break;

      case RecurringType.lastMonthDay:
        // Add the last day of the month
        dates.add(endDate);
        break;

      case RecurringType.lastBusinessDay:
        // Find the last business day (not a weekend)
        DateTime lastBusinessDay = endDate;
        while (lastBusinessDay.weekday == DateTime.saturday ||
            lastBusinessDay.weekday == DateTime.sunday) {
          lastBusinessDay = lastBusinessDay.subtract(const Duration(days: 1));
        }
        dates.add(lastBusinessDay);
        break;

      default:
        // For other types or none, don't add any dates
        break;
    }

    return dates;
  }

  // Get records grouped by month, excluding deleted records
  Map<String, List<Record>> getRecordsByMonth({Locale? locale}) {
    final Map<String, List<Record>> groupedRecords = {};
    final String languageCode = locale?.languageCode ?? 'en';

    // Filter out deleted records
    final activeRecords = records.where((record) => !record.isDeleted).toList();

    for (var record in activeRecords) {
      final monthYear = DateFormat(
        'MMMM yyyy',
        languageCode,
      ).format(record.date);

      if (!groupedRecords.containsKey(monthYear)) {
        groupedRecords[monthYear] = [];
      }

      groupedRecords[monthYear]!.add(record);
    }

    return groupedRecords;
  }

  // Delete a record by ID
  Future<void> deleteRecord(String recordId) async {
    try {
      // Update the record with deletion date instead of removing it
      await Supabase.instance.client
          .from('records')
          .update({'deleted': DateTime.now().toUtc().toIso8601String()}).eq(
              'id', recordId);

      // Update the local record to mark it as deleted
      final recordIndex = records.indexWhere((r) => r.id == recordId);
      if (recordIndex != -1) {
        records[recordIndex] = records[recordIndex].copyWith(
          deleted: DateTime.now(),
        );
        calculateMetrics();
        setState();
      }

      logger.d('Record $recordId marked as deleted');
    } catch (e) {
      logger.d('Error deleting record from database: $e');
      rethrow;
    }
  }

  // Optimistically mark a record as deleted in the UI
  void optimisticallyDeleteRecord(String recordId) {
    final recordIndex = records.indexWhere((r) => r.id == recordId);
    if (recordIndex != -1) {
      records[recordIndex] = records[recordIndex].copyWith(
        deleted: DateTime.now(),
      );
      calculateMetrics();
      setState();
    }
  }

  // Restore a record by removing the deletion date
  void restoreRecord(Record record) {
    final recordIndex = records.indexWhere((r) => r.id == record.id);
    if (recordIndex != -1) {
      records[recordIndex] = records[recordIndex].copyWith(deleted: null);
      calculateMetrics();
      setState();
    }
  }
}
