// CSA-056: Accessibility foundations
// Covers NFR-ACC-001 through NFR-ACC-007 from SRS section 9.6.
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/cards/course_card.dart';
import 'package:acendra/core/widgets/dialogs/app_dialog.dart';
import 'package:acendra/core/widgets/feedback/app_skeleton.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({required Widget child, ThemeData? theme}) {
  return MediaQuery(
    data: const MediaQueryData(),
    child: MaterialApp(
      theme: theme ?? ThemeData(useMaterial3: true),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  // ------------------------------------------------------------------ //
  // CourseCard – NFR-ACC-001, NFR-ACC-002, NFR-ACC-003
  // ------------------------------------------------------------------ //
  group('CourseCard accessibility', () {
    testWidgets('meets androidTapTargetGuideline', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: CourseCard(
            title: 'Flutter for Beginners',
            instructorName: 'Jane Doe',
            price: '\$49.99',
            onTap: () {},
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('meets labeledTapTargetGuideline', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: CourseCard(
            title: 'Flutter for Beginners',
            instructorName: 'Jane Doe',
            price: '\$49.99',
            onTap: () {},
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('meets textContrastGuideline', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: CourseCard(
            title: 'Flutter for Beginners',
            instructorName: 'Jane Doe',
            price: '\$49.99',
            onTap: () {},
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('semantic label includes title, instructor and price', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          child: CourseCard(
            title: 'Flutter for Beginners',
            instructorName: 'Jane Doe',
            price: '\$49.99',
            onTap: () {},
          ),
        ),
      );
      final semantics = tester.getSemantics(find.byType(CourseCard));
      expect(semantics.label, contains('Flutter for Beginners'));
      expect(semantics.label, contains('Jane Doe'));
      expect(semantics.label, contains('\$49.99'));
    });

    testWidgets('non-interactive card is not marked as button', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: const CourseCard(
            title: 'Flutter for Beginners',
            instructorName: 'Jane Doe',
            price: '\$49.99',
          ),
        ),
      );
      final semantics = tester.getSemantics(find.byType(CourseCard));
      expect(semantics.hasFlag(SemanticsFlag.isButton), isFalse);
    });
  });

  // ------------------------------------------------------------------ //
  // AppButton – NFR-ACC-001, NFR-ACC-002, NFR-ACC-003
  // ------------------------------------------------------------------ //
  group('AppButton accessibility', () {
    testWidgets('meets androidTapTargetGuideline', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: AppButton(label: 'Continue', onPressed: () {}),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('meets labeledTapTargetGuideline', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: AppButton(label: 'Continue', onPressed: () {}),
        ),
      );
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('loading state has accessible label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: AppButton(label: 'Submit', onPressed: () {}, isLoading: true),
        ),
      );
      final semantics = tester.getSemantics(find.byType(AppButton));
      expect(semantics.label, contains('Submit'));
      expect(semantics.label, contains('loading'));
    });

    testWidgets('disabled state is reflected in semantics', (tester) async {
      await tester.pumpWidget(
        _wrap(child: const AppButton(label: 'Submit', onPressed: null)),
      );
      final semantics = tester.getSemantics(find.byType(AppButton));
      expect(semantics.hasFlag(SemanticsFlag.isEnabled), isFalse);
    });
  });

  // ------------------------------------------------------------------ //
  // AppEmptyState – NFR-ACC-002
  // ------------------------------------------------------------------ //
  group('AppEmptyState accessibility', () {
    testWidgets('meets androidTapTargetGuideline', (tester) async {
      await tester.pumpWidget(
        _wrap(child: const AppEmptyState(message: 'No courses found')),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('message is accessible to screen readers', (tester) async {
      await tester.pumpWidget(
        _wrap(child: const AppEmptyState(message: 'No courses found')),
      );
      expect(find.text('No courses found'), findsOneWidget);
    });

    testWidgets('action button has accessible label when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          child: AppEmptyState(
            message: 'No courses found',
            actionLabel: 'Browse courses',
            onAction: () {},
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });
  });

  // ------------------------------------------------------------------ //
  // AppErrorState – NFR-ACC-002, NFR-ACC-004
  // ------------------------------------------------------------------ //
  group('AppErrorState accessibility', () {
    testWidgets('error message is accessible', (tester) async {
      await tester.pumpWidget(
        _wrap(child: const AppErrorState(message: 'Something went wrong')),
      );
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('retry button meets tap target guideline', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: AppErrorState(
            message: 'Something went wrong',
            actionLabel: 'Retry',
            onRetry: () {},
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });

  // ------------------------------------------------------------------ //
  // StatusBadge – NFR-ACC-004 (status not conveyed by color alone)
  // ------------------------------------------------------------------ //
  group('StatusBadge accessibility', () {
    for (final variant in BadgeVariant.values) {
      testWidgets('${variant.name} badge announces variant in label', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            child: StatusBadge(label: 'Active', variant: variant),
          ),
        );
        final semantics = tester.getSemantics(find.byType(StatusBadge));
        expect(semantics.label, isNotEmpty);
        // Must contain both the variant kind and the label text
        expect(
          semantics.label.toLowerCase(),
          contains(variant.name.toLowerCase()),
        );
        expect(semantics.label, contains('Active'));
      });
    }
  });

  // ------------------------------------------------------------------ //
  // AppTextField – NFR-ACC-001, NFR-ACC-002
  // ------------------------------------------------------------------ //
  group('AppTextField accessibility', () {
    testWidgets('label is present in semantics tree', (tester) async {
      await tester.pumpWidget(
        _wrap(child: const AppTextField(label: 'Email address')),
      );
      expect(find.text('Email address'), findsOneWidget);
    });

    testWidgets('error text is exposed to semantics', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: const AppTextField(
            label: 'Email address',
            errorText: 'Invalid email',
          ),
        ),
      );
      expect(find.text('Invalid email'), findsOneWidget);
    });
  });

  // ------------------------------------------------------------------ //
  // AppPasswordField – NFR-ACC-001, NFR-ACC-002
  // ------------------------------------------------------------------ //
  group('AppPasswordField accessibility', () {
    testWidgets('toggle button has a tooltip / semantic label', (tester) async {
      await tester.pumpWidget(
        _wrap(child: const AppPasswordField(label: 'Password')),
      );
      // The toggle icon button must have a tooltip (accessibility label).
      final iconButton = find.byType(IconButton);
      expect(iconButton, findsOneWidget);
      final widget = tester.widget<IconButton>(iconButton);
      expect(widget.tooltip, isNotNull);
      expect(widget.tooltip, isNotEmpty);
    });

    testWidgets('meets androidTapTargetGuideline', (tester) async {
      await tester.pumpWidget(
        _wrap(child: const AppPasswordField(label: 'Password')),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('meets labeledTapTargetGuideline', (tester) async {
      await tester.pumpWidget(
        _wrap(child: const AppPasswordField(label: 'Password')),
      );
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });
  });

  // ------------------------------------------------------------------ //
  // AppSkeleton – NFR-ACC-002 (loading placeholder accessible)
  // ------------------------------------------------------------------ //
  group('AppSkeleton accessibility', () {
    testWidgets('skeleton has a semantic label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: const AppSkeleton(
            width: 200,
            height: 20,
            semanticLabel: 'Loading',
          ),
        ),
      );
      expect(tester.getSemantics(find.byType(AppSkeleton)).label, isNotEmpty);
    });
  });

  // ------------------------------------------------------------------ //
  // AppDialog – NFR-ACC-001, NFR-ACC-002
  // ------------------------------------------------------------------ //
  group('AppDialog accessibility', () {
    testWidgets('dialog title and body are accessible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => AppDialog.show(
                context,
                title: 'Delete course',
                body: 'This action cannot be undone.',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Delete course'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });
}
