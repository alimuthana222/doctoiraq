import 'package:flutter/material.dart';

class NabdaColors {
  static const primary = Color(0xFF0B6E6E);
  static const dark = Color(0xFF102A43);
  static const accent = Color(0xFF4DD3C2);
  static const success = Color(0xFF2BB673);
  static const light = Color(0xFFF8FAFC);
}

class NabdaTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: NabdaColors.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: NabdaColors.primary,
        primary: NabdaColors.primary,
        secondary: NabdaColors.accent,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: NabdaColors.dark,
      ),
      fontFamily: 'Tajawal',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: NabdaColors.dark,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: NabdaColors.dark),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: NabdaColors.dark),
      ),
    );

    return base.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDEE7EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDEE7EF)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NabdaColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white,
        selectedColor: NabdaColors.accent.withValues(alpha: .25),
      ),
    );
  }

  static const primaryGradient = LinearGradient(
    colors: [NabdaColors.primary, NabdaColors.accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
