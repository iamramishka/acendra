import 'package:acendra/features/checkout/domain/entities/payment_method.dart';
import 'package:acendra/features/checkout/presentation/widgets/payment_method_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestWidget({
  required PaymentMethod selected,
  required ValueChanged<PaymentMethod> onChanged,
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: PaymentMethodSelector(
            selected: selected,
            onChanged: onChanged,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('PaymentMethodSelector', () {
    testWidgets('renders both payment method cards', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          selected: PaymentMethod.online,
          onChanged: (_) {},
        ),
      );

      expect(find.text('Online Payment'), findsOneWidget);
      expect(find.text('Bank Transfer'), findsOneWidget);
    });

    testWidgets('renders descriptions for both payment methods',
        (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          selected: PaymentMethod.online,
          onChanged: (_) {},
        ),
      );

      expect(
        find.text(
          'Pay instantly with a credit or debit card via PayHere.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Deposit to our bank account and submit your receipt.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping unselected card fires onChanged with correct value',
        (tester) async {
      PaymentMethod? changedTo;

      await tester.pumpWidget(
        _buildTestWidget(
          selected: PaymentMethod.online,
          onChanged: (method) => changedTo = method,
        ),
      );

      await tester.tap(find.text('Bank Transfer'));
      await tester.pump();

      expect(changedTo, equals(PaymentMethod.bankTransfer));
    });

    testWidgets('tapping already-selected card fires onChanged with same value',
        (tester) async {
      PaymentMethod? changedTo;

      await tester.pumpWidget(
        _buildTestWidget(
          selected: PaymentMethod.online,
          onChanged: (method) => changedTo = method,
        ),
      );

      await tester.tap(find.text('Online Payment'));
      await tester.pump();

      expect(changedTo, equals(PaymentMethod.online));
    });

    testWidgets('selected card has Semantics selected=true', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          selected: PaymentMethod.online,
          onChanged: (_) {},
        ),
      );

      final selectedSemantics = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.text('Online Payment'),
              matching: find.byType(Semantics),
            )
            .first,
      );

      expect(selectedSemantics.properties.selected, isTrue);
    });

    testWidgets('unselected card has Semantics selected=false', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          selected: PaymentMethod.online,
          onChanged: (_) {},
        ),
      );

      final unselectedSemantics = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.text('Bank Transfer'),
              matching: find.byType(Semantics),
            )
            .first,
      );

      expect(unselectedSemantics.properties.selected, isFalse);
    });

    testWidgets('switching selection updates visual state', (tester) async {
      PaymentMethod currentSelection = PaymentMethod.online;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return ProviderScope(
              child: MaterialApp(
                theme: ThemeData.light(),
                home: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: PaymentMethodSelector(
                      selected: currentSelection,
                      onChanged: (method) =>
                          setState(() => currentSelection = method),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      // Initially Online Payment is selected
      expect(
        tester
            .widget<Semantics>(
              find
                  .ancestor(
                    of: find.text('Online Payment'),
                    matching: find.byType(Semantics),
                  )
                  .first,
            )
            .properties
            .selected,
        isTrue,
      );

      // Tap Bank Transfer
      await tester.tap(find.text('Bank Transfer'));
      await tester.pump();

      // Now Bank Transfer should be selected
      expect(
        tester
            .widget<Semantics>(
              find
                  .ancestor(
                    of: find.text('Bank Transfer'),
                    matching: find.byType(Semantics),
                  )
                  .first,
            )
            .properties
            .selected,
        isTrue,
      );

      // And Online Payment should be unselected
      expect(
        tester
            .widget<Semantics>(
              find
                  .ancestor(
                    of: find.text('Online Payment'),
                    matching: find.byType(Semantics),
                  )
                  .first,
            )
            .properties
            .selected,
        isFalse,
      );
    });
  });
}
