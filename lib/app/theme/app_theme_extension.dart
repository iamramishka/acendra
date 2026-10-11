import 'package:acendra/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.focusRing,
    required this.surfaceSecondary,
    required this.surfaceTertiary,
    required this.textSecondary,
    required this.border,
  });

  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color focusRing;
  final Color surfaceSecondary;
  final Color surfaceTertiary;
  final Color textSecondary;
  final Color border;

  static AppThemeExtension fromTokens(AppColorTokens t) => AppThemeExtension(
    success: t.success,
    successContainer: t.successContainer,
    warning: t.warning,
    warningContainer: t.warningContainer,
    focusRing: t.focusRing,
    surfaceSecondary: t.surfaceSecondary,
    surfaceTertiary: t.surfaceTertiary,
    textSecondary: t.textSecondary,
    border: t.border,
  );

  @override
  AppThemeExtension copyWith({
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? focusRing,
    Color? surfaceSecondary,
    Color? surfaceTertiary,
    Color? textSecondary,
    Color? border,
  }) => AppThemeExtension(
    success: success ?? this.success,
    successContainer: successContainer ?? this.successContainer,
    warning: warning ?? this.warning,
    warningContainer: warningContainer ?? this.warningContainer,
    focusRing: focusRing ?? this.focusRing,
    surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
    surfaceTertiary: surfaceTertiary ?? this.surfaceTertiary,
    textSecondary: textSecondary ?? this.textSecondary,
    border: border ?? this.border,
  );

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      surfaceSecondary: Color.lerp(
        surfaceSecondary,
        other.surfaceSecondary,
        t,
      )!,
      surfaceTertiary: Color.lerp(surfaceTertiary, other.surfaceTertiary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}
