import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/authentication/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final width in [320.0, 390.0, 768.0, 1440.0]) {
      testWidgets(
        'sign-in renders at $width with production $brightness theme',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: brightness == Brightness.dark
                    ? AppTheme.dark
                    : AppTheme.light,
                home: const LoginScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Sign in to Acedra'), findsOneWidget);
          expect(find.byType(TextField), findsNWidgets(2));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
