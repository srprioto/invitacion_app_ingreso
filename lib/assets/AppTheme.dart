import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF313338),
  primaryColor: const Color(0xFF5865F2),
  canvasColor: const Color(0xFF2B2D31),
  dividerColor: const Color(0xFF3F4147),
  hintColor: const Color(0xFF949BA4),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF5865F2),
    onPrimary: Colors.white,
    secondary: Color(0xFF5865F2),
    onSecondary: Colors.white,
    surface: Color(0xFF2B2D31),
    onSurface: Color(0xFFDBDEE1),
    error: Color(0xFFED4245),
    onError: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E1F22),
    foregroundColor: Color(0xFFF2F3F5),
    elevation: 0,
    centerTitle: false,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFFDBDEE1)),
    bodyMedium: TextStyle(color: Color(0xFFDBDEE1)),
    bodySmall: TextStyle(color: Color(0xFF949BA4)),
    titleLarge: TextStyle(color: Color(0xFFF2F3F5), fontWeight: FontWeight.bold),
    titleMedium: TextStyle(color: Color(0xFFF2F3F5), fontWeight: FontWeight.w600),
    labelLarge: TextStyle(color: Color(0xFFF2F3F5)),
  ),
  iconTheme: const IconThemeData(color: Color(0xFFB5BAC1)),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1E1F22),
    hintStyle: const TextStyle(color: Color(0xFF949BA4)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Color(0xFF5865F2)),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF5865F2),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: const Color(0xFF00A8FC)),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFDBDEE1),
      side: const BorderSide(color: Color(0xFF4E5058)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF2B2D31),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    margin: const EdgeInsets.all(8),
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: Color(0xFFB5BAC1),
    textColor: Color(0xFFDBDEE1),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFF3F4147),
    thickness: 1,
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: Color(0xFF1E1F22),
    contentTextStyle: TextStyle(color: Color(0xFFDBDEE1)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF313338),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    titleTextStyle: const TextStyle(
      color: Color(0xFFF2F3F5),
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    contentTextStyle: const TextStyle(color: Color(0xFFDBDEE1)),
  ),
);