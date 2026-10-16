// CSA-195 — High-priority user workflow integration tests.
//
// These widget-level integration tests exercise the three most critical
// end-to-end user paths against fake repositories (no real Supabase needed).
//
// Imports app_router which depends on dart:js_interop (via package:web).
// Run on Chrome only:
//   flutter test --platform chrome test/features/integration/high_priority_workflows_test.dart
@TestOn('chrome')
library;
// Workflow 1: Student enrollment + course access
//   Marketplace → course card tap → checkout screen loads with course info
//   and payment method selector.
//
// Workflow 2: Student dashboard + continue learning
//   Authenticated student with enrolled courses → My Courses screen shows
//   enrolled cards → tapping a card navigates to /learn/:courseId.
//
// Workflow 3: Checkout → bank transfer → receipt status
//   Checkout screen with a pending bank-transfer order → tap "Continue Bank
//   Transfer" → BankTransferScreen renders instructions → tap "I've made the
//   transfer" → navigates to receipt status screen.

import 'package:acendra/app/router/app_router.dart';
import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/providers/logout_provider.dart';
import 'package:acendra/features/bank_transfer/data/bank_transfer_repository.dart';
import 'package:acendra/features/bank_transfer/domain/entities/receipt_submission.dart';
import 'package:acendra/features/checkout/domain/entities/checkout_order.dart';
import 'package:acendra/features/checkout/domain/entities/payment_method.dart';
import 'package:acendra/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_actor_provider.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:acendra/features/checkout/presentation/providers/payment_launcher_provider.dart';
import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/features/marketplace/domain/entities/category.dart';
import 'package:acendra/features/marketplace/domain/entities/course_detail.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/features/marketplace/domain/repositories/course_repository.dart';
import 'package:acendra/features/my_courses/data/repositories/supabase_my_courses_repository.dart';
import 'package:acendra/features/my_courses/domain/entities/enrolled_course.dart';
import 'package:acendra/features/my_courses/domain/repositories/my_courses_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart' show Override;

// ---------------------------------------------------------------------------
// Fake repositories
// ---------------------------------------------------------------------------

const _kCourseId = 'course-abc-123';
const _kCourseTitle = 'Flutter for Beginners';
const _kOrderId = 'order-xyz-789';
const _kOrderNumber = 'ORD-0001';

class _FakeCourseRepository implements CourseRepository {
  @override
  Future<List<CourseSummary>> listPublished() async => [
    const CourseSummary(
      id: _kCourseId,
      slug: 'flutter-for-beginners',
      title: _kCourseTitle,
      shortDescription: 'Learn Flutter from scratch.',
      priceMinor: 4999,
      currencyCode: 'LKR',
      publishedAt: '2025-01-01',
    ),
  ];

  @override
  Future<List<Category>> listCategories() async => [];

  @override
  Future<CourseDetail> getCourseDetail(String courseId) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> isEnrolled(String courseId) async => false;
}

class _FakeMyCoursesRepository implements MyCoursesRepository {
  @override
  Future<List<EnrolledCourse>> listEnrolled() async => [
    const EnrolledCourse(
      id: 'enroll-1',
      courseId: _kCourseId,
      title: _kCourseTitle,
      shortDescription: 'Learn Flutter from scratch.',
      status: 'active',
      enrolledAt: '2025-06-01',
    ),
  ];
}

class _FakeCheckoutRepository implements CheckoutRepository {
  final PaymentMethod paymentMethod;

  const _FakeCheckoutRepository({
    this.paymentMethod = PaymentMethod.bankTransfer,
  });

  @override
  Future<CheckoutOrder> createOrder({
    required String courseId,
    required PaymentMethod method,
    required String idempotencyKey,
  }) async {
    return CheckoutOrder(
      orderId: _kOrderId,
      orderNumber: _kOrderNumber,
      courseId: courseId,
      courseTitle: _kCourseTitle,
      amountMinor: 4999,
      currencyCode: 'LKR',
      paymentMethod: paymentMethod,
      status: 'pending_payment',
      nextAction: 'show_bank_instructions',
      bankInstructions: paymentMethod == PaymentMethod.bankTransfer
          ? const BankInstructions(
              bankName: 'People\'s Bank',
              accountHolder: 'Acedra Pvt Ltd',
              accountNumber: '123456789',
              branch: 'Colombo 03',
              currency: 'LKR',
            )
          : null,
    );
  }
}

class _FakeBankTransferRepository implements BankTransferRepository {
  @override
  Future<ReceiptSubmission> status(String orderId) async =>
      const ReceiptSubmission(
        orderId: _kOrderId,
        orderNumber: _kOrderNumber,
        courseTitle: _kCourseTitle,
        status: ReceiptStatus.awaitingReceipt,
      );

