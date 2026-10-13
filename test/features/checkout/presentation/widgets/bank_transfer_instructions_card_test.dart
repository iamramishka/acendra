import 'package:acendra/app/theme/app_colors.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/features/checkout/domain/entities/bank_transfer_details.dart';
import 'package:acendra/features/checkout/presentation/widgets/bank_transfer_instructions_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

const _mockDetails = BankTransferDetails(
  bankName: 'Bank of Ceylon',
  accountName: 'Acendra (Pvt) Ltd',
  accountNumber: '0123456789',
  branch: 'Colombo 03',
  amount: 12500.00,
  currency: 'LKR',
  referenceId: 'ORD-TEST-99999',
);

/// Wraps the card in a [MaterialApp] with the given [brightness].
Widget _buildCard({
  Brightness brightness = Brightness.light,
  VoidCallback? onConfirmTransfer,
}) {
  const lightTokens = AppColors.light;
  const darkTokens = AppColors.dark;

  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.light,
      ),
      extensions: [AppThemeExtension.fromTokens(lightTokens)],
    ),
    darkTheme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.dark,
      ),
      extensions: [AppThemeExtension.fromTokens(darkTokens)],
    ),
    themeMode:
        brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BankTransferInstructionsCard(
            details: _mockDetails,
            onConfirmTransfer: onConfirmTransfer,
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('BankTransferInstructionsCard', () {
    testWidgets('renders heading', (tester) async {
      await tester.pumpWidget(_buildCard());
      expect(find.text('Bank Transfer Instructions'), findsOneWidget);
    });

    testWidgets('renders bank name', (tester) async {
      await tester.pumpWidget(_buildCard());
      expect(find.text('Bank of Ceylon'), findsOneWidget);
    });

    testWidgets('renders account number', (tester) async {
      await tester.pumpWidget(_buildCard());
      expect(find.text('0123456789'), findsOneWidget);
    });

    testWidgets('renders reference ID', (tester) async {
      await tester.pumpWidget(_buildCard());
      expect(find.text('ORD-TEST-99999'), findsOneWidget);
    });

    testWidgets('renders formatted amount', (tester) async {
      await tester.pumpWidget(_buildCard());
      expect(find.text('LKR 12,500.00'), findsOneWidget);
    });

    testWidgets('renders account name', (tester) async {
      await tester.pumpWidget(_buildCard());
      expect(find.text('Acendra (Pvt) Ltd'), findsOneWidget);
    });

    testWidgets('renders branch', (tester) async {
      await tester.pumpWidget(_buildCard());
      expect(find.text('Colombo 03'), findsOneWidget);
    });

    testWidgets('renders warning note', (tester) async {
      await tester.pumpWidget(_buildCard());
      expect(
        find.textContaining('Access is granted only after finance approval'),
        findsOneWidget,
      );
    });

    testWidgets('copy button exists and has accessible semantics',
        (tester) async {
      await tester.pumpWidget(_buildCard());

      // The IconButton for copying should be present.
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);

      // Semantics node with the reference ID in its label should exist.
      expect(
        find.bySemanticsLabel(
          RegExp(r'Copy reference ID ORD-TEST-99999'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('confirm button calls onConfirmTransfer', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _buildCard(onConfirmTransfer: () => tapped = true),
      );

      // Scroll the confirm button into view before tapping.
      final btnFinder = find.text("I've Completed the Transfer");
      await tester.scrollUntilVisible(btnFinder, 100);
      await tester.pump();
      await tester.tap(btnFinder);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('confirm button is disabled when onConfirmTransfer is null',
        (tester) async {
      await tester.pumpWidget(_buildCard());

      // The ElevatedButton should have a null onPressed when callback is null.
      final btn = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text("I've Completed the Transfer"),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('renders without overflow in light theme at 390px width',
        (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildCard());
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow in dark theme at 390px width',
        (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildCard(brightness: Brightness.dark));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at 768px width', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildCard());
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at 1440px width', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildCard());
      expect(tester.takeException(), isNull);
    });
  });
}
