import 'package:acendra/app/providers/theme_mode_provider.dart';
import 'package:acendra/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('theme control can select Light, Dark and System again', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.tap(find.text('Dark'));
    await tester.pump();
    expect(container.read(themeModeProvider), ThemeMode.dark);

    await tester.tap(find.text('Light'));
    await tester.pump();
    expect(container.read(themeModeProvider), ThemeMode.light);

    await tester.tap(find.text('System'));
    await tester.pump();
    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  testWidgets('shows change password and sign out', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );
    expect(find.text('Change password'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });
}