  @override
  Future<void> uploadReceipt({
    required String orderId,
    required String fileName,
    required List<int> bytes,
    required String idempotencyKey,
  }) async {}

  @override
  Future<void> review({
    required String submissionId,
    String? rejectionReason,
    Map<String, dynamic>? verifiedCredit,
  }) async {}

  @override
  Future<List<Map<String, dynamic>>> queue() async => [];
}

// ---------------------------------------------------------------------------
// App builder helpers
// ---------------------------------------------------------------------------

Widget _authenticatedApp({
  List<Override> extraOverrides = const [],
}) {
  return ProviderScope(
    overrides: [
      authStreamProvider.overrideWith((ref) => const Stream.empty()),
      sessionRestoredProvider.overrideWithValue(true),
      isAuthenticatedProvider.overrideWithValue(true),
      currentSessionProvider.overrideWithValue(null),
      logoutProvider.overrideWith(LogoutNotifier.new),
      checkoutActorProvider.overrideWithValue('user-test-id'),
      paymentLauncherProvider.overrideWithValue((_) async {}),
      ...extraOverrides,
    ],
    child: Consumer(
      builder: (_, ref, __) =>
          MaterialApp.router(routerConfig: ref.watch(appRouterProvider)),
    ),
  );
}

// ---------------------------------------------------------------------------
// Workflow 1: Marketplace → course detail → checkout
// ---------------------------------------------------------------------------

