import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('AppTextField renders label', (tester) async {
    await tester.pumpWidget(_wrap(
      const AppTextField(label: 'Email'),
    ));
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('AppTextField shows errorText', (tester) async {
    await tester.pumpWidget(_wrap(
      const AppTextField(label: 'Email', errorText: 'Required'),
    ));
    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('AppPasswordField starts obscured', (tester) async {
    await tester.pumpWidget(_wrap(
      const AppPasswordField(label: 'Password'),
    ));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isTrue);
  });

  testWidgets('AppPasswordField toggles obscureText on icon tap', (tester) async {
    await tester.pumpWidget(_wrap(
      const AppPasswordField(label: 'Password'),
    ));
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isFalse);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
  });
}
