import 'package:acendra/app/theme/app_colors.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/app/theme/app_typography.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light =>
      _build(brightness: Brightness.light, tokens: AppColors.light);

  static ThemeData get dark =>
      _build(brightness: Brightness.dark, tokens: AppColors.dark);

  static ThemeData _build({
    required Brightness brightness,
    required AppColorTokens tokens,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      // Primary — Royal Blue / Sky Cyan for dark
      primary: tokens.primary,
      onPrimary: tokens.onPrimary,
      primaryContainer: tokens.primaryContainer,
      onPrimaryContainer: tokens.onPrimaryContainer,
      // Secondary mirrors primary (same brand colour family)
      secondary: tokens.primary,
      onSecondary: tokens.onPrimary,
      secondaryContainer: tokens.primaryContainer,
      onSecondaryContainer: tokens.onPrimaryContainer,
      // Tertiary → Sky Cyan accent
      tertiary: tokens.accent,
      onTertiary: tokens.onPrimary,
      tertiaryContainer: tokens.accentContainer,
      onTertiaryContainer: tokens.accent,
      error: tokens.error,
      onError: tokens.onPrimary,
      errorContainer: tokens.errorContainer,
      onErrorContainer: tokens.error,
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
      onSurfaceVariant: tokens.textSecondary,
      outline: tokens.border,
      outlineVariant: tokens.border,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: tokens.textPrimary,
      onInverseSurface: tokens.surface,
      inversePrimary: tokens.primaryContainer,
    );

    final textTheme = AppTypography.textTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: [AppThemeExtension.fromTokens(tokens)],
      textTheme: textTheme,
      scaffoldBackgroundColor: tokens.background,

      cardTheme: CardThemeData(
        color: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: tokens.border),
        ),
        elevation: 0,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: tokens.surface,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xs,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: tokens.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: tokens.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: tokens.error, width: 2),
        ),
        errorStyle: TextStyle(color: tokens.error, fontSize: 12, height: 1.4),
        errorMaxLines: 2,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.primary,
          side: BorderSide(color: tokens.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: tokens.border,
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: tokens.surfaceSecondary,
        labelStyle: textTheme.bodySmall,
        side: BorderSide(color: tokens.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),
    );
  }
}
