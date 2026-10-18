import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/features/authentication/presentation/screens/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reset cannot submit weak or mismatched passwords', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ResetPasswordScreen(),
        ),
      ),
    );
    AppButton submit() => tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Update Password'),
    );
    expect(submit().onPressed, isNull);
    await tester.enterText(find.byType(TextField).at(0), 'abcdef');
    await tester.enterText(find.byType(TextField).at(1), 'abcdef');
    await tester.pump();
    expect(submit().onPressed, isNull);
    await tester.enterText(find.byType(TextField).at(0), 'Learning123');
    await tester.enterText(find.byType(TextField).at(1), 'Learning124');
    await tester.pump();
    expect(submit().onPressed, isNull);
    await tester.enterText(find.byType(TextField).at(1), 'Learning123');
    await tester.pump();
    expect(submit().onPressed, isNotNull);
    expect(find.byTooltip('Show password'), findsNWidgets(2));
  });
}
