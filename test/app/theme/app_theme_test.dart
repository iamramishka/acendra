import 'package:acendra/app/providers/theme_mode_provider.dart';
import 'package:acendra/app/theme/app_colors.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppColors', () {
    test('light primary matches design spec', () {
      expect(AppColors.light.primary, const Color(0xFF1259DB));
    });

    test('dark primary matches design spec', () {
      expect(AppColors.dark.primary, const Color(0xFF78ABFF));
    });

    test('light background matches design spec', () {
      expect(AppColors.light.background, const Color(0xFFF5F8FC));
    });

    test('dark background matches design spec', () {
      expect(AppColors.dark.background, const Color(0xFF081329));
    });
  });

  group('AppSpacing', () {
    test('md is 16', () => expect(AppSpacing.md, 16.0));
    test('lg is 24', () => expect(AppSpacing.lg, 24.0));
  });

  group('AppRadius', () {
    test('button radius is 12', () => expect(AppRadius.button, 12.0));
    test('card radius is 18', () => expect(AppRadius.card, 18.0));
  });

  group('AppThemeExtension', () {
    test('fromTokens light maps success colour', () {
      final ext = AppThemeExtension.fromTokens(AppColors.light);
      expect(ext.success, AppColors.light.success);
      expect(ext.warning, AppColors.light.warning);
      expect(ext.focusRing, AppColors.light.focusRing);
    });

    test('fromTokens dark maps success colour', () {
      final ext = AppThemeExtension.fromTokens(AppColors.dark);
      expect(ext.success, AppColors.dark.success);
      expect(ext.warning, AppColors.dark.warning);
      expect(ext.border, AppColors.dark.border);
    });

    test('lerp interpolates correctly', () {
      final a = AppThemeExtension.fromTokens(AppColors.light);
      final b = AppThemeExtension.fromTokens(AppColors.dark);
      final mid = a.lerp(b, 0.5);
      expect(mid.success, Color.lerp(a.success, b.success, 0.5));
    });
  });

  group('ThemeModeNotifier', () {
    test('starts as system', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('toggle switches light->dark->light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeModeProvider.notifier).setMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);
      container.read(themeModeProvider.notifier).toggle();
      expect(container.read(themeModeProvider), ThemeMode.dark);
      container.read(themeModeProvider.notifier).toggle();
      expect(container.read(themeModeProvider), ThemeMode.light);
    });
  });
}
