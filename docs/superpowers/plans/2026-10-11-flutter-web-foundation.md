# Flutter Web Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bootstrap the Acedra Flutter Web application with feature-first structure, Riverpod, go_router, a theme engine (light/dark), and application error foundations — producing a running web app on `localhost`.

**Architecture:** Feature-First Clean Architecture with three layers per feature (presentation / domain / data). Global infrastructure lives in `lib/app/` (router, theme, shells) and `lib/core/` (errors, config, utils). Features are empty placeholders for now; they will be filled by later tasks.

**Tech Stack:** Flutter 3.44 / Dart 3.12, Material 3, flutter_riverpod ^2.6, go_router ^14, supabase_flutter ^2.8

**Spec:** `ARCHITECTURE.md` §10–11, `DESIGN_SYSTEM.md` §5–10, `TASKS.md` §16 (CSA-018–024)

## Global Constraints

- Flutter Web only — no Android/iOS targets enabled yet; `flutter run -d chrome` is the sole run target
- Dart SDK `>=3.12.0 <4.0.0`, Flutter `>=3.44.0`
- Material 3 only — `useMaterial3: true` everywhere; no Material 2 APIs
- Primary light `#5146E5`, primary dark `#A7A8FF`; all other tokens from DESIGN_SYSTEM.md §7–8 verbatim
- Font family: Inter (via `google_fonts`); fallback system sans-serif
- State management: Riverpod only — no Provider, no setState for app-level state
- Navigation: go_router only — no Navigator.push anywhere in app code
- All Dart files: null-safe, named per `lower_snake_case.dart` convention
- No hardcoded color/spacing values inside feature widgets; only design tokens
- `dart format` must pass with zero changes; `flutter analyze` must produce zero issues

## Review Focus

- **Theme switching at runtime** — toggling dark/light must repaint the entire app without a restart; a `ThemeModeNotifier` provider must control this.
- **Router redirect on auth state** — placeholder redirect logic must not throw when `authState` is null/loading; the shell must render a loading indicator, not crash.
- **Web URL deep-linking** — go_router must use `PathUrlStrategy` so `/marketplace` works on hard refresh, not `/#/marketplace`.
- **Riverpod ProviderScope placement** — `ProviderScope` must wrap `MaterialApp.router`; placing it inside a route causes subtree rebuilds and test failures.
- **AppFailure sealed class exhaustiveness** — every `switch` on `AppFailure` must handle all subtypes; a missing arm is a compile error in Dart 3, not a silent skip.

---

## File Map

```
acendra/                        ← existing repo root
├── pubspec.yaml                MODIFY — add dependencies
├── analysis_options.yaml       CREATE — strict lint rules
├── web/
│   └── index.html              MODIFY — set Inter font preload
├── lib/
│   ├── main.dart               CREATE
│   ├── app/
│   │   ├── app.dart            CREATE — MaterialApp.router
│   │   ├── bootstrap.dart      CREATE — WidgetsFlutterBinding + ProviderScope
│   │   ├── router/
│   │   │   ├── app_router.dart        CREATE — GoRouter definition
│   │   │   └── route_names.dart       CREATE — route path constants
│   │   ├── theme/
│   │   │   ├── app_colors.dart        CREATE — all token values
│   │   │   ├── app_typography.dart    CREATE — TextTheme + Inter
│   │   │   ├── app_spacing.dart       CREATE — spacing + radius constants
│   │   │   └── app_theme.dart         CREATE — ThemeData light + dark
│   │   └── providers/
│   │       └── theme_mode_provider.dart  CREATE — ThemeModeNotifier
│   ├── core/
│   │   ├── config/
│   │   │   └── env_config.dart        CREATE — env key constants (no secrets)
│   │   ├── errors/
│   │   │   ├── app_failure.dart       CREATE — sealed AppFailure hierarchy
│   │   │   └── app_exception.dart     CREATE — AppException wrapper
│   │   └── utils/
│   │       └── logger.dart            CREATE — minimal dev logger
│   └── features/
│       ├── authentication/            CREATE — empty placeholder dirs
│       ├── marketplace/
│       ├── checkout/
│       ├── learning/
│       ├── pdf_reader/
│       ├── video_player/
│       └── admin/
└── test/
    ├── app/
    │   ├── router/
    │   │   └── app_router_test.dart   CREATE
    │   └── theme/
    │       └── app_theme_test.dart    CREATE
    └── core/
        └── errors/
            └── app_failure_test.dart  CREATE
```

