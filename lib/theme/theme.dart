import 'package:flutter/material.dart';

/// Light theme using standard Material 3.
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    centerTitle: false,
    backgroundColor: Color(0xFF1565C0),
    foregroundColor: Colors.white,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 58),
    displayMedium: TextStyle(fontSize: 46),
    displaySmall: TextStyle(fontSize: 37),
    headlineLarge: TextStyle(fontSize: 33),
    headlineMedium: TextStyle(fontSize: 29),
    headlineSmall: TextStyle(fontSize: 25),
    titleLarge: TextStyle(fontSize: 23),
    titleMedium: TextStyle(fontSize: 17),
    titleSmall: TextStyle(fontSize: 15),
    bodyLarge: TextStyle(fontSize: 17),
    bodyMedium: TextStyle(fontSize: 15),
    bodySmall: TextStyle(fontSize: 13),
    labelLarge: TextStyle(fontSize: 15),
    labelMedium: TextStyle(fontSize: 13),
    labelSmall: TextStyle(fontSize: 12),
  ),
);
