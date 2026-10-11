import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: ThemeData(useMaterial3: true),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('primary button fires onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(AppButton(label: 'Go', onPressed: () => tapped = true)),
    );
    await tester.tap(find.byType(AppButton));
    expect(tapped, isTrue);
  });

  testWidgets('button does not fire when isLoading', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        AppButton(label: 'Go', onPressed: () => tapped = true, isLoading: true),
      ),
    );
    await tester.tap(find.byType(AppButton));
    expect(tapped, isFalse);
  });

  testWidgets('button does not fire when onPressed is null', (tester) async {
    await tester.pumpWidget(
      _wrap(const AppButton(label: 'Go', onPressed: null)),
    );
    await tester.tap(find.byType(AppButton));
  });

  testWidgets('destructive variant renders without error', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppButton(
          label: 'Delete',
          onPressed: () {},
          variant: ButtonVariant.destructive,
        ),
      ),
    );
    expect(find.byType(AppButton), findsOneWidget);
  });

  testWidgets('small size renders without error', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppButton(label: 'Small', onPressed: () {}, size: ButtonSize.small),
      ),
    );
    expect(find.byType(AppButton), findsOneWidget);
  });

  testWidgets('outlined variant renders without error', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppButton(
          label: 'Outline',
          onPressed: () {},
          variant: ButtonVariant.outlined,
        ),
      ),
    );
    expect(find.byType(AppButton), findsOneWidget);
  });
}
