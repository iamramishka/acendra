import 'package:acendra/core/widgets/feedback/app_skeleton.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('AppSkeleton renders', (tester) async {
    await tester.pumpWidget(_wrap(
      const AppSkeleton(width: 100, height: 20),
    ));
    expect(find.byType(AppSkeleton), findsOneWidget);
  });

  testWidgets('AppEmptyState shows message', (tester) async {
    await tester.pumpWidget(_wrap(
      const AppEmptyState(message: 'No courses yet'),
    ));
    expect(find.text('No courses yet'), findsOneWidget);
  });

  testWidgets('AppEmptyState fires onAction when provided', (tester) async {
    var acted = false;
    await tester.pumpWidget(_wrap(
      AppEmptyState(
        message: 'Empty',
        actionLabel: 'Browse',
        onAction: () => acted = true,
      ),
    ));
    await tester.tap(find.text('Browse'));
    expect(acted, isTrue);
  });

  testWidgets('AppErrorState fires onRetry', (tester) async {
    var retried = false;
    await tester.pumpWidget(_wrap(
      AppErrorState(
        message: 'Failed',
        actionLabel: 'Retry',
        onRetry: () => retried = true,
      ),
    ));
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('StatusBadge success renders label', (tester) async {
    await tester.pumpWidget(_wrap(
      const StatusBadge(label: 'Active', variant: BadgeVariant.success),
    ));
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('StatusBadge error renders label', (tester) async {
    await tester.pumpWidget(_wrap(
      const StatusBadge(label: 'Failed', variant: BadgeVariant.error),
    ));
    expect(find.text('Failed'), findsOneWidget);
  });
}
