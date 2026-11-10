import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

abstract final class AppColors {
  static const background = Color(0xFF0B0B0F);
  static const surface = Color(0xFF0E0E12);
  static const primary = Color(0xFFC8A2B7);
  static const text = Color(0xFFF5F1EA);
  static const muted = Color(0xFF9CA3AF);
  static const placeholder = Color(0xFF6B7C93);
  static const border = Color(0x599CA3AF);
}

abstract final class AppTheme {
  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.background,
      secondary: AppColors.primary,
      onSecondary: AppColors.background,
      secondaryContainer: Color(0x2EC8A2B7),
      onSecondaryContainer: AppColors.text,
      surface: AppColors.surface,
      onSurface: AppColors.text,
    ),
    chipTheme: const ChipThemeData(showCheckmark: false),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.placeholder, fontSize: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size(double.infinity, 49),
      ),
    ),
  );
}

class RevelaScrollBehavior extends MaterialScrollBehavior {
  const RevelaScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
  };
}
