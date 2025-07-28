import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF2D2D2D);
  static const Color background = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF1a1a1a);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderError = Color(0xFFEF4444);
  static const Color errorBackground = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFECACA);
  static const Color errorText = Color(0xFFDC2626);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'SF Pro Display',
      colorScheme: const ColorScheme.light(
        primary: primary,
        surface: background,
      ),
      scaffoldBackgroundColor: background,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'SF Pro Display',
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: backgroundDark,
      ),
      scaffoldBackgroundColor: backgroundDark,
    );
  }
}
