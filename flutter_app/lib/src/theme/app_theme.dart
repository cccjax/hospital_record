import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const primary = Color(0xFF178A7A);
  const card = Color(0xFFF8FBFF);

  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    primary: primary,
    surface: Colors.white,
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF1F5FA),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2EAF6)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD5E2F2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD5E2F2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF79AEE6), width: 1.3),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );
}
