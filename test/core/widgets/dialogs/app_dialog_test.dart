import 'package:acendra/core/widgets/dialogs/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(VoidCallback onPressed) => MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: onPressed,
            child: const Text('Open'),
          ),
        ),
      ),
    );

void main() {
  group('AppDialog', () {
    testWidgets('shows title and body text', (tester) async {
      await tester.pumpWidget(_app(() {}));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => AppDialog.show(
                  ctx,
                  title: 'Delete item',
                  body: 'Are you sure?',
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Delete item'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);
    });

    testWidgets('tapping confirm button returns true', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await AppDialog.show(ctx, title: 'T', body: 'B');
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('tapping cancel button returns false', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await AppDialog.show(ctx, title: 'T', body: 'B');
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('custom confirmLabel and cancelLabel appear', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => AppDialog.show(
                  ctx,
                  title: 'T',
                  body: 'B',
                  confirmLabel: 'Yes, delete',
                  cancelLabel: 'Go back',
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Yes, delete'), findsOneWidget);
      expect(find.text('Go back'), findsOneWidget);
    });
  });
}