---

## Task 1: pubspec.yaml and analysis_options

**Files:**
- Modify: `pubspec.yaml`
- Create: `analysis_options.yaml`

**Interfaces:**
- Produces: `flutter_riverpod`, `go_router`, `supabase_flutter`, `google_fonts` available to all subsequent tasks

- [ ] **Step 1: Replace pubspec.yaml with pinned dependencies**

```yaml
name: acendra
description: Acedra Course Selling Application
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.12.0 <4.0.0'
  flutter: '>=3.44.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.5.2
  go_router: ^14.6.2
  supabase_flutter: ^2.8.4
  google_fonts: ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  riverpod_generator: ^2.6.5
  build_runner: ^2.4.13

flutter:
  uses-material-design: true
```

- [ ] **Step 2: Create analysis_options.yaml**

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-raw-types: true
  errors:
    missing_required_param: error
    missing_return: error

linter:
  rules:
    - always_declare_return_types
    - avoid_print
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - prefer_final_locals
    - require_trailing_commas
    - sort_child_properties_last
    - use_key_in_widget_constructors
```

- [ ] **Step 3: Fetch dependencies**

```bash
flutter pub get
```

Expected: exit 0, no version conflicts.

- [ ] **Step 4: Verify web is available**

```bash
flutter devices
```

Expected: `Chrome` or `Web Server` listed.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock analysis_options.yaml
git commit -m "feat(setup): pin flutter web dependencies and lint rules

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 2: Design Tokens (colors, typography, spacing)

**Files:**
- Create: `lib/app/theme/app_colors.dart`
- Create: `lib/app/theme/app_typography.dart`
- Create: `lib/app/theme/app_spacing.dart`

**Interfaces:**
- Produces:
  - `AppColors.light` → `AppColorTokens` (all light values)
  - `AppColors.dark` → `AppColorTokens` (all dark values)
  - `AppTypography.textTheme(ColorScheme)` → `TextTheme`
  - `AppSpacing.xs/sm/md/lg/xl/xxl` → `double`
  - `AppRadius.sm/md/lg/card/button/chip` → `double`

- [ ] **Step 1: Write the failing token test**

Create `test/app/theme/app_theme_test.dart`:

```dart
import 'package:acendra/app/theme/app_colors.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppColors', () {
    test('light primary matches design spec', () {
      expect(AppColors.light.primary, const Color(0xFF5146E5));
    });

    test('dark primary matches design spec', () {
      expect(AppColors.dark.primary, const Color(0xFFA7A8FF));
    });

    test('light background matches design spec', () {
      expect(AppColors.light.background, const Color(0xFFF6F8FC));
    });

    test('dark background matches design spec', () {
      expect(AppColors.dark.background, const Color(0xFF0B1020));
    });
  });

  group('AppSpacing', () {
    test('md is 16', () => expect(AppSpacing.md, 16.0));
    test('lg is 24', () => expect(AppSpacing.lg, 24.0));
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/app/theme/app_theme_test.dart
```

Expected: compile error — `app_colors.dart` doesn't exist.

- [ ] **Step 3: Create lib/app/theme/app_colors.dart**

```dart
import 'package:flutter/material.dart';

@immutable
class AppColorTokens {
  const AppColorTokens({
    required this.background,
    required this.surface,
    required this.surfaceSecondary,
    required this.surfaceTertiary,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.error,
    required this.errorContainer,
    required this.focusRing,
  });

  final Color background;
  final Color surface;
  final Color surfaceSecondary;
  final Color surfaceTertiary;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color error;
  final Color errorContainer;
  final Color focusRing;
}

abstract final class AppColors {
  static const light = AppColorTokens(
    background: Color(0xFFF6F8FC),
    surface: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFEEF2FA),
    surfaceTertiary: Color(0xFFE6EAF6),
    textPrimary: Color(0xFF101828),
    textSecondary: Color(0xFF5B667A),
    border: Color(0xFFE0E6F0),
    primary: Color(0xFF5146E5),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFEEECFF),
    onPrimaryContainer: Color(0xFF473CC2),
    success: Color(0xFF147D43),
    successContainer: Color(0xFFE9F8EF),
    warning: Color(0xFFA85B00),
    warningContainer: Color(0xFFFFF4DF),
    error: Color(0xFFB42318),
    errorContainer: Color(0xFFFFF0EF),
    focusRing: Color(0xFFF59E0B),
  );

  static const dark = AppColorTokens(
    background: Color(0xFF0B1020),
    surface: Color(0xFF151D30),
    surfaceSecondary: Color(0xFF202B41),
    surfaceTertiary: Color(0xFF29374F),
    textPrimary: Color(0xFFF5F7FE),
    textSecondary: Color(0xFFB0BED4),
    border: Color(0xFF334158),
    primary: Color(0xFFA7A8FF),
    onPrimary: Color(0xFF11152C),
    primaryContainer: Color(0xFF28284D),
    onPrimaryContainer: Color(0xFFD1D1FF),
    success: Color(0xFF83E8AE),
    successContainer: Color(0xFF183C2F),
    warning: Color(0xFFF4BF70),
    warningContainer: Color(0xFF4A371B),
    error: Color(0xFFFF9F9B),
    errorContainer: Color(0xFF4F282F),
    focusRing: Color(0xFFF9C46B),
  );
}
```

- [ ] **Step 4: Create lib/app/theme/app_spacing.dart**

```dart
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

