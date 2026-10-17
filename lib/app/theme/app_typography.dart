import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Headings: Manrope (Bold/SemiBold) — premium, geometric
// Body/UI:  Inter  (Regular/Medium/SemiBold) — highly readable
abstract final class AppTypography {
  static TextTheme textTheme(ColorScheme colorScheme) {
    final inter = GoogleFonts.interTextTheme();

    return inter.copyWith(
      // ── Display (Manrope Bold) — landing hero, marketing headings ──
      displayLarge: GoogleFonts.manrope(
        fontSize: 52,
        fontWeight: FontWeight.w800,
        height: 1.10,
        letterSpacing: -1.0,
        color: colorScheme.onSurface,
      ),
      displayMedium: GoogleFonts.manrope(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.12,
        letterSpacing: -0.5,
        color: colorScheme.onSurface,
      ),
      displaySmall: GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
      ),

      // ── Headlines (Manrope SemiBold) — page/section headings ──
      headlineLarge: GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.20,
        color: colorScheme.onSurface,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: colorScheme.onSurface,
      ),
      headlineSmall: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.30,
        color: colorScheme.onSurface,
      ),

      // ── Titles (Inter SemiBold) — card titles, dialog headers ──
      titleLarge: inter.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: colorScheme.onSurface,
      ),
      titleMedium: inter.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.40,
        color: colorScheme.onSurface,
      ),
      titleSmall: inter.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.40,
        color: colorScheme.onSurface,
      ),

      // ── Body (Inter Regular) — reading content, descriptions ──
      bodyLarge: inter.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.60,
        color: colorScheme.onSurface,
      ),
      bodyMedium: inter.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.57,
        color: colorScheme.onSurface,
      ),
      bodySmall: inter.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.50,
        color: colorScheme.onSurfaceVariant,
      ),

      // ── Labels (Inter Medium/SemiBold) — buttons, nav, chips, tables ──
      labelLarge: inter.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      labelMedium: inter.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
      labelSmall: inter.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
