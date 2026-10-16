// Widget smoke test for AcendraApp.
// Requires browser platform (transitively uses dart:js_interop via go_router).
@TestOn('browser')
library;

import 'package:acendra/app/app.dart';
import 'package:acendra/core/widgets/navigation/auth_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AcendraApp renders without crashing', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AcendraApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(AuthShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
