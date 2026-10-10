import 'package:acendra/app/theme/app_colors.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppColors', () {
    test('light primary matches design spec', () {
      expect(AppColors.light.primary, const Color(0xFF5146E5));
    });

    test('dark primary matches design spec', () {
      expect(AppColors.dark.primary, const Color(0xFFA7A8FF));
    });

    test('light background matches design spec', () {
      expect(AppColors.light.background, const Color(0xFFF6F8FC));
    });

    test('dark background matches design spec', () {
      expect(AppColors.dark.background, const Color(0xFF0B1020));
    });
  });

  group('AppSpacing', () {
    test('md is 16', () => expect(AppSpacing.md, 16.0));
    test('lg is 24', () => expect(AppSpacing.lg, 24.0));
  });
}
