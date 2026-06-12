import 'package:flutter/material.dart';

class AppTheme {
  // Bento Minimalist Colors
  static const Color background = Color(0xFFF9F9F9);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color buttonX = Color(0xFFFF5A5F); // Vibrant Orange/Red
  static const Color buttonHeart = Color(0xFF007AFF); // Electric Blue

  static ThemeData get bentoTheme {
    return ThemeData(
      scaffoldBackgroundColor: background,
      primaryColor: buttonHeart,
      fontFamily: 'Inter', // A generic sans-serif fallback, flutter defaults to Roboto/SF Pro
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
