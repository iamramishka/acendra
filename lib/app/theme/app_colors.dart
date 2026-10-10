import 'package:flutter/material.dart';

@immutable
class AppColorTokens {
  const AppColorTokens({
    required this.background,
    required this.surface,
    required this.surfaceSecondary,
    required this.surfaceTertiary,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.error,
    required this.errorContainer,
    required this.focusRing,
  });

  final Color background;
  final Color surface;
  final Color surfaceSecondary;
  final Color surfaceTertiary;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color error;
  final Color errorContainer;
  final Color focusRing;
}

abstract final class AppColors {
  static const light = AppColorTokens(
    background: Color(0xFFF6F8FC),
    surface: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFEEF2FA),
    surfaceTertiary: Color(0xFFE6EAF6),
    textPrimary: Color(0xFF101828),
    textSecondary: Color(0xFF5B667A),
    border: Color(0xFFE0E6F0),
    primary: Color(0xFF5146E5),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFEEECFF),
    onPrimaryContainer: Color(0xFF473CC2),
    success: Color(0xFF147D43),
    successContainer: Color(0xFFE9F8EF),
    warning: Color(0xFFA85B00),
    warningContainer: Color(0xFFFFF4DF),
    error: Color(0xFFB42318),
    errorContainer: Color(0xFFFFF0EF),
    focusRing: Color(0xFFF59E0B),
  );

  static const dark = AppColorTokens(
    background: Color(0xFF0B1020),
    surface: Color(0xFF151D30),
    surfaceSecondary: Color(0xFF202B41),
    surfaceTertiary: Color(0xFF29374F),
    textPrimary: Color(0xFFF5F7FE),
    textSecondary: Color(0xFFB0BED4),
    border: Color(0xFF334158),
    primary: Color(0xFFA7A8FF),
    onPrimary: Color(0xFF11152C),
    primaryContainer: Color(0xFF28284D),
    onPrimaryContainer: Color(0xFFD1D1FF),
    success: Color(0xFF83E8AE),
    successContainer: Color(0xFF183C2F),
    warning: Color(0xFFF4BF70),
    warningContainer: Color(0xFF4A371B),
    error: Color(0xFFFF9F9B),
    errorContainer: Color(0xFF4F282F),
    focusRing: Color(0xFFF9C46B),
  );
}
