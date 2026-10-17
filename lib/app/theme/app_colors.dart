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
    required this.accent,
    required this.accentContainer,
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
  final Color accent;
  final Color accentContainer;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color error;
  final Color errorContainer;
  final Color focusRing;
}

// Acedra Horizon — brand palette v2
// Primary: Royal Blue  #1259DB
// Accent:  Sky Cyan    #1DA2FD
// Neutral: Deep Navy   #0D1633
abstract final class AppColors {
  static const Color royalBlue = Color(0xFF1259DB);
  static const Color skyCyan   = Color(0xFF1DA2FD);
  static const Color deepNavy  = Color(0xFF0D1633);
  static const Color softBlue  = Color(0xFFEAF3FF);

  static const light = AppColorTokens(
    background:         Color(0xFFF5F8FC),
    surface:            Color(0xFFFFFFFF),
    surfaceSecondary:   Color(0xFFEAF3FF),
    surfaceTertiary:    Color(0xFFD6E8FF),
    textPrimary:        Color(0xFF0D1633),
    textSecondary:      Color(0xFF54647E),
    border:             Color(0xFFDCE6F2),
    primary:            Color(0xFF1259DB),
    onPrimary:          Color(0xFFFFFFFF),
    primaryContainer:   Color(0xFFEAF3FF),
    onPrimaryContainer: Color(0xFF0D3A8C),
    accent:             Color(0xFF1DA2FD),
    accentContainer:    Color(0xFFE0F5FF),
    success:            Color(0xFF147D43),
    successContainer:   Color(0xFFE9F8EF),
    warning:            Color(0xFFA85B00),
    warningContainer:   Color(0xFFFFF4DF),
    error:              Color(0xFFB42318),
    errorContainer:     Color(0xFFFFF0EF),
    focusRing:          Color(0xFF1DA2FD),
  );

  static const dark = AppColorTokens(
    background:         Color(0xFF081329),
    surface:            Color(0xFF101E36),
    surfaceSecondary:   Color(0xFF182844),
    surfaceTertiary:    Color(0xFF1F3254),
    textPrimary:        Color(0xFFF5F8FF),
    textSecondary:      Color(0xFF8BA4C8),
    border:             Color(0xFF2A3B55),
    primary:            Color(0xFF78ABFF),
    onPrimary:          Color(0xFF081A40),
    primaryContainer:   Color(0xFF0F2A5C),
    onPrimaryContainer: Color(0xFFBDD6FF),
    accent:             Color(0xFF58D2F4),
    accentContainer:    Color(0xFF0A2E40),
    success:            Color(0xFF83E8AE),
    successContainer:   Color(0xFF183C2F),
    warning:            Color(0xFFF4BF70),
    warningContainer:   Color(0xFF4A371B),
    error:              Color(0xFFFF9F9B),
    errorContainer:     Color(0xFF4F282F),
    focusRing:          Color(0xFF58D2F4),
  );
}
