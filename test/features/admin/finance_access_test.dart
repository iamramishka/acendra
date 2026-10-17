import 'dart:convert';

import 'package:acendra/features/admin/presentation/providers/finance_access_provider.dart';
import 'package:acendra/features/admin/presentation/providers/admin_dashboard_provider.dart';
import 'package:acendra/features/admin/presentation/providers/admin_payments_provider.dart';
import 'package:acendra/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Session session(String aal) => Session(
  accessToken:
      'header.${base64Url.encode(utf8.encode(jsonEncode({'aal': aal})))}.signature',
  tokenType: 'bearer',
  user: const User(
    id: 'test-user',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-01-01',
  ),
);

void main() {
  for (final allowed in [false, true]) {
    testWidgets('finance shortcut visibility follows eligibility $allowed', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminDashboardProvider.overrideWith(_Dashboard.new),
            adminPaymentCountsProvider.overrideWith((ref) async => {}),
            financeAccessProvider.overrideWith((ref) async => allowed),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AdminDashboardScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Finance Review'),
        allowed ? findsOneWidget : findsNothing,
      );
    });
  }
  for (final role in [
    'finance_admin',
    'super_admin',
    'content_manager',
    'admin',
    'student',
  ]) {
    for (final aal in ['aal1', 'aal2']) {
      test('$role at $aal has appropriate finance navigation', () async {
        final container = ProviderContainer(
          overrides: [
            currentSessionProvider.overrideWithValue(session(aal)),
            financeRoleGrantsProvider.overrideWith((ref) async => [role]),
          ],
        );
        addTearDown(container.dispose);
        expect(
          await container.read(financeAccessProvider.future),
          aal == 'aal2' && {'finance_admin', 'super_admin'}.contains(role),
        );
      });
    }
  }
  test('signed out users cannot access finance navigation', () async {
    final container = ProviderContainer(
      overrides: [currentSessionProvider.overrideWithValue(null)],
    );
    addTearDown(container.dispose);
    expect(await container.read(financeAccessProvider.future), isFalse);
  });
}

class _Dashboard extends AdminDashboardNotifier {
  @override
  Future<AdminDashboardStats> build() async => const AdminDashboardStats(
    totalStudents: 0,
    totalCourses: 0,
    pendingPayments: 0,
    totalRevenue: 0,
    recentPendingPayments: [],
  );
}
