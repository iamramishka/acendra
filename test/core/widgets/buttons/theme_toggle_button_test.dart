import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acendra/app/providers/theme_mode_provider.dart';
import 'package:acendra/core/widgets/buttons/theme_toggle_button.dart';

class _FixedThemeModeNotifier extends ThemeModeNotifier {
  _FixedThemeModeNotifier(this._initial);
  final ThemeMode _initial;

  @override
  ThemeMode build() => _initial;
}

Widget _scope(ThemeMode mode) => ProviderScope(
  overrides: [
    themeModeProvider.overrideWith(() => _FixedThemeModeNotifier(mode)),
  ],
  child: const MaterialApp(home: Scaffold(body: ThemeToggleButton())),
);

void main() {
  testWidgets('shows dark_mode icon when theme is light', (tester) async {
    await tester.pumpWidget(_scope(ThemeMode.light));
    expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    expect(find.byIcon(Icons.light_mode), findsNothing);
  });

  testWidgets('shows light_mode icon when theme is dark', (tester) async {
    await tester.pumpWidget(_scope(ThemeMode.dark));
    expect(find.byIcon(Icons.light_mode), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode), findsNothing);
  });

  testWidgets('tapping toggles icon from dark to light', (tester) async {
    await tester.pumpWidget(_scope(ThemeMode.dark));
    expect(find.byIcon(Icons.light_mode), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pump();

    expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    expect(find.byIcon(Icons.light_mode), findsNothing);
  });
}