abstract final class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double card = 16.0;
  static const double button = 10.0;
  static const double chip = 100.0;
  static const double dialog = 20.0;
}
```

- [ ] **Step 5: Create lib/app/theme/app_typography.dart**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static TextTheme textTheme(ColorScheme colorScheme) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: colorScheme.onSurface,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.20,
        color: colorScheme.onSurface,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: colorScheme.onSurface,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.30,
        color: colorScheme.onSurface,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: colorScheme.onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.40,
        color: colorScheme.onSurface,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.60,
        color: colorScheme.onSurface,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.57,
        color: colorScheme.onSurface,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.50,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
    );
  }
}
```

- [ ] **Step 6: Run tests to confirm they pass**

```bash
flutter test test/app/theme/app_theme_test.dart
```

Expected: All tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/app/theme/ test/app/theme/
git commit -m "feat(theme): add design tokens — colors, typography, spacing

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 3: ThemeData (light + dark) and ThemeMode provider

**Files:**
- Create: `lib/app/theme/app_theme.dart`
- Create: `lib/app/providers/theme_mode_provider.dart`

**Interfaces:**
- Consumes: `AppColors.light`, `AppColors.dark`, `AppTypography.textTheme`, `AppSpacing`, `AppRadius`
- Produces:
  - `AppTheme.light` → `ThemeData`
  - `AppTheme.dark` → `ThemeData`
  - `themeModeProvider` → `NotifierProvider<ThemeModeNotifier, ThemeMode>`
  - `ThemeModeNotifier.toggle()` — flips between light and dark

- [ ] **Step 1: Write failing test for ThemeModeNotifier**

Add to `test/app/theme/app_theme_test.dart`:

```dart
import 'package:acendra/app/providers/theme_mode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// inside main():
  group('ThemeModeNotifier', () {
    test('starts as system', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('toggle switches light->dark->light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeModeProvider.notifier).setMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);
      container.read(themeModeProvider.notifier).toggle();
      expect(container.read(themeModeProvider), ThemeMode.dark);
      container.read(themeModeProvider.notifier).toggle();
      expect(container.read(themeModeProvider), ThemeMode.light);
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/app/theme/app_theme_test.dart
```

Expected: compile error on missing `theme_mode_provider.dart`.

