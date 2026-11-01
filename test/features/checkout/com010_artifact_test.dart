import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/cards/course_thumbnail.dart';
import 'package:acendra/features/checkout/data/repositories/student_order_repository.dart';
import 'package:acendra/features/checkout/domain/entities/checkout_status_label.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_actor_provider.dart';
import 'package:acendra/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../marketplace/fakes/fake_course_repository.dart';

void main() {
  test('student status labels do not expose backend codes', () {
    expect(checkoutStatusLabel('pending_payment'), 'Awaiting payment');
    expect(checkoutStatusLabel('pending_verification'), 'Verification pending');
    expect(checkoutStatusLabel('internal_future_status'), 'Status unavailable');
  });

  testWidgets(
    'existing order footer uses its immutable amount instead of the current catalog price',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            checkoutActorProvider.overrideWithValue('student'),
            courseDetailProvider(
              'fake-id-1',
            ).overrideWith((ref) async => fakeDetail),
            categoriesProvider.overrideWith((ref) async => []),
            openCourseOrderProvider('fake-id-1').overrideWith(
              (ref) async => const StudentOrder(
                id: 'order',
                courseId: 'fake-id-1',
                title: 'Stored Course',
                number: 'AC-1',
                amountMinor: 12345,
                currency: 'LKR',
                method: 'bank_transfer',
                status: 'pending_payment',
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const CheckoutScreen(courseId: 'fake-id-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final footer = find.descendant(
        of: find.byType(Scaffold),
        matching: find.text('LKR 123.45'),
      );
      expect(footer, findsOneWidget);
      expect(
        find.widgetWithText(AppButton, 'Payment Status').hitTestable(),
        findsOneWidget,
      );
    },
  );
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('checkout artifact layout $width dark=$dark', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              checkoutActorProvider.overrideWithValue('student'),
              courseDetailProvider(
                'fake-id-1',
              ).overrideWith((ref) async => fakeDetail),
              categoriesProvider.overrideWith((ref) async => []),
              openCourseOrderProvider(
                'fake-id-1',
              ).overrideWith((ref) async => null),
            ],
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: const CheckoutScreen(courseId: 'fake-id-1'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel('Payment, step 2 of 3, current'),
          findsOneWidget,
        );
        expect(
          tester.widget<CourseThumbnail>(find.byType(CourseThumbnail)).courseId,
          'fake-id-1',
        );
        expect(find.text('Fake Course'), findsOneWidget);
        final submit = find.widgetWithText(AppButton, 'Continue to PayHere');
        expect(submit.hitTestable(), findsOneWidget);
        expect(tester.getSize(submit).width, lessThanOrEqualTo(600));
        final country = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'Country',
        );
        await tester.ensureVisible(country);
        expect(tester.widget<TextField>(country).controller!.text, 'Sri Lanka');
        await tester.enterText(country, 'Sing');
        await tester.pumpAndSettle();
        expect(find.text('Singapore'), findsOneWidget);
        await tester.tap(find.text('Singapore'));
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(country).controller!.text, 'Singapore');
        await tester.ensureVisible(find.text('Bank Transfer'));
        await tester.tap(find.text('Bank Transfer'));
        await tester.pumpAndSettle();
        expect(find.text('Billing Details'), findsNothing);
        expect(
          find
              .widgetWithText(AppButton, 'Continue to Bank Transfer')
              .hitTestable(),
          findsOneWidget,
        );
        expect(
          find.textContaining('Submit your receipt for review'),
          findsOneWidget,
        );
        semantics.dispose();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
