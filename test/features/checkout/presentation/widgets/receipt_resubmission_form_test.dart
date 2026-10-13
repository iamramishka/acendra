import 'dart:async';
import 'dart:typed_data';

import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/features/checkout/presentation/services/receipt_file.dart';
import 'package:acendra/features/checkout/presentation/widgets/receipt_resubmission_form.dart';
import 'package:acendra/features/bank_transfer/presentation/screens/receipt_resubmission_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child, {bool dark = false}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  home: Scaffold(body: child),
);
Finder get submit => find.widgetWithText(AppButton, 'Submit New Receipt');
Future<void> pick(WidgetTester tester) async {
  await tester.tap(
    find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == 'Select receipt file',
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'valid selection never enables unavailable submission or reports success',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        wrap(
          ReceiptResubmissionForm(
            orderId: 'order-1',
            filePicker: () async {
              calls++;
              return ReceiptFile(
                name: 'receipt.jpg',
                bytes: Uint8List.fromList([1, 2, 3]),
              );
            },
          ),
        ),
      );
      await pick(tester);
      expect(calls, 1);
      expect(find.text('receipt.jpg'), findsOneWidget);
      expect(tester.widget<AppButton>(submit).onPressed, isNull);
      await tester.tap(submit);
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('submitted successfully'), findsNothing);
      expect(find.textContaining('temporarily unavailable'), findsOneWidget);
    },
  );
  for (final entry in <String, int>{
    'empty.jpg': 0,
    'large.pdf': maxReceiptBytes + 1,
    'receipt.png': 10,
  }.entries) {
    testWidgets('rejects invalid selection ${entry.key}', (tester) async {
      await tester.pumpWidget(
        wrap(
          ReceiptResubmissionForm(
            orderId: 'order-1',
            filePicker: () async =>
                ReceiptFile(name: entry.key, bytes: Uint8List(entry.value)),
          ),
        ),
      );
      await pick(tester);
      expect(tester.widget<AppButton>(submit).onPressed, isNull);
      expect(find.text(entry.key), findsNothing);
      expect(
        find.textContaining(
          entry.value == 0
              ? 'empty'
              : entry.value > maxReceiptBytes
              ? 'too large'
              : 'Only JPG and PDF',
        ),
        findsOneWidget,
      );
    });
  }
  testWidgets('cancel preserves selected file', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      wrap(
        ReceiptResubmissionForm(
          orderId: 'order-1',
          filePicker: () async => calls++ == 0
              ? ReceiptFile(name: 'receipt.pdf', bytes: Uint8List(1))
              : null,
        ),
      ),
    );
    await pick(tester);
    await pick(tester);
    expect(find.text('receipt.pdf'), findsOneWidget);
  });
  testWidgets('picker failure is sanitized', (tester) async {
    await tester.pumpWidget(
      wrap(
        ReceiptResubmissionForm(
          orderId: 'order-1',
          filePicker: () async => throw StateError('private/path'),
        ),
      ),
    );
    await pick(tester);
    expect(find.textContaining('Could not read'), findsOneWidget);
    expect(find.textContaining('private/path'), findsNothing);
  });
  testWidgets('completion after disposal is harmless', (tester) async {
    final pending = Completer<ReceiptFile?>();
    await tester.pumpWidget(
      wrap(
        ReceiptResubmissionForm(
          orderId: 'order-1',
          filePicker: () => pending.future,
        ),
      ),
    );
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Select receipt file',
      ),
    );
    await tester.pumpWidget(wrap(const SizedBox()));
    pending.complete(ReceiptFile(name: 'receipt.pdf', bytes: Uint8List(1)));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  for (final dark in [false, true]) {
    testWidgets('canonical screen uses shared form at 390px, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        wrap(
          const ReceiptResubmissionScreen(
            orderId: 'order-1',
            rejectionReason: 'Reference not visible.',
          ),
          dark: dark,
        ),
      );
      expect(find.byType(ReceiptResubmissionForm), findsOneWidget);
      expect(find.text('Reference not visible.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  test(
    'size and extension boundaries use the same validation as browser selection',
    () {
      expect(receiptFileError('receipt.JPEG', maxReceiptBytes), isNull);
      expect(receiptFileError('receipt.pdf', maxReceiptBytes + 1), isNotNull);
      expect(receiptFileError('receipt.jpg', 0), isNotNull);
    },
  );
}