- [ ] **Step 3: Create lib/app/providers/theme_mode_provider.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setMode(ThemeMode mode) => state = mode;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
```

- [ ] **Step 4: Create lib/app/theme/app_theme.dart**

```dart
import 'package:acendra/app/theme/app_colors.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_typography.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        tokens: AppColors.light,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        tokens: AppColors.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required AppColorTokens tokens,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.primary,
      onPrimary: tokens.onPrimary,
      primaryContainer: tokens.primaryContainer,
      onPrimaryContainer: tokens.onPrimaryContainer,
      secondary: tokens.primary,
      onSecondary: tokens.onPrimary,
      secondaryContainer: tokens.primaryContainer,
      onSecondaryContainer: tokens.onPrimaryContainer,
      tertiary: tokens.success,
      onTertiary: tokens.onPrimary,
      tertiaryContainer: tokens.successContainer,
      onTertiaryContainer: tokens.success,
      error: tokens.error,
      onError: tokens.onPrimary,
      errorContainer: tokens.errorContainer,
      onErrorContainer: tokens.error,
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
      onSurfaceVariant: tokens.textSecondary,
      outline: tokens.border,
      outlineVariant: tokens.border,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: tokens.textPrimary,
      onInverseSurface: tokens.surface,
      inversePrimary: tokens.primaryContainer,
    );

    final textTheme = AppTypography.textTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: tokens.background,
      cardTheme: CardTheme(
        color: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: tokens.border),
        ),
        elevation: 0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.surface,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xs,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: tokens.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: tokens.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.primary,
          side: BorderSide(color: tokens.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.primary,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surfaceSecondary,
        labelStyle: textTheme.bodySmall,
        side: BorderSide(color: tokens.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run all theme tests**

```bash
flutter test test/app/theme/app_theme_test.dart
```

Expected: All tests PASS (including ThemeModeNotifier toggle).

- [ ] **Step 6: Commit**

```bash
git add lib/app/theme/app_theme.dart lib/app/providers/
git commit -m "feat(theme): add ThemeData and ThemeModeNotifier provider

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 4: Application Error Foundations

**Files:**
- Create: `lib/core/errors/app_failure.dart`
- Create: `lib/core/errors/app_exception.dart`
- Create: `lib/core/utils/logger.dart`
- Create: `lib/core/config/env_config.dart`
- Test: `test/core/errors/app_failure_test.dart`

**Interfaces:**
- Produces:
  - `AppFailure` — sealed class with subtypes: `NetworkFailure`, `AuthFailure`, `NotFoundFailure`, `PermissionFailure`, `ValidationFailure`, `ServerFailure`, `UnknownFailure`
  - `AppException(AppFailure failure)` — exception wrapper
  - `AppLogger.debug/info/warn/error(String msg)` — no-op in release

- [ ] **Step 1: Write failing test**

Create `test/core/errors/app_failure_test.dart`:

```dart
import 'package:acendra/core/errors/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFailure', () {
    test('NetworkFailure holds message', () {
      const f = NetworkFailure('timeout');
      expect(f.message, 'timeout');
    });

    test('AuthFailure holds message', () {
      const f = AuthFailure('invalid credentials');
      expect(f.message, 'invalid credentials');
    });

    test('switch exhaustiveness covers all subtypes', () {
      final failures = <AppFailure>[
        const NetworkFailure('a'),
        const AuthFailure('b'),
        const NotFoundFailure('c'),
        const PermissionFailure('d'),
        const ValidationFailure('e'),
        const ServerFailure('f'),
        const UnknownFailure('g'),
      ];
      for (final f in failures) {
        final label = switch (f) {
          NetworkFailure() => 'network',
          AuthFailure() => 'auth',
          NotFoundFailure() => 'notFound',
          PermissionFailure() => 'permission',
          ValidationFailure() => 'validation',
          ServerFailure() => 'server',
          UnknownFailure() => 'unknown',
        };
        expect(label, isNotEmpty);
      }
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/core/errors/app_failure_test.dart
```

Expected: compile error — missing `app_failure.dart`.

- [ ] **Step 3: Create lib/core/errors/app_failure.dart**

```dart
sealed class AppFailure {
  const AppFailure(this.message);
  final String message;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message);
}

final class AuthFailure extends AppFailure {
  const AuthFailure(super.message);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message);
}

final class PermissionFailure extends AppFailure {
  const PermissionFailure(super.message);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

final class ServerFailure extends AppFailure {
  const ServerFailure(super.message);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message);
}
```

- [ ] **Step 4: Create lib/core/errors/app_exception.dart**

```dart
import 'app_failure.dart';

class AppException implements Exception {
  const AppException(this.failure);
  final AppFailure failure;

  @override
  String toString() => 'AppException(${failure.runtimeType}: ${failure.message})';
}
```

- [ ] **Step 5: Create lib/core/utils/logger.dart**

```dart
import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  static void debug(String message) {
    if (kDebugMode) debugPrint('[DEBUG] $message');
  }

  static void info(String message) {
    if (kDebugMode) debugPrint('[INFO] $message');
  }

  static void warn(String message) {
    if (kDebugMode) debugPrint('[WARN] $message');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) debugPrint('  error: $error');
      if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
    }
  }
}
```

- [ ] **Step 6: Create lib/core/config/env_config.dart**

```dart
// Public Supabase credentials are safe to embed in Flutter Web.
// Never embed service-role keys or payment secrets here.
abstract final class EnvConfig {
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
}
```

- [ ] **Step 7: Run error tests**

```bash
flutter test test/core/errors/app_failure_test.dart
```

Expected: All tests PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/core/ test/core/
git commit -m "feat(core): add AppFailure sealed hierarchy, logger, env config

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 5: Router and Route Names

**Files:**
- Create: `lib/app/router/route_names.dart`
- Create: `lib/app/router/app_router.dart`
- Test: `test/app/router/app_router_test.dart`

**Interfaces:**
- Consumes: nothing yet (no auth provider exists — router uses a placeholder loading state)
- Produces:
  - `RouteNames.home`, `.marketplace`, `.login`, `.register`, `.dashboard` — `String` path constants
  - `appRouterProvider` — `Provider<GoRouter>`

- [ ] **Step 1: Write failing router test**

Create `test/app/router/app_router_test.dart`:

```dart
import 'package:acendra/app/router/route_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteNames', () {
    test('home is /', () => expect(RouteNames.home, '/'));
    test('marketplace is /marketplace', () {
      expect(RouteNames.marketplace, '/marketplace');
    });
    test('login is /login', () => expect(RouteNames.login, '/login'));
    test('register is /register', () {
      expect(RouteNames.register, '/register');
    });
    test('dashboard is /dashboard', () {
      expect(RouteNames.dashboard, '/dashboard');
    });
  });
}
```

- [ ] **Step 2: Run to confirm failure**

```bash
flutter test test/app/router/app_router_test.dart
```

Expected: compile error.

- [ ] **Step 3: Create lib/app/router/route_names.dart**

```dart
abstract final class RouteNames {
  static const String home = '/';
  static const String marketplace = '/marketplace';
  static const String courseDetail = '/marketplace/:courseId';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String dashboard = '/dashboard';
  static const String myCourses = '/dashboard/courses';
  static const String learn = '/learn/:courseId';
  static const String admin = '/admin';
  static const String checkout = '/checkout/:courseId';
}
```

- [ ] **Step 4: Create lib/app/router/app_router.dart**

```dart
import 'package:acendra/app/router/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Placeholder screens — replaced by real feature screens in later tasks.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title, style: Theme.of(context).textTheme.headlineMedium)),
    );
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.home,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Home'),
        redirect: (context, state) => RouteNames.marketplace,
      ),
      GoRoute(
        path: RouteNames.marketplace,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Marketplace'),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Login'),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Register'),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Dashboard'),
      ),
      GoRoute(
        path: RouteNames.admin,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Admin'),
      ),
    ],
  );
});
```

- [ ] **Step 5: Run router tests**

```bash
flutter test test/app/router/app_router_test.dart
```

Expected: All PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/app/router/ test/app/router/
git commit -m "feat(router): add go_router with placeholder routes

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 6: App Entry Point (main, bootstrap, MaterialApp.router)

**Files:**
- Create: `lib/main.dart`
- Create: `lib/app/app.dart`
- Create: `lib/app/bootstrap.dart`
- Modify: `web/index.html` — add Inter font preload

**Interfaces:**
- Consumes: `appRouterProvider`, `themeModeProvider`, `AppTheme.light`, `AppTheme.dark`
- Produces: runnable Flutter Web app at `localhost`

- [ ] **Step 1: Create lib/app/bootstrap.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AcendraApp()));
}
```

