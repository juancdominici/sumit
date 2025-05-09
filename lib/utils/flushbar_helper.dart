import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

/// Provides consistent, type-specific Flushbar notifications across the app.
/// Update this class to change global notification styles.
class AppFlushbar {
  static Flushbar success({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Flushbar(
      titleText:
          title != null
              ? Text(
                title,
                style: TextStyle(
                  color:
                      isDark
                          ? Colors.greenAccent.shade100
                          : Colors.green.shade900,
                  fontWeight: FontWeight.bold,
                ),
              )
              : null,
      messageText: Text(
        message,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.green.shade900,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: Icon(
        Icons.check_circle_outline,
        size: 28.0,
        color: isDark ? Colors.greenAccent : Colors.green,
      ),
      leftBarIndicatorColor: isDark ? Colors.greenAccent : Colors.green,
      backgroundColor:
          isDark
              ? Colors.green.shade900.withOpacity(0.95)
              : Colors.green.shade50,
      duration: duration,
      borderRadius: BorderRadius.circular(8),
      margin: const EdgeInsets.all(8),
      flushbarPosition: FlushbarPosition.TOP,
      shouldIconPulse: false,
    );
  }

  static Flushbar error({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Flushbar(
      titleText:
          title != null
              ? Text(
                title,
                style: TextStyle(
                  color:
                      isDark ? Colors.redAccent.shade100 : Colors.red.shade900,
                  fontWeight: FontWeight.bold,
                ),
              )
              : null,
      messageText: Text(
        message,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.red.shade900,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: Icon(
        Icons.error_outline,
        size: 28.0,
        color: isDark ? Colors.redAccent : Colors.red,
      ),
      leftBarIndicatorColor: isDark ? Colors.redAccent : Colors.red,
      backgroundColor:
          isDark ? Colors.red.shade900.withOpacity(0.95) : Colors.red.shade50,
      duration: duration,
      borderRadius: BorderRadius.circular(8),
      margin: const EdgeInsets.all(8),
      flushbarPosition: FlushbarPosition.TOP,
      shouldIconPulse: false,
    );
  }

  static Flushbar info({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Flushbar(
      titleText:
          title != null
              ? Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.blue.shade100 : Colors.blue.shade900,
                  fontWeight: FontWeight.bold,
                ),
              )
              : null,
      messageText: Text(
        message,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.blue.shade900,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: Icon(
        Icons.info_outline,
        size: 28.0,
        color: isDark ? Colors.blueAccent : Colors.blue,
      ),
      leftBarIndicatorColor: isDark ? Colors.blueAccent : Colors.blue,
      backgroundColor:
          isDark
              ? Colors.blueGrey.shade900.withOpacity(0.95)
              : Colors.blue.shade50,
      duration: duration,
      borderRadius: BorderRadius.circular(8),
      margin: const EdgeInsets.all(8),
      flushbarPosition: FlushbarPosition.TOP,
      shouldIconPulse: false,
    );
  }

  static Flushbar warning({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Flushbar(
      titleText:
          title != null
              ? Text(
                title,
                style: TextStyle(
                  color:
                      isDark ? Colors.orange.shade100 : Colors.orange.shade900,
                  fontWeight: FontWeight.bold,
                ),
              )
              : null,
      messageText: Text(
        message,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.orange.shade900,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: Icon(
        Icons.warning_amber_outlined,
        size: 28.0,
        color: isDark ? Colors.orangeAccent : Colors.orange,
      ),
      leftBarIndicatorColor: isDark ? Colors.orangeAccent : Colors.orange,
      backgroundColor:
          isDark
              ? Colors.orange.shade900.withOpacity(0.95)
              : Colors.orange.shade50,
      duration: duration,
      borderRadius: BorderRadius.circular(8),
      margin: const EdgeInsets.all(8),
      flushbarPosition: FlushbarPosition.TOP,
      shouldIconPulse: false,
    );
  }

  static Flushbar withAction({
    required BuildContext context,
    required String message,
    String? title,
    required Widget mainButton,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Flushbar(
      titleText:
          title != null
              ? Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.grey.shade900,
                  fontWeight: FontWeight.bold,
                ),
              )
              : null,
      messageText: Text(
        message,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.grey.shade900,
          fontWeight: FontWeight.w500,
        ),
      ),
      mainButton: mainButton,
      backgroundColor:
          isDark
              ? Colors.grey.shade900.withOpacity(0.95)
              : Colors.grey.shade200,
      duration: duration,
      borderRadius: BorderRadius.circular(8),
      margin: const EdgeInsets.all(8),
      flushbarPosition: FlushbarPosition.TOP,
      shouldIconPulse: false,
    );
  }
}
