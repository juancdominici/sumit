import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.amber,
    brightness: Brightness.light,
  ),
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  iconTheme: const IconThemeData(color: Colors.black45),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    elevation: 0,
  ),
  bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.amberAccent.shade400;
      }
      return Colors.black54;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.amberAccent.shade100.withAlpha(200);
      }
      return Colors.black54.withValues(alpha: 0.3);
    }),
    trackOutlineColor: WidgetStateProperty.all(Colors.black12),
  ),
  cardColor: Colors.white,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black87),
    bodyMedium: TextStyle(color: Colors.black54),
    titleLarge: TextStyle(color: Colors.black87),
    titleMedium: TextStyle(color: Colors.black54),
  ),
  dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
);

ThemeData darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.amber,
    brightness: Brightness.dark,
  ).copyWith(
    primary: Colors.amberAccent,
    secondary: Colors.amberAccent.shade200,
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.grey.shade900,
  iconTheme: const IconThemeData(color: Colors.white),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey.shade900,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  bottomSheetTheme: BottomSheetThemeData(backgroundColor: Colors.grey.shade800),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.amberAccent.shade400;
      }
      return Colors.grey;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.amberAccent.shade100.withAlpha(200);
      }
      return Colors.grey.withValues(alpha: 0.3);
    }),
    trackOutlineColor: WidgetStateProperty.all(Colors.grey.shade700),
  ),
  cardColor: Colors.grey.shade800,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
    titleLarge: TextStyle(color: Colors.white),
    titleMedium: TextStyle(color: Colors.white70),
  ),
  dialogTheme: DialogThemeData(backgroundColor: Colors.grey.shade800),
);
