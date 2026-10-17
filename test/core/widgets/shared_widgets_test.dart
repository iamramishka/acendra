import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/cards/course_card.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: ThemeData(useMaterial3: true),
  home: Scaffold(body: child),
);

void main() {
  group('AppSnackbar', () {
    testWidgets('show displays the message text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => AppSnackbar.show(ctx, 'Hello snackbar'),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Hello snackbar'), findsOneWidget);
    });

    testWidgets('show with error variant still displays the message', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => AppSnackbar.show(
                  ctx,
                  'Error occurred',
                  variant: SnackbarVariant.error,
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Error occurred'), findsOneWidget);
    });
  });

  group('AppButton variants', () {
    testWidgets('secondary variant renders', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppButton(
            label: 'Secondary',
            onPressed: () {},
            variant: ButtonVariant.secondary,
          ),
        ),
      );
      expect(find.text('Secondary'), findsOneWidget);
    });

    testWidgets('outlined variant renders', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppButton(
            label: 'Outlined',
            onPressed: () {},
            variant: ButtonVariant.outlined,
          ),
        ),
      );
      expect(find.text('Outlined'), findsOneWidget);
    });

    testWidgets('destructive variant renders', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppButton(
            label: 'Delete',
            onPressed: () {},
            variant: ButtonVariant.destructive,
          ),
        ),
      );
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets(
      'isLoading shows CircularProgressIndicator and blocks onPressed',
      (tester) async {
        int tapCount = 0;
        await tester.pumpWidget(
          _wrap(
            AppButton(
              label: 'Save',
              onPressed: () => tapCount++,
              isLoading: true,
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        expect(tapCount, 0);
      },
    );

    testWidgets('small size renders', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppButton(label: 'Small', onPressed: () {}, size: ButtonSize.small),
        ),
      );
      expect(find.text('Small'), findsOneWidget);
    });

    testWidgets('large size renders', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppButton(label: 'Large', onPressed: () {}, size: ButtonSize.large),
        ),
      );
      expect(find.text('Large'), findsOneWidget);
    });

    testWidgets('button with icon renders icon and label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppButton(
            label: 'Add',
            onPressed: () {},
            icon: const Icon(Icons.add),
          ),
        ),
      );

      expect(find.text('Add'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  group('CourseCard additional scenarios', () {
    testWidgets('shows rating and review count when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CourseCard(
            title: 'Flutter Course',
            instructorName: 'Jane Doe',
            price: '\$49.99',
            rating: 4.5,
            reviewCount: 100,
          ),
        ),
      );

      expect(find.text('4.5'), findsOneWidget);
      expect(find.text(' (100)'), findsOneWidget);
    });

    testWidgets('shows course cover when imageUrl is null', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CourseCard(
            title: 'No Image Course',
            instructorName: 'John Smith',
            price: '\$29.99',
          ),
        ),
      );

      expect(find.text('Cover image not provided'), findsOneWidget);
    });

    testWidgets('renders without error when onTap is null', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CourseCard(
            title: 'No Tap Course',
            instructorName: 'Alex Lee',
            price: '\$19.99',
          ),
        ),
      );

      expect(find.text('No Tap Course'), findsOneWidget);
    });
  });

  group('StatusBadge additional variants', () {
    testWidgets('warning variant renders its label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const StatusBadge(label: 'Pending', variant: BadgeVariant.warning),
        ),
      );
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('info variant renders its label', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatusBadge(label: 'New', variant: BadgeVariant.info)),
      );
      expect(find.text('New'), findsOneWidget);
    });
  });
}