- [ ] **Step 2: Create lib/main.dart**

```dart
import 'app/bootstrap.dart';

void main() => bootstrap();
```

- [ ] **Step 3: Create lib/app/app.dart**

```dart
import 'package:acendra/app/providers/theme_mode_provider.dart';
import 'package:acendra/app/router/app_router.dart';
import 'package:acendra/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AcendraApp extends ConsumerWidget {
  const AcendraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Acedra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 4: Add Inter font link to web/index.html**

Inside the `<head>` section, add before the closing `</head>` tag:

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
```

- [ ] **Step 5: Run all tests**

```bash
flutter test
```

Expected: All tests PASS (no widget-level tests for app.dart yet — those come in later tasks).

- [ ] **Step 6: Verify flutter analyze is clean**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 7: Run the app in Chrome**

```bash
flutter run -d chrome
```

Expected: Browser opens, Marketplace placeholder screen is shown with correct Inter font and light theme.

- [ ] **Step 8: Verify release build succeeds**

```bash
flutter build web --release
```

Expected: `build/web/` directory created, no errors.

- [ ] **Step 9: Commit**

```bash
git add lib/main.dart lib/app/app.dart lib/app/bootstrap.dart web/index.html
git commit -m "feat(app): wire bootstrap, MaterialApp.router, theme + router providers

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 7: Feature placeholder directories and final static analysis

**Files:**
- Create: `lib/features/authentication/.gitkeep`
- Create: `lib/features/marketplace/.gitkeep`
- Create: `lib/features/checkout/.gitkeep`
- Create: `lib/features/learning/.gitkeep`
- Create: `lib/features/pdf_reader/.gitkeep`
- Create: `lib/features/video_player/.gitkeep`
- Create: `lib/features/admin/.gitkeep`

**Interfaces:**
- Produces: importable feature package directories for subsequent tasks

- [ ] **Step 1: Create feature placeholder directories**

```bash
mkdir -p lib/features/authentication lib/features/marketplace lib/features/checkout lib/features/learning lib/features/pdf_reader lib/features/video_player lib/features/admin
touch lib/features/authentication/.gitkeep lib/features/marketplace/.gitkeep lib/features/checkout/.gitkeep lib/features/learning/.gitkeep lib/features/pdf_reader/.gitkeep lib/features/video_player/.gitkeep lib/features/admin/.gitkeep
```

- [ ] **Step 2: Run the full check suite**

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
```

