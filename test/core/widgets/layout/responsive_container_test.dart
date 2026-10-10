import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/core/widgets/layout/responsive_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('layout is compact below 600', (tester) async {
    tester.view.physicalSize = const Size(599, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    ScreenLayout? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            captured = ctx.layout;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(captured, ScreenLayout.compact);
  });

  testWidgets('layout is medium at 600', (tester) async {
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    ScreenLayout? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            captured = ctx.layout;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(captured, ScreenLayout.medium);
  });

  testWidgets('layout is medium at 1023', (tester) async {
    tester.view.physicalSize = const Size(1023, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    ScreenLayout? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            captured = ctx.layout;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(captured, ScreenLayout.medium);
  });

  testWidgets('layout is expanded at 1024', (tester) async {
    tester.view.physicalSize = const Size(1024, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    ScreenLayout? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            captured = ctx.layout;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(captured, ScreenLayout.expanded);
  });

  testWidgets('ResponsiveContainer renders child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveContainer(child: Text('hello')),
        ),
      ),
    );
    expect(find.text('hello'), findsOneWidget);
  });
}
