import 'package:june/june.dart';
import 'package:sumit/models/module.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisplayState extends JuneState {
  String displayValue = '';
  String operator = '';
  Map<String, int> selection = {'start': 0, 'end': 0};
  String tagInputValue = '';
  bool showTagInput = false;
  bool isRecurringExpense = false;
  bool showRecurringExpenseInput = false;
  RecurringType recurringExpenseType = RecurringType.none;
  DateTime date = DateTime.now();
  String? groupId;

  DisplayState() {
    _loadDefaultOperator();
  }

  Future<void> _loadDefaultOperator() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultNegative = prefs.getBool('default_negative') ?? false;
    operator = defaultNegative ? "-" : "";
    setState();
  }

  void handleNumberInput(String number) {
    if (displayValue == '0') {
      displayValue = number;
    } else if (selection['start'] != -1) {
      displayValue =
          displayValue.substring(0, selection['start']!) +
          number +
          displayValue.substring(selection['end']!);
      selection = {
        'start': selection['start']! + 1,
        'end': selection['start']! + 1,
      };
    } else {
      displayValue += number;
    }
    setState();
  }

  void handleCommaInput() {
    if (!displayValue.contains('.')) {
      if (selection['start'] != -1) {
        displayValue =
            '${displayValue.substring(0, selection['start']!)}.${displayValue.substring(selection['end']!)}';
        selection = {
          'start': selection['start']! + 1,
          'end': selection['start']! + 1,
        };
      } else {
        displayValue += '.';
      }
    }
    setState();
  }

  void handleBackspaceInput() {
    if (displayValue.length > 1) {
      if (selection['start'] != -1) {
        displayValue =
            displayValue.substring(0, selection['start']! - 1) +
            displayValue.substring(selection['end']!);
        selection = {
          'start': selection['start']! - 1,
          'end': selection['start']! - 1,
        };
      } else {
        displayValue = displayValue.substring(0, displayValue.length - 1);
      }
    } else {
      displayValue = '0';
    }
    setState();
  }

  void handleOperatorInput(String newOperator) {
    if (displayValue != '0') {
      operator = operator.isEmpty || operator == "+" ? "-" : "+";
      setState();
    }
  }

  void resetDisplay() async {
    displayValue = '0';
    final prefs = await SharedPreferences.getInstance();
    operator = prefs.getBool('default_negative') ?? false ? "-" : "";
    selection = {'start': -1, 'end': -1};
    tagInputValue = '';
    showTagInput = false;
    isRecurringExpense = false;
    showRecurringExpenseInput = false;
    recurringExpenseType = RecurringType.none;
    date = DateTime.now();
    setState();
  }

  handleAddRecord() async {
    if (displayValue == '0') {
      throw DisplayError(
        message: 'El valor no puede ser 0',
        color: Colors.red.shade300,
      );
    }
    final amount = operator == "-" ? "-$displayValue" : displayValue;
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      throw DisplayError(
        message: 'User not authenticated',
        color: Colors.red.shade300,
      );
    }

    final recordData = {
      "tag": tagInputValue,
      "amount": amount,
      "date": date.toUtc().toString(),
      "is_recurring": isRecurringExpense,
      "recurring_type": recurringExpenseType.value,
      "user_id": userId,
      if (groupId != null) "group_id": groupId,
    };

    return await Supabase.instance.client.from("records").insert(recordData);
  }

  void setGroupId(String? id) {
    groupId = id;
    setState();
  }
}

class DisplayError implements Exception {
  final String message;
  final Color color;

  DisplayError({required this.message, required this.color});

  @override
  String toString() => message;
}
