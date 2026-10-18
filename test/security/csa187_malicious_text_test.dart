import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/core/widgets/cards/course_card.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:acendra/features/profile/presentation/screens/profile_screen.dart';
import 'package:acendra/features/profile/presentation/providers/profile_provider.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/providers/logout_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../features/marketplace/fakes/fake_course_repository.dart';
import 'csa187_dom_stub.dart'
    if (dart.library.js_interop) 'csa187_dom_web.dart';

const payloads = [
  '<img src=x onerror=alert("CSA187")>',
  '<svg onload=alert("CSA187")>',
  '<script>alert("CSA187")</script>',
];
void main() {
  for (final payload in payloads) {
    testWidgets('course metadata and search preserve literal $payload', (
      tester,
    ) async {
      final course = CourseSummary(
        id: 'security-fixture',
        slug: 'security-fixture',
        title: payload,
        shortDescription: payload,
        priceMinor: 100,
        currencyCode: 'LKR',
        publishedAt: '2026-10-13',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            courseRepositoryProvider.overrideWithValue(
              FakeCourseRepository(result: [course]),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: MarketplaceScreen())),
        ),
      );
      await tester.pumpAndSettle();
      final card = find.byType(CourseCard);
      // The title and short description are separate literal text surfaces.
      final title = find.descendant(
        of: card,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Text && widget.data == payload && widget.maxLines == 2,
        ),
      );
      final description = find.descendant(
        of: card,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data == payload &&
              widget.maxLines == null,
        ),
      );
      expect(title, findsOneWidget);
      expect(description, findsOneWidget);
      verifyNoPayloadElements();
      await tester.enterText(find.byType(TextField), payload);
      await tester.pumpAndSettle();
      expect(find.text(payload), findsWidgets);
      expect(find.text('No courses available yet.'), findsNothing);
      verifyNoPayloadElements();
      await tester.enterText(
        find.byType(TextField),
        'unmatched-security-query',
      );
      await tester.pumpAndSettle();
      expect(
        find.text('No courses found. Try a different word or category.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      verifyNoPayloadElements();
    });
    testWidgets('profile metadata preserves literal $payload', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            displayNameProvider.overrideWithValue(payload),
            currentEmailProvider.overrideWithValue('synthetic@example.test'),
            logoutProvider.overrideWith(LogoutNotifier.new),
            authStreamProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(payload), findsWidgets);
      expect(tester.takeException(), isNull);
      verifyNoPayloadElements();
    });
  }
}
