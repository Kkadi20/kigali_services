import 'package:flutter/material.dart';

// App color palette — used across all screens for consistent styling
class AppColors {
  static const Color background     = Color(0xFF0D1B2A);
  static const Color surface        = Color(0xFF1A2B3C);
  static const Color cardColor      = Color(0xFF1E3048);
  static const Color accent         = Color(0xFFF5A623);
  static const Color accentLight    = Color(0xFFFFD166);
  static const Color textPrimary    = Color(0xFFFFFFFF);
  static const Color textSecondary  = Color(0xFFADB5BD);
  static const Color textMuted      = Color(0xFF6C757D);
  static const Color success        = Color(0xFF28A745);
  static const Color error          = Color(0xFFDC3545);
  static const Color divider        = Color(0xFF2A3F55);
  static const Color chipSelected   = Color(0xFFF5A623);
  static const Color chipUnselected = Color(0xFF1E3048);
}

// Dark navy theme applied to the entire app via MaterialApp
class AppTheme {
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.accent,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      surface: AppColors.surface,
      error:   AppColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: AppColors.textMuted),
      prefixIconColor: AppColors.textMuted,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      titleLarge:     TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      titleMedium:    TextStyle(color: AppColors.textPrimary),
      bodyLarge:      TextStyle(color: AppColors.textPrimary),
      bodyMedium:     TextStyle(color: AppColors.textSecondary),
      bodySmall:      TextStyle(color: AppColors.textMuted),
    ),
  );
}