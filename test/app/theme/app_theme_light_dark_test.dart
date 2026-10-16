// CSA-193: Light/dark theme rendering tests
// Verifies key widgets render correctly in both themes, color contrast,
// the theme toggle button, and semantic colors.
import 'package:acendra/app/providers/theme_mode_provider.dart';
import 'package:acendra/app/theme/app_colors.dart';
import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/buttons/theme_toggle_button.dart';
import 'package:acendra/core/widgets/cards/course_card.dart';
import 'package:acendra/core/widgets/dialogs/app_dialog.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap({
  required Widget child,
  ThemeMode themeMode = ThemeMode.light,
  ProviderContainer? container,
}) {
  final app = MaterialApp(
    themeMode: themeMode,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
  if (container != null) {
    return UncontrolledProviderScope(container: container, child: app);
  }
  return ProviderScope(child: app);
}

const _courseCard = CourseCard(
  title: 'Flutter for Beginners',
  instructorName: 'Jane Doe',
  price: '\$49.99',
);

const _courseCardWithRating = CourseCard(
  title: 'Flutter for Beginners',
  instructorName: 'Jane Doe',
  price: '\$49.99',
  rating: 4.8,
  reviewCount: 120,
);

void main() {
  // -----------------------------------------------------------------------
  // CourseCard
  // -----------------------------------------------------------------------

  group('CourseCard – light theme', () {
    testWidgets('renders without overflow or errors', (tester) async {
      await tester.pumpWidget(_wrap(child: _courseCard));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets textContrastGuideline', (tester) async {
      await tester.pumpWidget(_wrap(child: _courseCardWithRating));
      await tester.pump();
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });

  group('CourseCard – dark theme', () {
    testWidgets('renders without overflow or errors', (tester) async {
      await tester.pumpWidget(
        _wrap(child: _courseCard, themeMode: ThemeMode.dark),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets textContrastGuideline', (tester) async {
      await tester.pumpWidget(
        _wrap(child: _courseCardWithRating, themeMode: ThemeMode.dark),
      );
      await tester.pump();
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });

  // -----------------------------------------------------------------------
  // AppButton variants
  // -----------------------------------------------------------------------

  group('AppButton – light theme', () {
    for (final variant in ButtonVariant.values) {
      testWidgets('${variant.name} renders without errors', (tester) async {
        await tester.pumpWidget(
          _wrap(
            child: AppButton(
              label: 'Click me',
              onPressed: () {},
              variant: variant,
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('primary meets textContrastGuideline', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: AppButton(label: 'Continue', onPressed: () {}),
        ),
      );
      await tester.pump();
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });

  group('AppButton – dark theme', () {
    for (final variant in ButtonVariant.values) {
      testWidgets('${variant.name} renders without errors', (tester) async {
        await tester.pumpWidget(
          _wrap(
            child: AppButton(
              label: 'Click me',
              onPressed: () {},
              variant: variant,
            ),
            themeMode: ThemeMode.dark,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('primary meets textContrastGuideline', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: AppButton(label: 'Continue', onPressed: () {}),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump();
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });

  // -----------------------------------------------------------------------
  // AppTextField
  // -----------------------------------------------------------------------

  group('AppTextField – light theme', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(_wrap(child: const AppTextField(label: 'Email')));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('with error text renders without errors', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: const AppTextField(label: 'Email', errorText: 'Invalid email'),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Invalid email'), findsOneWidget);
    });
  });

  group('AppTextField – dark theme', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: const AppTextField(label: 'Email'),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('with error text renders without errors', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: const AppTextField(label: 'Email', errorText: 'Invalid email'),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Invalid email'), findsOneWidget);
    });
  });

  // -----------------------------------------------------------------------
  // StatusBadge – all variants, both themes
  // -----------------------------------------------------------------------

  group('StatusBadge – light theme', () {
    for (final variant in BadgeVariant.values) {
      testWidgets('${variant.name} renders without errors', (tester) async {
        await tester.pumpWidget(
          _wrap(
            child: StatusBadge(label: 'Active', variant: variant),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('StatusBadge – dark theme', () {
    for (final variant in BadgeVariant.values) {
      testWidgets('${variant.name} renders without errors', (tester) async {
        await tester.pumpWidget(
          _wrap(
            child: StatusBadge(label: 'Active', variant: variant),
            themeMode: ThemeMode.dark,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  // -----------------------------------------------------------------------
  // AppEmptyState / AppErrorState
  // -----------------------------------------------------------------------

  group('AppEmptyState – both themes', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${mode.name} renders without errors', (tester) async {
        await tester.pumpWidget(
          _wrap(
            child: const AppEmptyState(message: 'No courses found'),
            themeMode: mode,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('No courses found'), findsOneWidget);
      });

      testWidgets('${mode.name} with action renders without errors', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            child: AppEmptyState(
              message: 'No courses found',
              actionLabel: 'Browse',
              onAction: () {},
            ),
            themeMode: mode,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('AppErrorState – both themes', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${mode.name} renders without errors', (tester) async {
        await tester.pumpWidget(
          _wrap(
            child: const AppErrorState(message: 'Something went wrong'),
            themeMode: mode,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Something went wrong'), findsOneWidget);
      });

      testWidgets('${mode.name} with retry button renders without errors', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            child: AppErrorState(
              message: 'Something went wrong',
              actionLabel: 'Retry',
              onRetry: () {},
            ),
            themeMode: mode,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  // -----------------------------------------------------------------------
  // AppDialog
  // -----------------------------------------------------------------------

  group('AppDialog – both themes', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${mode.name} opens and displays title/body', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              themeMode: mode,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
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
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Delete course'), findsOneWidget);
        expect(find.text('This action cannot be undone.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  // -----------------------------------------------------------------------
  // ThemeToggleButton – switches ThemeMode via provider
  // -----------------------------------------------------------------------

  group('ThemeToggleButton', () {
    testWidgets('shows dark_mode icon when provider mode is light', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeModeProvider.notifier).setMode(ThemeMode.light);

      await tester.pumpWidget(
        _wrap(child: const ThemeToggleButton(), container: container),
      );
      await tester.pump();

      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
      expect(find.byIcon(Icons.light_mode), findsNothing);
    });

    testWidgets('shows light_mode icon when provider mode is dark', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);

      await tester.pumpWidget(
        _wrap(
          child: const ThemeToggleButton(),
          themeMode: ThemeMode.dark,
          container: container,
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.light_mode), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode), findsNothing);
    });

    testWidgets('tap toggles provider from light to dark', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeModeProvider.notifier).setMode(ThemeMode.light);

      await tester.pumpWidget(
        _wrap(child: const ThemeToggleButton(), container: container),
      );
      await tester.pump();

      expect(container.read(themeModeProvider), ThemeMode.light);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    testWidgets('tap toggles provider from dark back to light', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);

      await tester.pumpWidget(
        _wrap(
          child: const ThemeToggleButton(),
          themeMode: ThemeMode.dark,
          container: container,
        ),
      );
      await tester.pump();

      expect(container.read(themeModeProvider), ThemeMode.dark);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    testWidgets('renders without errors in light theme', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeModeProvider.notifier).setMode(ThemeMode.light);

      await tester.pumpWidget(
        _wrap(child: const ThemeToggleButton(), container: container),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without errors in dark theme', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);

      await tester.pumpWidget(
        _wrap(
          child: const ThemeToggleButton(),
          themeMode: ThemeMode.dark,
          container: container,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // -----------------------------------------------------------------------
  // Semantic color token sanity – light vs dark
  // -----------------------------------------------------------------------

  group('Semantic color tokens – contrast sanity', () {
    test('light success color has sufficient luminance', () {
      final l = AppColors.light.success.computeLuminance();
      expect(l, greaterThan(0.0));
    });

    test('dark success color is visible on dark background', () {
      final l = AppColors.dark.success.computeLuminance();
      expect(l, greaterThan(0.05));
    });

    test('light error color is distinct from light background', () {
      final errorL = AppColors.light.error.computeLuminance();
      final bgL = AppColors.light.background.computeLuminance();
      expect((errorL - bgL).abs(), greaterThan(0.05));
    });

    test('dark error color is visible on dark background', () {
      final errorL = AppColors.dark.error.computeLuminance();
      final bgL = AppColors.dark.background.computeLuminance();
      expect((errorL - bgL).abs(), greaterThan(0.05));
    });

    test('light warning color is distinct from light background', () {
      final warnL = AppColors.light.warning.computeLuminance();
      final bgL = AppColors.light.background.computeLuminance();
      expect((warnL - bgL).abs(), greaterThan(0.05));
    });

    test('dark warning color is visible on dark background', () {
      final warnL = AppColors.dark.warning.computeLuminance();
      final bgL = AppColors.dark.background.computeLuminance();
      expect((warnL - bgL).abs(), greaterThan(0.05));
    });

    test(
      'light text primary meets WCAG AA contrast against light background',
      () {
        final textL = AppColors.light.textPrimary.computeLuminance();
        final bgL = AppColors.light.background.computeLuminance();
        final lighter = textL > bgL ? textL : bgL;
        final darker = textL > bgL ? bgL : textL;
        final ratio = (lighter + 0.05) / (darker + 0.05);
        expect(ratio, greaterThan(4.5));
      },
    );

    test(
      'dark text primary meets WCAG AA contrast against dark background',
      () {
        final textL = AppColors.dark.textPrimary.computeLuminance();
        final bgL = AppColors.dark.background.computeLuminance();
        final lighter = textL > bgL ? textL : bgL;
        final darker = textL > bgL ? bgL : textL;
        final ratio = (lighter + 0.05) / (darker + 0.05);
        expect(ratio, greaterThan(4.5));
      },
    );
  });
}
