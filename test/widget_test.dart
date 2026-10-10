// Widget smoke test for AcendraApp.
import 'package:acendra/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AcendraApp renders without crashing', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AcendraApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