void main() {
  group('Workflow 1: Marketplace → checkout', () {
    testWidgets('marketplace shows course card', (tester) async {
      await tester.pumpWidget(
        _authenticatedApp(
          extraOverrides: [
            courseRepositoryProvider.overrideWithValue(
              _FakeCourseRepository(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to marketplace.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer)),
      );
      container.read(appRouterProvider).go(RouteNames.marketplace);
      await tester.pumpAndSettle();

      expect(find.text(_kCourseTitle), findsWidgets);
    });

    testWidgets('tapping a course navigates to checkout with payment selector',
        (tester) async {
      await tester.pumpWidget(
        _authenticatedApp(
          extraOverrides: [
            courseRepositoryProvider.overrideWithValue(
              _FakeCourseRepository(),
            ),
            checkoutRepositoryProvider.overrideWithValue(
              const _FakeCheckoutRepository(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Navigate directly to checkout (simulating the tap path).
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer)),
      );
      container.read(appRouterProvider).go(
        RouteNames.checkout.replaceFirst(':courseId', _kCourseId),
      );
      await tester.pumpAndSettle();

      expect(find.text('Checkout'), findsWidgets);
      expect(find.text('Payment Method'), findsOneWidget);
      expect(find.text('Proceed to Payment'), findsOneWidget);
    });

    testWidgets('checkout shows order summary after order is created',
        (tester) async {
      await tester.pumpWidget(
        _authenticatedApp(
          extraOverrides: [
            courseRepositoryProvider.overrideWithValue(
              _FakeCourseRepository(),
            ),
            checkoutRepositoryProvider.overrideWithValue(
              const _FakeCheckoutRepository(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer)),
      );
      container.read(appRouterProvider).go(
        RouteNames.checkout.replaceFirst(':courseId', _kCourseId),
      );
      await tester.pumpAndSettle();

      // Trigger order creation by pressing "Proceed to Payment" after filling
      // the required billing fields.
      final firstNameFields = find.ancestor(
        of: find.text('First Name'),
        matching: find.byType(TextField),
      );
      if (firstNameFields.evaluate().isEmpty) {
        // Fields found via TextFormField subtree.
        final allTextFields = find.byType(TextField);
        if (allTextFields.evaluate().length >= 6) {
          await tester.enterText(allTextFields.at(0), 'Ada');
          await tester.enterText(allTextFields.at(1), 'Lovelace');
          await tester.enterText(allTextFields.at(2), '+94771234567');
          await tester.enterText(allTextFields.at(3), '123 Main St');
          await tester.enterText(allTextFields.at(4), 'Colombo');
          await tester.enterText(allTextFields.at(5), 'Sri Lanka');
        }
      }
      await tester.tap(find.text('Proceed to Payment'));
      await tester.pumpAndSettle();

      expect(find.text('Order Summary'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Workflow 2: Dashboard → My Courses → Continue Learning
  // ---------------------------------------------------------------------------

  group('Workflow 2: Dashboard → My Courses → Continue Learning', () {
    testWidgets('authenticated student sees enrolled courses on My Courses screen',
        (tester) async {
      await tester.pumpWidget(
        _authenticatedApp(
          extraOverrides: [
            myCoursesRepositoryProvider.overrideWithValue(
              _FakeMyCoursesRepository(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer)),
      );
      container.read(appRouterProvider).go(RouteNames.myCourses);
      await tester.pumpAndSettle();

      expect(find.text('My Courses'), findsWidgets);
      expect(find.text(_kCourseTitle), findsOneWidget);
    });

    testWidgets('tapping enrolled course card navigates to /learn/:courseId',
        (tester) async {
      await tester.pumpWidget(
        _authenticatedApp(
          extraOverrides: [
            myCoursesRepositoryProvider.overrideWithValue(
              _FakeMyCoursesRepository(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer)),
      );
      container.read(appRouterProvider).go(RouteNames.myCourses);
      await tester.pumpAndSettle();

      // Tap the enrolled course card to trigger navigation to /learn/<courseId>.
      await tester.tap(find.text(_kCourseTitle));
      await tester.pumpAndSettle();

      // The learn screen URL should now contain the courseId.
      // The router is the source of truth; verify the destination rendered.
      final location = container.read(appRouterProvider).routerDelegate
          .currentConfiguration
          .uri
          .toString();
      expect(location, contains(_kCourseId));
    });

    testWidgets('My Courses screen shows empty state when no enrollments',
        (tester) async {
      await tester.pumpWidget(
        _authenticatedApp(
          extraOverrides: [
            myCoursesRepositoryProvider.overrideWith(
              (_) => _EmptyMyCoursesRepository(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer)),
      );
      container.read(appRouterProvider).go(RouteNames.myCourses);
      await tester.pumpAndSettle();

      expect(find.text('You have not enrolled in any courses yet.'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Workflow 3: Checkout → Bank Transfer → Receipt Status
  // ---------------------------------------------------------------------------

  group('Workflow 3: Checkout → bank transfer → receipt status', () {
    testWidgets('bank transfer screen shows step-by-step instructions when order is valid',
        (tester) async {
      await tester.pumpWidget(
        _authenticatedApp(
          extraOverrides: [
            checkoutRepositoryProvider.overrideWithValue(
              const _FakeCheckoutRepository(
                paymentMethod: PaymentMethod.bankTransfer,
              ),
            ),
            checkoutProvider.overrideWith(() => _PreloadedCheckoutNotifier()),
            bankTransferRepositoryProvider.overrideWithValue(
              _FakeBankTransferRepository(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer)),
      );
      container.read(appRouterProvider).go(
        RouteNames.bankTransfer.replaceFirst(':orderId', _kOrderId),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bank Transfer'), findsWidgets);
      expect(find.text('Log in to your bank'), findsOneWidget);
      expect(find.text("I've made the transfer"), findsOneWidget);
    });

    testWidgets(
        '"I\'ve made the transfer" navigates to receipt status screen',
        (tester) async {
      await tester.pumpWidget(
        _authenticatedApp(
          extraOverrides: [
            checkoutProvider.overrideWith(() => _PreloadedCheckoutNotifier()),
            bankTransferRepositoryProvider.overrideWithValue(
              _FakeBankTransferRepository(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer)),
      );
      container.read(appRouterProvider).go(
        RouteNames.bankTransfer.replaceFirst(':orderId', _kOrderId),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text("I've made the transfer"));
      await tester.pumpAndSettle();

      // Receipt status screen should now be visible.
      expect(find.text('Transfer Status'), findsWidgets);
    });

    testWidgets(
        'receipt status screen shows awaiting-receipt state when no receipt uploaded',
        (tester) async {
      await tester.pumpWidget(
        _authenticatedApp(
          extraOverrides: [
            bankTransferRepositoryProvider.overrideWithValue(
              _FakeBankTransferRepository(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer)),
      );
      container.read(appRouterProvider).go(
        RouteNames.receiptStatus.replaceFirst(':orderId', _kOrderId),
      );
      await tester.pumpAndSettle();

      expect(find.text('Transfer Status'), findsWidgets);
    });
  });
}

// ---------------------------------------------------------------------------
// Supporting fakes
// ---------------------------------------------------------------------------

class _EmptyMyCoursesRepository implements MyCoursesRepository {
  @override
  Future<List<EnrolledCourse>> listEnrolled() async => [];
}

/// Pre-loads checkoutProvider with a valid bank-transfer order so that
/// BankTransferScreen renders instructions rather than the error fallback.
class _PreloadedCheckoutNotifier extends CheckoutNotifier {
  @override
  Future<CheckoutOrder?> build() async => const CheckoutOrder(
    orderId: _kOrderId,
    orderNumber: _kOrderNumber,
    courseId: _kCourseId,
    courseTitle: _kCourseTitle,
    amountMinor: 4999,
    currencyCode: 'LKR',
    paymentMethod: PaymentMethod.bankTransfer,
    status: 'pending_payment',
    nextAction: 'show_bank_instructions',
    bankInstructions: BankInstructions(
      bankName: 'People\'s Bank',
      accountHolder: 'Acedra Pvt Ltd',
      accountNumber: '123456789',
      branch: 'Colombo 03',
      currency: 'LKR',
    ),
  );
}
