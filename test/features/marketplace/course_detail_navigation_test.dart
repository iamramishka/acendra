import 'dart:async';
import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/features/marketplace/domain/entities/course_detail.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:acendra/features/marketplace/presentation/screens/course_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const courseId = '11111111-1111-4111-8111-111111111111';
const detail = CourseDetail(
  id: courseId,
  slug: 'sample',
  title: 'Sample Course',
  shortDescription: 'Synthetic course',
  priceMinor: 12345,
  currencyCode: 'LKR',
  publishedAt: '2026-10-15T00:00:00Z',
  sections: [],
);

void main() {
  Future<void> mount(WidgetTester tester, Future<bool> enrollment) async {
    final router = GoRouter(
      initialLocation: '/course',
      routes: [
        GoRoute(
          path: '/course',
          builder: (_, _) => const CourseDetailScreen(courseId: courseId),
        ),
        GoRoute(
          path: '/checkout/:courseId',
          builder: (_, state) => Scaffold(
            body: Text('Checkout ${state.pathParameters['courseId']}'),
          ),
        ),
        GoRoute(
          path: '/learn/:courseId',
          builder: (_, state) => Scaffold(
            body: Text('Learning ${state.pathParameters['courseId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courseDetailProvider(courseId).overrideWith((ref) async => detail),
          isEnrolledProvider(courseId).overrideWith((ref) => enrollment),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  for (final enrolled in [false, true]) {
    testWidgets(
      'resolved enrolled=$enrolled navigates using actual course identity',
      (tester) async {
        await mount(tester, Future.value(enrolled));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(
            AppButton,
            enrolled ? 'Continue Learning' : 'Enroll Now',
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('${enrolled ? 'Learning' : 'Checkout'} $courseId'),
          findsOneWidget,
        );
      },
    );
  }
  testWidgets(
    'pending enrollment disables action instead of assuming unenrolled',
    (tester) async {
      final pending = Completer<bool>();
      await mount(tester, pending.future);
      final button = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Checking enrollment…'),
      );
      expect(button.onPressed, isNull);
      expect(find.widgetWithText(AppButton, 'Enroll Now'), findsNothing);
      pending.complete(false);
      await tester.pumpAndSettle();
    },
  );
  testWidgets('failed enrollment keeps action disabled with explicit retry', (
    tester,
  ) async {
    final pending = Completer<bool>();
    await mount(tester, pending.future);
    pending.completeError(StateError('synthetic private error'));
    await tester.pumpAndSettle();
    final button = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Enrollment status unavailable'),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Retry enrollment status'), findsOneWidget);
    expect(find.textContaining('synthetic private error'), findsNothing);
  });
}
