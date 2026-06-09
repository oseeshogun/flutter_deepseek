import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class StudioColors {
  static const background = Color(0xFF0A0E14);
  static const surface = Color(0xFF121820);
  static const surfaceElevated = Color(0xFF1A2332);
  static const border = Color(0xFF2A3544);
  static const accent = Color(0xFF4D9FFF);
  static const accentSoft = Color(0xFF1E3A5F);
  static const userGradientStart = Color(0xFF2563EB);
  static const userGradientEnd = Color(0xFF06B6D4);
  static const textPrimary = Color(0xFFF1F5F9);
  static const textMuted = Color(0xFF94A3B8);
  static const reasoning = Color(0xFFFBBF24);
}

ThemeData buildStudioTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: StudioColors.background,
    colorScheme: const ColorScheme.dark(
      primary: StudioColors.accent,
      surface: StudioColors.surface,
      onSurface: StudioColors.textPrimary,
    ),
  );

  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: StudioColors.textPrimary,
      displayColor: StudioColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: StudioColors.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: StudioColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: StudioColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: StudioColors.accent, width: 1.5),
      ),
      hintStyle: const TextStyle(color: StudioColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
  );
}
