import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF008F83);
  static const Color primaryLight = Color(0xFF54B7AE);
  static const Color primaryDark = Color(0xFF006B62);
  static const Color iconBackground = Color(0xFFE7F8F6);
  static const Color backgroundColor = Color(0xFFF5F7F9);
  static const Color cardColor = Colors.white;
  static const Color surfaceColor = cardColor;
  static const Color textPrimary = Color(0xFF1D1F22);
  static const Color textSecondary = Color(0xFF5F6871);
  static const Color statusActiveBg = Color(0xFFE8F5E9);
  static const Color statusActiveText = Color(0xFF198754);
  static const Color statusDraftBg = Color(0xFFFEF9E7);
  static const Color statusDraftText = Color(0xFFE4A11B);
  static const Color statusInactiveBg = Color(0xFFFCE8E6);
  static const Color statusInactiveText = Color(0xFFD93025);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryColor, primaryLight],
  );

  /// Visual tokens used only by the teacher (skill provider) area.
  static const Color teacherAccentEmerald = Color(0xFF059669);
  static const Color teacherAccentAmber = Color(0xFFD97706);
  static const Color teacherAccentCoral = Color(0xFFE11D48);
  static const Color teacherAccentIndigo = Color(0xFF4F46E5);
  static const Color teacherAccentViolet = Color(0xFF7C3AED);
  static const Color teacherAccentSky = Color(0xFF0284C7);
  static const Color teacherPageBackground = Color(0xFFF1F6F5);
  static const double teacherCardRadius = 18;

  static const LinearGradient teacherHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF064E48),
      Color(0xFF0F766E),
      Color(0xFF2DD4BF),
    ],
    stops: [0.0, 0.48, 1.0],
  );

  static BoxDecoration get teacherCardDecoration => BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(teacherCardRadius),
        border: Border.all(color: const Color(0xFFE3EEEC)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration teacherTintedCard(Color accent) => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.16),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(teacherCardRadius),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      surface: cardColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: primaryColor),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
