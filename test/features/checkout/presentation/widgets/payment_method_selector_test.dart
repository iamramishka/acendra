import 'package:acendra/features/checkout/domain/entities/payment_method.dart';
import 'package:acendra/features/checkout/presentation/widgets/payment_method_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestWidget({
  required PaymentMethod selected,
  required ValueChanged<PaymentMethod> onChanged,
}) => MaterialApp(
  home: Scaffold(
    body: PaymentMethodSelector(selected: selected, onChanged: onChanged),
  ),
);

bool? _selected(WidgetTester tester, PaymentMethod method) {
  final control = find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.label == method.label,
  );
  expect(control, findsOneWidget);
  return tester
      .getSemantics(control)
      .getSemanticsData()
      .flagsCollection
      .isSelected
      .toBoolOrNull();
}

void main() {
  testWidgets('renders both payment methods and descriptions', (tester) async {
    await tester.pumpWidget(
      _buildTestWidget(selected: PaymentMethod.online, onChanged: (_) {}),
    );
    for (final method in PaymentMethod.values) {
      expect(find.text(method.label), findsOneWidget);
      expect(find.text(method.description), findsOneWidget);
    }
  });

  for (final method in PaymentMethod.values) {
    testWidgets('tapping ${method.label} reports the correct payment method', (
      tester,
    ) async {
      PaymentMethod? changedTo;
      await tester.pumpWidget(
        _buildTestWidget(
          selected: PaymentMethod.online,
          onChanged: (value) => changedTo = value,
        ),
      );
      await tester.tap(find.text(method.label));
      await tester.pump();
      expect(changedTo, method);
    });
    testWidgets('${method.label} exposes its selected accessibility state', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestWidget(selected: PaymentMethod.online, onChanged: (_) {}),
      );
      expect(_selected(tester, method), method == PaymentMethod.online);
    });
  }

  testWidgets('switching selection updates both accessible states', (
    tester,
  ) async {
    var selected = PaymentMethod.online;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => _buildTestWidget(
          selected: selected,
          onChanged: (value) => setState(() => selected = value),
        ),
      ),
    );
    expect(_selected(tester, PaymentMethod.online), isTrue);
    expect(_selected(tester, PaymentMethod.bankTransfer), isFalse);
    await tester.tap(find.text('Bank Transfer'));
    await tester.pumpAndSettle();
    expect(_selected(tester, PaymentMethod.bankTransfer), isTrue);
    expect(_selected(tester, PaymentMethod.online), isFalse);
  });
}