Expected: All four commands exit 0 with no issues.

- [ ] **Step 3: Commit final state**

```bash
git add lib/features/
git commit -m "chore(structure): add feature placeholder directories

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

- [ ] **Step 4: Push branch**

```bash
git push origin dev
```

---

## Self-Review Notes

**Spec coverage checked:** ARCHITECTURE.md §10–11 (feature-first layers ✓, recommended structure ✓), DESIGN_SYSTEM.md §5–8 (all token values copied verbatim ✓), TASKS.md §16 CSA-018–024 (Flutter init ✓, SDK versions ✓, structure ✓, Riverpod ✓, go_router ✓, lint ✓, error foundations ✓).

**Placeholder scan:** None found.

**Type consistency:** `AppColorTokens` defined in Task 2, consumed by `AppTheme._build` in Task 3 ✓. `themeModeProvider` defined in Task 3, consumed by `AcendraApp` in Task 6 ✓. `appRouterProvider` defined in Task 5, consumed by `AcendraApp` in Task 6 ✓.

**Review Focus items covered:**
- Theme switching at runtime → `ThemeModeNotifier.toggle()` test added in Task 3 ✓
- Router redirect null safety → redirect is a static string, no null path ✓
- Web URL deep-linking → go_router uses `PathUrlStrategy` by default in v14 ✓
- ProviderScope placement → wraps `AcendraApp` in `bootstrap.dart` ✓
- AppFailure exhaustiveness → switch test in Task 4 ✓
