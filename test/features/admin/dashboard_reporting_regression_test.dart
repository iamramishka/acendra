import 'package:acendra/features/admin/data/repositories/admin_course_repository.dart';
import 'package:acendra/features/admin/data/repositories/admin_directory_client.dart';
import 'package:acendra/features/admin/data/repositories/admin_payment_repository.dart';
import 'package:acendra/features/admin/data/repositories/admin_reporting_repository.dart';
import 'package:acendra/features/admin/data/repositories/admin_student_repository.dart';
import 'package:acendra/features/admin/domain/entities/payment_record.dart';
import 'package:acendra/features/admin/presentation/providers/admin_dashboard_provider.dart';
import 'package:acendra/features/admin/presentation/providers/admin_payments_provider.dart';
import 'package:acendra/features/admin/presentation/providers/finance_access_provider.dart';
import 'package:acendra/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:acendra/features/admin/presentation/screens/admin_payments_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'fakes/dashboard_repositories.dart';

void main() {
  test(
    'restricted student metrics do not suppress authorized course counts',
    () async {
      final container = ProviderContainer(
        overrides: [
          adminCourseRepositoryProvider.overrideWithValue(
            EmptyCourseRepository(),
          ),
          adminStudentRepositoryProvider.overrideWithValue(
            RestrictedStudentRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final dashboard = await container.read(adminDashboardProvider.future);
      expect(dashboard.totalStudents, isNull);
      expect(dashboard.totalCourses, 0);
    },
  );

  test(
    'default payment provider never returns fabricated payment records',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await expectLater(
        container.read(adminPaymentsProvider.future),
        throwsA(isA<PaymentReportingUnavailable>()),
      );
    },
  );

  testWidgets('dashboard shows unavailable rather than an invented total', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDashboardProvider.overrideWith(_UnavailableDashboard.new),
          financeAccessProvider.overrideWith((ref) async => false),
        ],
        child: const MaterialApp(home: Scaffold(body: AdminDashboardScreen())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unavailable'), findsNWidgets(2));
    expect(find.text('LKR 0.00'), findsNothing);
    expect(find.text('No pending payments'), findsNothing);
    expect(find.text('Payment reporting is unavailable.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard errors do not expose backend diagnostics', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminDashboardProvider.overrideWith(_FailedDashboard.new)],
        child: const MaterialApp(home: Scaffold(body: AdminDashboardScreen())),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Failed to load dashboard. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('internal database detail'), findsNothing);
  });

  test('payment records cannot establish confirmed financial totals', () async {
    final container = ProviderContainer(
      overrides: [
        adminPaymentRepositoryProvider.overrideWithValue(
          StubAdminPaymentRepository(),
        ),
        adminCourseRepositoryProvider.overrideWithValue(
          EmptyCourseRepository(),
        ),
        adminStudentRepositoryProvider.overrideWithValue(
          EmptyStudentRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final stats = await container.read(adminDashboardProvider.future);

    expect(stats.confirmedReceipts, isNull);
  });

  test(
    'dashboard surfaces gross confirmed receipts from the reporting API',
    () async {
      final container = ProviderContainer(
        overrides: [
          adminCourseRepositoryProvider.overrideWithValue(
            EmptyCourseRepository(),
          ),
          adminStudentRepositoryProvider.overrideWithValue(
            EmptyStudentRepository(),
          ),
          adminReportingRepositoryProvider.overrideWithValue(
            _FakeReporting(
              ConfirmedReceipts(
                grossReceiptsMinor: BigInt.from(1234567),
                currency: 'LKR',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final stats = await container.read(adminDashboardProvider.future);
      expect(stats.confirmedReceipts?.formattedGross, 'LKR 12,345.67');
    },
  );

  test('unavailable or restricted receipts stay null, not zero', () async {
    for (final error in <Object>[
      const ReportingUnavailable(),
      const AdminDataException('Admin service is unavailable.'),
    ]) {
      final container = ProviderContainer(
        overrides: [
          adminCourseRepositoryProvider.overrideWithValue(
            EmptyCourseRepository(),
          ),
          adminStudentRepositoryProvider.overrideWithValue(
            EmptyStudentRepository(),
          ),
          adminReportingRepositoryProvider.overrideWithValue(
            _FakeReporting.failing(error),
          ),
        ],
      );
      addTearDown(container.dispose);
      final stats = await container.read(adminDashboardProvider.future);
      expect(stats.confirmedReceipts, isNull);
      expect(stats.totalCourses, 0);
    }
  });

  test('signed-out or unwired reporting leaves receipts unavailable', () async {
    final container = ProviderContainer(
      overrides: [
        adminCourseRepositoryProvider.overrideWithValue(
          EmptyCourseRepository(),
        ),
        adminStudentRepositoryProvider.overrideWithValue(
          EmptyStudentRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final stats = await container.read(adminDashboardProvider.future);
    expect(stats.confirmedReceipts, isNull);
    expect(stats.totalCourses, 0);
  });

  testWidgets('dashboard labels receipts as gross, with exact amount', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDashboardProvider.overrideWith(_ReceiptsDashboard.new),
          financeAccessProvider.overrideWith((ref) async => false),
        ],
        child: const MaterialApp(home: Scaffold(body: AdminDashboardScreen())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('LKR 12,345.67'), findsOneWidget);
    expect(find.text('Gross Receipts (30 days)'), findsOneWidget);
    expect(find.text('Total Revenue'), findsNothing);
    expect(find.textContaining('Net'), findsNothing);
    expect(
      find.text(
        'Refund and net totals are unavailable until confirmed refund reporting is connected.',
      ),
      findsOneWidget,
    );
    expect(find.text('Refunds: LKR 0.00'), findsNothing);
    expect(find.text('Net: LKR 0.00'), findsNothing);
  });

  test('dashboard uses the same global status snapshot as Payments', () async {
    final container = ProviderContainer(
      overrides: [
        adminPaymentRepositoryProvider.overrideWithValue(
          StubAdminPaymentRepository(),
        ),
        adminCourseRepositoryProvider.overrideWithValue(
          EmptyCourseRepository(),
        ),
        adminStudentRepositoryProvider.overrideWithValue(
          EmptyStudentRepository(),
        ),
        adminPaymentCountsProvider.overrideWith(
          (ref) async => {
            PaymentStatus.pending: 7,
            PaymentStatus.processing: 1,
            PaymentStatus.approved: 2,
            PaymentStatus.rejected: 1,
          },
        ),
      ],
    );
    addTearDown(container.dispose);

    final payments = await container.read(adminPaymentsProvider.future);
    final dashboard = await container.read(adminDashboardProvider.future);

    expect(payments.pendingCount, 7);
    expect(dashboard.pendingPayments, payments.pendingCount);
  });

  test(
    'unavailable payments do not suppress authorized directory counts',
    () async {
      final container = ProviderContainer(
        overrides: [
          adminCourseRepositoryProvider.overrideWithValue(
            EmptyCourseRepository(),
          ),
          adminStudentRepositoryProvider.overrideWithValue(
            EmptyStudentRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final dashboard = await container.read(adminDashboardProvider.future);
      expect(dashboard.totalCourses, 0);
      expect(dashboard.totalStudents, 0);
      expect(dashboard.pendingPayments, isNull);
      expect(dashboard.recentPendingPayments, isEmpty);
    },
  );

  testWidgets('Payments displays unavailable rather than demo identities', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: AdminPaymentsScreen())),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Payment reporting is unavailable. Please try again later.'),
      findsOneWidget,
    );
    expect(find.textContaining('@example.com'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _UnavailableDashboard extends AdminDashboardNotifier {
  @override
  Future<AdminDashboardStats> build() async => const AdminDashboardStats(
    totalStudents: 0,
    totalCourses: 0,
    pendingPayments: null,
    confirmedReceipts: null,
    recentPendingPayments: [],
  );
}

class _ReceiptsDashboard extends AdminDashboardNotifier {
  @override
  Future<AdminDashboardStats> build() async => AdminDashboardStats(
    totalStudents: 0,
    totalCourses: 0,
    pendingPayments: 0,
    confirmedReceipts: ConfirmedReceipts(
      grossReceiptsMinor: BigInt.from(1234567),
      currency: 'LKR',
    ),
    recentPendingPayments: const [],
  );
}

class _FakeReporting implements AdminReportingRepository {
  _FakeReporting(ConfirmedReceipts value) : _value = value, _error = null;
  _FakeReporting.failing(Object error) : _value = null, _error = error;
  final ConfirmedReceipts? _value;
  final Object? _error;
  @override
  Future<ConfirmedReceipts> confirmedReceipts() async =>
      _error != null ? throw _error : _value!;
}

class _FailedDashboard extends AdminDashboardNotifier {
  @override
  Future<AdminDashboardStats> build() async =>
      throw Exception('internal database detail');
}
