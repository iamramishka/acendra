import 'package:acendra/app/theme/app_colors.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/features/checkout/presentation/screens/payment_failure_screen.dart';
import 'package:acendra/features/checkout/presentation/screens/payment_pending_screen.dart';
import 'package:acendra/features/checkout/presentation/screens/payment_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// Minimal GoRouter for tests — captures go() calls without real navigation.
GoRouter _testRouter(Widget screen) => GoRouter(
  initialLocation: '/test',
  routes: [
    GoRoute(path: '/test', builder: (_, _) => screen),
    GoRoute(
      path: '/marketplace',
      builder: (_, _) => const _Stub('marketplace'),
    ),
    GoRoute(path: '/dashboard', builder: (_, _) => const _Stub('dashboard')),
    GoRoute(path: '/learn/:courseId', builder: (_, _) => const _Stub('learn')),
    GoRoute(
      path: '/checkout/:courseId',
      builder: (_, _) => const _Stub('checkout'),
    ),
    GoRoute(
      path: '/marketplace/:courseId',
      builder: (_, _) => const _Stub('courseDetail'),
    ),
  ],
);

class _Stub extends StatelessWidget {
  const _Stub(this.name);
  final String name;

  @override
  Widget build(BuildContext context) => Text(name);
}

// Wraps a screen with ProviderScope + MaterialApp.router using the test router.
Widget _wrap(Widget screen) {
  final router = _testRouter(screen);
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      theme: ThemeData(
        extensions: [AppThemeExtension.fromTokens(AppColors.light)],
      ),
    ),
  );
}

void main() {
  group('PaymentSuccessScreen', () {
    testWidgets('renders course title', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PaymentSuccessScreen(
            courseId: 'course-1',
            courseTitle: 'Flutter Fundamentals',
            orderNumber: 'ORD-001',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Flutter Fundamentals'), findsOneWidget);
    });

    testWidgets('renders order number', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PaymentSuccessScreen(
            courseId: 'course-1',
            courseTitle: 'Flutter Fundamentals',
            orderNumber: 'ORD-12345',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Order #ORD-12345'), findsOneWidget);
    });

    testWidgets('renders Payment Successful heading', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PaymentSuccessScreen(
            courseId: 'course-1',
            courseTitle: 'Test Course',
            orderNumber: 'ORD-001',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Payment Successful!'), findsOneWidget);
    });

    testWidgets('renders Start Learning and Browse More Courses buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const PaymentSuccessScreen(
            courseId: 'course-1',
            courseTitle: 'Test Course',
            orderNumber: 'ORD-001',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Start Learning'), findsOneWidget);
      expect(find.text('Browse More Courses'), findsOneWidget);
    });
  });

  group('PaymentPendingScreen', () {
    testWidgets('renders Awaiting Verification heading', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PaymentPendingScreen(
            courseId: 'course-1',
            courseTitle: 'Dart Deep Dive',
            orderNumber: 'ORD-002',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Awaiting Verification'), findsOneWidget);
    });

    testWidgets('renders bank info when bankName and accountNumber provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const PaymentPendingScreen(
            courseId: 'course-1',
            courseTitle: 'Dart Deep Dive',
            orderNumber: 'ORD-002',
            bankName: 'BOC',
            accountNumber: '1234567890',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bank: BOC'), findsOneWidget);
      expect(find.text('Account: 1234567890'), findsOneWidget);
    });

    testWidgets('does not render bank info when bankName is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const PaymentPendingScreen(
            courseId: 'course-1',
            courseTitle: 'Dart Deep Dive',
            orderNumber: 'ORD-002',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Transfer Details'), findsNothing);
    });

    testWidgets('renders order number', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PaymentPendingScreen(
            courseId: 'course-1',
            courseTitle: 'Dart Deep Dive',
            orderNumber: 'ORD-XYZ',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Order #ORD-XYZ'), findsOneWidget);
    });
  });

  group('PaymentFailureScreen', () {
    testWidgets('renders Try Again button', (tester) async {
      await tester.pumpWidget(
        _wrap(const PaymentFailureScreen(courseId: 'course-1')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('renders custom reason text when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PaymentFailureScreen(
            courseId: 'course-1',
            reason: 'Insufficient funds in your account.',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Insufficient funds in your account.'), findsOneWidget);
    });

    testWidgets('renders default description when reason is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const PaymentFailureScreen(courseId: 'course-1')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Your payment could not be processed. Please try again or use a different payment method.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders Payment Failed heading', (tester) async {
      await tester.pumpWidget(
        _wrap(const PaymentFailureScreen(courseId: 'course-1')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Payment Failed'), findsAtLeast(1));
    });
  });
}
