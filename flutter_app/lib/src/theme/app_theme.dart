import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const primary = Color(0xFF0D766E);
  const card = Color(0xFFFCFEFF);
  const buttonTextStyle = TextStyle(fontWeight: FontWeight.w700, fontSize: 13);
  final buttonShape =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    primary: primary,
    surface: Colors.white,
    secondary: const Color(0xFF2F80ED),
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFE7EEF8),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
      shadowColor: Color(0x3A123A47),
      toolbarHeight: 60,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 1.2,
      shadowColor: const Color(0x2A173454),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFD6E2F0)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        shape: buttonShape,
        elevation: 0,
        textStyle: buttonTextStyle,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        shape: buttonShape,
        side: const BorderSide(color: Color(0xFFBCD2EA)),
        foregroundColor: const Color(0xFF2F5F96),
        textStyle: buttonTextStyle,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        foregroundColor: const Color(0xFF325E8F),
        textStyle: buttonTextStyle,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(34, 34),
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: const Color(0xF8FFFFFF),
      indicatorColor: const Color(0x1F2F80ED),
      shadowColor: const Color(0x240F2847),
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
        (states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? const Color(0xFF1E558B) : const Color(0xFF6B809D),
          );
        },
      ),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
        (states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? const Color(0xFF1F5B95) : const Color(0xFF7A8FA8),
            size: selected ? 22 : 20,
          );
        },
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFFFFFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD3E0F1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD3E0F1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6FA7E6), width: 1.35),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      hintStyle: const TextStyle(color: Color(0xFF8A9CB2), fontSize: 13),
      labelStyle: const TextStyle(color: Color(0xFF617690), fontSize: 13),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1F2F46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: const TextStyle(fontSize: 13, color: Color(0xFFF7FAFF)),
    ),
  );
}
