import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/register_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/reset_password_screen.dart';
import 'package:acendra/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/features/marketplace/presentation/screens/course_detail_screen.dart';
import 'package:acendra/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:acendra/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'marketplace/fakes/fake_course_repository.dart';

void main() {
  const screens = <String, Widget>{
    'registration': RegisterScreen(),
    'forgot password': ForgotPasswordScreen(),
    'reset password': ResetPasswordScreen(),
    'checkout': CheckoutScreen(courseId: 'fake-id-1'),
    'course details': CourseDetailScreen(courseId: 'fake-id-1'),
    'catalog': MarketplaceScreen(),
    'settings': SettingsScreen(),
  };
  for (final entry in screens.entries) {
    for (final width in [320.0, 390.0, 768.0, 1440.0]) {
      for (final dark in [false, true]) {
        testWidgets('${entry.key} at $width, 200% text, dark=$dark', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                courseRepositoryProvider.overrideWithValue(
                  FakeCourseRepository(
                    result: [fakeCourse],
                    detail: fakeDetail,
                  ),
                ),
              ],
              child: MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!,
                ),
                home: Scaffold(body: entry.value),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
