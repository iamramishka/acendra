# Phase 2 – Design System Components Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the shared widget library (breakpoints, buttons, inputs, cards, feedback, shells) that every feature UI consumes.

**Architecture:** Feature-First Clean Architecture; all shared widgets live in `lib/core/widgets/`; navigation shells live in `lib/core/widgets/navigation/`; `AppThemeExtension` hangs off `ThemeData.extensions` for semantic colours not in Material's `ColorScheme`; `AppBreakpoints` + `ResponsiveContainer` wrap layout concerns; router is extended with `ShellRoute` entries.

**Tech Stack:** Flutter 3.44, Dart 3.12, Material 3, Riverpod 2.6.1, go_router 14.6.2, google_fonts 6.2.1

**Spec:** `DESIGN_SYSTEM.md` (root of repo)

## Global Constraints

- Flutter Web only — no iOS/Android platform code
- `useMaterial3: true` always; no Material 2 APIs
- All colours from `AppColors.light` / `AppColors.dark` via `AppThemeExtension` or `ColorScheme` — no hard-coded hex in widgets
- Spacing via `AppSpacing.*`, radii via `AppRadius.*`
- DESIGN_SYSTEM.md §12 radii: button=12, input=12, card=18, dialog=20 — **update `AppRadius` values to match**
- Button min-heights: small≥36 px, medium≥44 px, large≥48 px
- Breakpoints: compact <600, medium 600–1023, expanded ≥1024
- Admin sidebar fixed width: 248 px
- Max content width: 1280 px
- Page margins: compact=16, medium=24, expanded=32
- `dart format`, `flutter analyze`, `flutter test`, `flutter build web --release` must all pass before PR
- Never commit `.env`; never embed service-role keys

## Review Focus

1. **Breakpoint boundary at exactly 600 / 1024** — a viewport of 599 should be compact, 600 medium, 1023 medium, 1024 expanded; off-by-one breaks layout on common tablet widths.
2. **AppButton loading state blocks tap** — while `isLoading: true`, the button must not fire `onPressed`; a widget test that taps during loading and asserts the callback was not called.
3. **AppThemeExtension round-trip** — `Theme.of(context).extension<AppThemeExtension>()` must be non-null in both light and dark; a null dereference would crash every screen using semantic colours.
4. **ShellRoute child propagation** — go_router's `ShellRoute` passes the `child` widget; shells that forget to render it produce a blank screen with no error.
5. **AppTextField obscureText toggle** — the password field's visibility icon must actually toggle `obscureText`; a test that taps the icon and asserts the field switches modes.

---

### Task 1: AppRadius correction + AppThemeExtension

**Files:**
- Modify: `lib/app/theme/app_spacing.dart` (update AppRadius values)
- Create: `lib/app/theme/app_theme_extension.dart`
- Modify: `lib/app/theme/app_theme.dart` (add extension to ThemeData)
- Modify: `test/app/theme/app_theme_test.dart` (add extension tests)

**Interfaces:**
- Consumes: `AppColorTokens` (from `app_colors.dart`)
- Produces: `AppThemeExtension` ThemeExtension with fields: `success`, `successContainer`, `warning`, `warningContainer`, `focusRing`, `surfaceSecondary`, `surfaceTertiary`, `textSecondary`, `border`; retrievable via `Theme.of(ctx).extension<AppThemeExtension>()!`

- [ ] **Step 1: Write failing tests**

```dart
// test/app/theme/app_theme_test.dart — add these tests
test('AppRadius.button equals 12', () {
  expect(AppRadius.button, 12.0);
});

test('AppRadius.card equals 18', () {
  expect(AppRadius.card, 18.0);
});

test('AppThemeExtension is present in light theme', () {
  final theme = AppTheme.light;
  final ext = theme.extensions[AppThemeExtension] as AppThemeExtension?;
  expect(ext, isNotNull);
  expect(ext!.success, AppColors.light.success);
});

test('AppThemeExtension is present in dark theme', () {
  final theme = AppTheme.dark;
  final ext = theme.extensions[AppThemeExtension] as AppThemeExtension?;
  expect(ext, isNotNull);
  expect(ext!.success, AppColors.dark.success);
});
```

- [ ] **Step 2: Run tests — expect failures**

```bash
flutter test test/app/theme/app_theme_test.dart
```
Expected: FAIL — AppRadius.button != 12, AppThemeExtension not found.

- [ ] **Step 3: Fix AppRadius in app_spacing.dart**

```dart
abstract final class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;   // inputs
  static const double lg = 16.0;
  static const double card = 18.0; // updated from 16
  static const double button = 12.0; // updated from 10
  static const double chip = 100.0;
  static const double dialog = 20.0;
}
```

- [ ] **Step 4: Create app_theme_extension.dart**

```dart
import 'package:acendra/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.focusRing,
    required this.surfaceSecondary,
    required this.surfaceTertiary,
    required this.textSecondary,
    required this.border,
  });

  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color focusRing;
  final Color surfaceSecondary;
  final Color surfaceTertiary;
  final Color textSecondary;
  final Color border;

  static AppThemeExtension fromTokens(AppColorTokens t) => AppThemeExtension(
        success: t.success,
        successContainer: t.successContainer,
        warning: t.warning,
        warningContainer: t.warningContainer,
        focusRing: t.focusRing,
        surfaceSecondary: t.surfaceSecondary,
        surfaceTertiary: t.surfaceTertiary,
        textSecondary: t.textSecondary,
        border: t.border,
      );

  @override
  AppThemeExtension copyWith({
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? focusRing,
    Color? surfaceSecondary,
    Color? surfaceTertiary,
    Color? textSecondary,
    Color? border,
  }) =>
      AppThemeExtension(
        success: success ?? this.success,
        successContainer: successContainer ?? this.successContainer,
        warning: warning ?? this.warning,
        warningContainer: warningContainer ?? this.warningContainer,
        focusRing: focusRing ?? this.focusRing,
        surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
        surfaceTertiary: surfaceTertiary ?? this.surfaceTertiary,
        textSecondary: textSecondary ?? this.textSecondary,
        border: border ?? this.border,
      );

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      surfaceSecondary: Color.lerp(surfaceSecondary, other.surfaceSecondary, t)!,
      surfaceTertiary: Color.lerp(surfaceTertiary, other.surfaceTertiary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}
```

- [ ] **Step 5: Add extension to AppTheme._build in app_theme.dart**

In the `return ThemeData(...)` block, add:
```dart
extensions: [AppThemeExtension.fromTokens(tokens)],
```

- [ ] **Step 6: Run tests — expect pass**

```bash
flutter test test/app/theme/app_theme_test.dart
```
Expected: all pass (was 8, now 12).

- [ ] **Step 7: Commit**

```bash
git add lib/app/theme/app_spacing.dart lib/app/theme/app_theme_extension.dart lib/app/theme/app_theme.dart test/app/theme/app_theme_test.dart
git commit -m "feat(theme): add AppThemeExtension + fix AppRadius per DESIGN_SYSTEM"
```

---

### Task 2: AppBreakpoints + ResponsiveContainer

**Files:**
- Create: `lib/app/theme/app_breakpoints.dart`
- Create: `lib/core/widgets/layout/responsive_container.dart`
- Create: `test/core/widgets/layout/responsive_container_test.dart`

**Interfaces:**
- Consumes: nothing from earlier tasks
- Produces:
  - `AppBreakpoints.compact = 600.0`, `AppBreakpoints.medium = 1024.0`
  - `enum ScreenLayout { compact, medium, expanded }`
  - `BuildContext.layout` → `ScreenLayout`
  - `ResponsiveContainer({required Widget child, double? maxWidth})` — centres child, applies per-breakpoint horizontal padding, caps width at `maxWidth ?? 1280`

- [ ] **Step 1: Write failing tests**

```dart
// test/core/widgets/layout/responsive_container_test.dart
import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('layout is compact below 600', (tester) async {
    tester.view.physicalSize = const Size(599, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            expect(ctx.layout, ScreenLayout.compact);
            return const SizedBox();
          },
        ),
      ),
    );
  });

  testWidgets('layout is medium at 600', (tester) async {
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            expect(ctx.layout, ScreenLayout.medium);
            return const SizedBox();
          },
        ),
      ),
    );
  });

  testWidgets('layout is expanded at 1024', (tester) async {
    tester.view.physicalSize = const Size(1024, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            expect(ctx.layout, ScreenLayout.expanded);
            return const SizedBox();
          },
        ),
      ),
    );
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/core/widgets/layout/responsive_container_test.dart
```
Expected: FAIL — `AppBreakpoints` not defined.

- [ ] **Step 3: Create app_breakpoints.dart**

```dart
abstract final class AppBreakpoints {
  static const double compact = 600.0;
  static const double medium = 1024.0;
  static const double maxContentWidth = 1280.0;
  static const double adminSidebarWidth = 248.0;
  static const double marginCompact = 16.0;
  static const double marginMedium = 24.0;
  static const double marginExpanded = 32.0;
}

enum ScreenLayout { compact, medium, expanded }
```

- [ ] **Step 4: Create responsive_container.dart**

```dart
import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:flutter/material.dart';

extension ScreenLayoutExtension on BuildContext {
  ScreenLayout get layout {
    final w = MediaQuery.sizeOf(this).width;
    if (w < AppBreakpoints.compact) return ScreenLayout.compact;
    if (w < AppBreakpoints.medium) return ScreenLayout.medium;
    return ScreenLayout.expanded;
  }

  double get pageMargin => switch (layout) {
        ScreenLayout.compact => AppBreakpoints.marginCompact,
        ScreenLayout.medium => AppBreakpoints.marginMedium,
        ScreenLayout.expanded => AppBreakpoints.marginExpanded,
      };
}

class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({super.key, required this.child, this.maxWidth});
  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final margin = context.pageMargin;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? AppBreakpoints.maxContentWidth,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: margin),
          child: child,
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run — expect PASS**

```bash
flutter test test/core/widgets/layout/responsive_container_test.dart
```
Expected: 3/3 pass.

- [ ] **Step 6: Commit**

```bash
git add lib/app/theme/app_breakpoints.dart lib/core/widgets/layout/responsive_container.dart test/core/widgets/layout/responsive_container_test.dart
git commit -m "feat(layout): add AppBreakpoints, ScreenLayout, ResponsiveContainer"
```

---

### Task 3: AppButton

**Files:**
- Create: `lib/core/widgets/buttons/app_button.dart`
- Create: `test/core/widgets/buttons/app_button_test.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppRadius.button`, `AppSpacing`, `AppThemeExtension`
- Produces: `AppButton({required String label, required VoidCallback? onPressed, ButtonVariant variant, ButtonSize size, bool isLoading, Widget? icon})`; `enum ButtonVariant { primary, secondary, outlined, destructive }`; `enum ButtonSize { small, medium, large }`

- [ ] **Step 1: Write failing tests**

```dart
// test/core/widgets/buttons/app_button_test.dart
import 'package:acendra/app/app.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('primary button fires onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      AppButton(label: 'Go', onPressed: () => tapped = true),
    ));
    await tester.tap(find.byType(AppButton));
    expect(tapped, isTrue);
  });

  testWidgets('button does not fire when isLoading', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      AppButton(
        label: 'Go',
        onPressed: () => tapped = true,
        isLoading: true,
      ),
    ));
    await tester.tap(find.byType(AppButton));
    expect(tapped, isFalse);
  });

  testWidgets('button does not fire when onPressed is null', (tester) async {
    await tester.pumpWidget(_wrap(
      const AppButton(label: 'Go', onPressed: null),
    ));
    await tester.tap(find.byType(AppButton));
    // no exception = pass
  });

  testWidgets('destructive variant renders without error', (tester) async {
    await tester.pumpWidget(_wrap(
      AppButton(
        label: 'Delete',
        onPressed: () {},
        variant: ButtonVariant.destructive,
      ),
    ));
    expect(find.byType(AppButton), findsOneWidget);
  });

  testWidgets('small size renders without error', (tester) async {
    await tester.pumpWidget(_wrap(
      AppButton(
        label: 'Small',
        onPressed: () {},
        size: ButtonSize.small,
      ),
    ));
    expect(find.byType(AppButton), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/core/widgets/buttons/app_button_test.dart
```
Expected: FAIL — AppButton not defined.

- [ ] **Step 3: Create app_button.dart**

```dart
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';

enum ButtonVariant { primary, secondary, outlined, destructive }

enum ButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final minHeight = switch (size) {
      ButtonSize.small => 36.0,
      ButtonSize.medium => 44.0,
      ButtonSize.large => 48.0,
    };

    final hPad = switch (size) {
      ButtonSize.small => AppSpacing.md,
      ButtonSize.medium => AppSpacing.lg,
      ButtonSize.large => AppSpacing.xl,
    };

    final vPad = switch (size) {
      ButtonSize.small => AppSpacing.xs + 2,
      ButtonSize.medium => AppSpacing.sm + 2,
      ButtonSize.large => AppSpacing.md - 2,
    };

    Color bgColor;
    Color fgColor;
    Color? borderColor;

    switch (variant) {
      case ButtonVariant.primary:
        bgColor = cs.primary;
        fgColor = cs.onPrimary;
      case ButtonVariant.secondary:
        bgColor = cs.primaryContainer;
        fgColor = cs.onPrimaryContainer;
      case ButtonVariant.outlined:
        bgColor = Colors.transparent;
        fgColor = cs.primary;
        borderColor = cs.primary;
      case ButtonVariant.destructive:
        bgColor = cs.error;
        fgColor = cs.onError;
    }

    final effectiveOnPressed = (isLoading || onPressed == null) ? null : onPressed;

    final content = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fgColor,
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon!,
                  const SizedBox(width: AppSpacing.sm),
                  Text(label),
                ],
              )
            : Text(label);

    final style = ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: 0,
      minimumSize: Size(0, minHeight),
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      side: borderColor != null ? BorderSide(color: borderColor) : null,
      textStyle: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return ElevatedButton(
      onPressed: effectiveOnPressed,
      style: style,
      child: content,
    );
  }
}
```

- [ ] **Step 4: Run — expect PASS**

```bash
flutter test test/core/widgets/buttons/app_button_test.dart
```
Expected: 5/5 pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/buttons/app_button.dart test/core/widgets/buttons/app_button_test.dart
git commit -m "feat(widgets): add AppButton with variant, size, loading support"
```

---

### Task 4: AppTextField + AppPasswordField

**Files:**
- Create: `lib/core/widgets/inputs/app_text_field.dart`
- Create: `test/core/widgets/inputs/app_text_field_test.dart`

**Interfaces:**
- Consumes: `AppThemeExtension`, `AppRadius.md`
- Produces:
  - `AppTextField({String? label, String? hint, String? errorText, TextEditingController? controller, ...standardTextFieldParams})`
  - `AppPasswordField({String? label, String? hint, String? errorText, TextEditingController? controller})` — wraps `AppTextField` with eye-toggle

- [ ] **Step 1: Write failing tests**

```dart
// test/core/widgets/inputs/app_text_field_test.dart
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('AppTextField renders label', (tester) async {
    await tester.pumpWidget(_wrap(
      const AppTextField(label: 'Email'),
    ));
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('AppTextField shows errorText', (tester) async {
    await tester.pumpWidget(_wrap(
      const AppTextField(label: 'Email', errorText: 'Required'),
    ));
    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('AppPasswordField toggles obscureText', (tester) async {
    await tester.pumpWidget(_wrap(
      const AppPasswordField(label: 'Password'),
    ));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isTrue);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    final fieldAfter = tester.widget<TextField>(find.byType(TextField));
    expect(fieldAfter.obscureText, isFalse);
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/core/widgets/inputs/app_text_field_test.dart
```
Expected: FAIL — AppTextField not defined.

- [ ] **Step 3: Create app_text_field.dart**

```dart
import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.focusNode,
    this.enabled = true,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
  });

  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final bool enabled;
  final int? maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      autofillHints: autofillHints,
      focusNode: focusNode,
      enabled: enabled,
      maxLines: obscureText ? 1 : maxLines,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
  });

  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool enabled;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      hint: widget.hint,
      errorText: widget.errorText,
      controller: widget.controller,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      obscureText: _obscure,
      keyboardType: TextInputType.visiblePassword,
      autofillHints: const [AutofillHints.password],
      suffixIcon: IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}
```

- [ ] **Step 4: Run — expect PASS**

```bash
flutter test test/core/widgets/inputs/app_text_field_test.dart
```
Expected: 3/3 pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/inputs/app_text_field.dart test/core/widgets/inputs/app_text_field_test.dart
git commit -m "feat(widgets): add AppTextField and AppPasswordField"
```

---

### Task 5: CourseCard

**Files:**
- Create: `lib/core/widgets/cards/course_card.dart`
- Create: `test/core/widgets/cards/course_card_test.dart`

**Interfaces:**
- Consumes: `AppThemeExtension`, `AppSpacing`, `AppRadius.card`
- Produces: `CourseCard({required String title, required String instructorName, required String price, String? imageUrl, double? rating, int? reviewCount, VoidCallback? onTap})`

- [ ] **Step 1: Write failing tests**

```dart
// test/core/widgets/cards/course_card_test.dart
import 'package:acendra/core/widgets/cards/course_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('CourseCard renders title and instructor', (tester) async {
    await tester.pumpWidget(_wrap(
      CourseCard(
        title: 'Flutter Basics',
        instructorName: 'Jane Doe',
        price: '\$49',
        onTap: () {},
      ),
    ));
    expect(find.text('Flutter Basics'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
  });

  testWidgets('CourseCard fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      CourseCard(
        title: 'X',
        instructorName: 'Y',
        price: '\$0',
        onTap: () => tapped = true,
      ),
    ));
    await tester.tap(find.byType(CourseCard));
    expect(tapped, isTrue);
  });

  testWidgets('CourseCard renders price', (tester) async {
    await tester.pumpWidget(_wrap(
      CourseCard(
        title: 'X',
        instructorName: 'Y',
        price: '\$99',
        onTap: null,
      ),
    ));
    expect(find.text('\$99'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/core/widgets/cards/course_card_test.dart
```
Expected: FAIL — CourseCard not defined.

- [ ] **Step 3: Create course_card.dart**

```dart
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.title,
    required this.instructorName,
    required this.price,
    this.imageUrl,
    this.rating,
    this.reviewCount,
    this.onTap,
  });

  final String title;
  final String instructorName;
  final String price;
  final String? imageUrl;
  final double? rating;
  final int? reviewCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(imageUrl!, fit: BoxFit.cover),
              )
            else
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ColoredBox(
                  color: cs.primaryContainer,
                  child: Icon(Icons.play_circle_outline,
                      size: 48, color: cs.onPrimaryContainer),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: tt.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppSpacing.xs),
                  Text(instructorName,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      )),
                  if (rating != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(children: [
                      const Icon(Icons.star, size: 14, color: Color(0xFFF4BF70)),
                      const SizedBox(width: 2),
                      Text('${rating!.toStringAsFixed(1)}',
                          style: tt.labelSmall),
                      if (reviewCount != null)
                        Text(' (${reviewCount})',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            )),
                    ]),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(price,
                      style: tt.titleSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run — expect PASS**

```bash
flutter test test/core/widgets/cards/course_card_test.dart
```
Expected: 3/3 pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/cards/course_card.dart test/core/widgets/cards/course_card_test.dart
git commit -m "feat(widgets): add CourseCard"
```

---

### Task 6: Feedback widgets (AppSkeleton, AppEmptyState, AppErrorState, StatusBadge, AppSnackbar, AppDialog)

**Files:**
- Create: `lib/core/widgets/feedback/app_skeleton.dart`
- Create: `lib/core/widgets/feedback/app_state_views.dart`
- Create: `lib/core/widgets/feedback/status_badge.dart`
- Create: `lib/core/widgets/feedback/app_snackbar.dart`
- Create: `lib/core/widgets/dialogs/app_dialog.dart`
- Create: `test/core/widgets/feedback/feedback_test.dart`

**Interfaces:**
- Consumes: `AppThemeExtension`, `AppSpacing`, `AppButton`
- Produces:
  - `AppSkeleton({double? width, double? height, BorderRadius? borderRadius})`
  - `AppEmptyState({required String message, String? actionLabel, VoidCallback? onAction})`
  - `AppErrorState({required String message, String? actionLabel, VoidCallback? onRetry})`
  - `enum BadgeVariant { success, warning, error, info }`; `StatusBadge({required String label, required BadgeVariant variant})`
  - `AppSnackbar.show(context, message, {SnackbarVariant variant})` static method
  - `AppDialog.show(context, {required String title, required String body, ...}) → Future<bool?>`

- [ ] **Step 1: Write failing tests**

```dart
// test/core/widgets/feedback/feedback_test.dart
import 'package:acendra/core/widgets/feedback/app_skeleton.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('AppSkeleton renders', (tester) async {
    await tester.pumpWidget(_wrap(
      const AppSkeleton(width: 100, height: 20),
    ));
    expect(find.byType(AppSkeleton), findsOneWidget);
  });

  testWidgets('AppEmptyState shows message', (tester) async {
    await tester.pumpWidget(_wrap(
      const AppEmptyState(message: 'No courses yet'),
    ));
    expect(find.text('No courses yet'), findsOneWidget);
  });

  testWidgets('AppErrorState fires onRetry', (tester) async {
    var retried = false;
    await tester.pumpWidget(_wrap(
      AppErrorState(
        message: 'Failed',
        actionLabel: 'Retry',
        onRetry: () => retried = true,
      ),
    ));
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('StatusBadge success renders', (tester) async {
    await tester.pumpWidget(_wrap(
      const StatusBadge(label: 'Active', variant: BadgeVariant.success),
    ));
    expect(find.text('Active'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/core/widgets/feedback/feedback_test.dart
```
Expected: FAIL — widgets not defined.

- [ ] **Step 3: Create app_skeleton.dart**

```dart
import 'package:flutter/material.dart';

class AppSkeleton extends StatefulWidget {
  const AppSkeleton({super.key, this.width, this.height, this.borderRadius});
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface.withAlpha(30);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base.withOpacity(_anim.value),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(6),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Create app_state_views.dart**

```dart
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: ButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onRetry,
  });
  final String message;
  final String? actionLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge),
            if (actionLabel != null && onRetry != null) ...[
              const SizedBox(height: 16),
              AppButton(
                label: actionLabel!,
                onPressed: onRetry,
                variant: ButtonVariant.outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Create status_badge.dart**

```dart
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';

enum BadgeVariant { success, warning, error, info }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.variant});
  final String label;
  final BadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    final (bg, fg) = switch (variant) {
      BadgeVariant.success => (ext.successContainer, ext.success),
      BadgeVariant.warning => (ext.warningContainer, ext.warning),
      BadgeVariant.error => (cs.errorContainer, cs.onErrorContainer),
      BadgeVariant.info => (cs.primaryContainer, cs.onPrimaryContainer),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
```

- [ ] **Step 6: Create app_snackbar.dart**

```dart
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';

enum SnackbarVariant { info, success, warning, error }

abstract final class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    SnackbarVariant variant = SnackbarVariant.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    final (bg, fg) = switch (variant) {
      SnackbarVariant.success => (ext.successContainer, ext.success),
      SnackbarVariant.warning => (ext.warningContainer, ext.warning),
      SnackbarVariant.error => (cs.errorContainer, cs.onErrorContainer),
      SnackbarVariant.info => (cs.primaryContainer, cs.onPrimaryContainer),
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: fg)),
        backgroundColor: bg,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
```

- [ ] **Step 7: Create app_dialog.dart**

```dart
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';

abstract final class AppDialog {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String body,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    ButtonVariant confirmVariant = ButtonVariant.primary,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          AppButton(
            label: cancelLabel,
            onPressed: () => Navigator.of(ctx).pop(false),
            variant: ButtonVariant.outlined,
            size: ButtonSize.small,
          ),
          AppButton(
            label: confirmLabel,
            onPressed: () => Navigator.of(ctx).pop(true),
            variant: confirmVariant,
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 8: Run — expect PASS**

```bash
flutter test test/core/widgets/feedback/feedback_test.dart
```
Expected: 4/4 pass.

- [ ] **Step 9: Commit**

```bash
git add lib/core/widgets/feedback/ lib/core/widgets/dialogs/ test/core/widgets/feedback/
git commit -m "feat(widgets): add AppSkeleton, AppEmptyState, AppErrorState, StatusBadge, AppSnackbar, AppDialog"
```

---

### Task 7: Navigation shells (PublicShell, AuthShell, StudentShell, LearningShell, AdminShell)

**Files:**
- Create: `lib/core/widgets/navigation/public_shell.dart`
- Create: `lib/core/widgets/navigation/auth_shell.dart`
- Create: `lib/core/widgets/navigation/student_shell.dart`
- Create: `lib/core/widgets/navigation/learning_shell.dart`
- Create: `lib/core/widgets/navigation/admin_shell.dart`
- Create: `test/core/widgets/navigation/shells_test.dart`

**Interfaces:**
- Consumes: `AppBreakpoints`, `ResponsiveContainer`
- Produces:
  - `PublicShell({required Widget child})` — top nav bar + footer, `ResponsiveContainer` content
  - `AuthShell({required Widget child})` — centred card layout, no nav
  - `StudentShell({required Widget child})` — top nav with dashboard links
  - `LearningShell({required Widget child})` — full-width, minimal chrome
  - `AdminShell({required Widget child})` — fixed 248 px left sidebar + content area

- [ ] **Step 1: Write failing tests**

```dart
// test/core/widgets/navigation/shells_test.dart
import 'package:acendra/core/widgets/navigation/public_shell.dart';
import 'package:acendra/core/widgets/navigation/auth_shell.dart';
import 'package:acendra/core/widgets/navigation/student_shell.dart';
import 'package:acendra/core/widgets/navigation/learning_shell.dart';
import 'package:acendra/core/widgets/navigation/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: child);

void main() {
  testWidgets('PublicShell renders child', (tester) async {
    await tester.pumpWidget(_wrap(
      const PublicShell(child: Text('content')),
    ));
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('AuthShell renders child', (tester) async {
    await tester.pumpWidget(_wrap(
      const AuthShell(child: Text('login form')),
    ));
    expect(find.text('login form'), findsOneWidget);
  });

  testWidgets('StudentShell renders child', (tester) async {
    await tester.pumpWidget(_wrap(
      const StudentShell(child: Text('dashboard')),
    ));
    expect(find.text('dashboard'), findsOneWidget);
  });

  testWidgets('LearningShell renders child', (tester) async {
    await tester.pumpWidget(_wrap(
      const LearningShell(child: Text('lesson')),
    ));
    expect(find.text('lesson'), findsOneWidget);
  });

  testWidgets('AdminShell renders child', (tester) async {
    await tester.pumpWidget(_wrap(
      const AdminShell(child: Text('admin panel')),
    ));
    expect(find.text('admin panel'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/core/widgets/navigation/shells_test.dart
```
Expected: FAIL — shells not defined.

- [ ] **Step 3: Create public_shell.dart**

```dart
import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/core/widgets/layout/responsive_container.dart';
import 'package:flutter/material.dart';

class PublicShell extends StatelessWidget {
  const PublicShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acedra'),
        actions: const [],
      ),
      body: ResponsiveContainer(child: child),
    );
  }
}
```

- [ ] **Step 4: Create auth_shell.dart**

```dart
import 'package:flutter/material.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Create student_shell.dart**

```dart
import 'package:acendra/core/widgets/layout/responsive_container.dart';
import 'package:flutter/material.dart';

class StudentShell extends StatelessWidget {
  const StudentShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acedra')),
      body: ResponsiveContainer(child: child),
    );
  }
}
```

- [ ] **Step 6: Create learning_shell.dart**

```dart
import 'package:flutter/material.dart';

class LearningShell extends StatelessWidget {
  const LearningShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning')),
      body: child,
    );
  }
}
```

- [ ] **Step 7: Create admin_shell.dart**

```dart
import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: AppBreakpoints.adminSidebarWidth,
            child: ColoredBox(
              color: ext.surfaceSecondary,
              child: const Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Admin',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
```

- [ ] **Step 8: Run — expect PASS**

```bash
flutter test test/core/widgets/navigation/shells_test.dart
```
Expected: 5/5 pass.

- [ ] **Step 9: Commit**

```bash
git add lib/core/widgets/navigation/ test/core/widgets/navigation/
git commit -m "feat(navigation): add PublicShell, AuthShell, StudentShell, LearningShell, AdminShell"
```

---

### Task 8: Router wiring — ShellRoutes + final verification

**Files:**
- Modify: `lib/app/router/app_router.dart` (restructure to ShellRoutes)
- Modify: `test/app/router/app_router_test.dart` (update tests if needed)

**Interfaces:**
- Consumes: all 5 shells from Task 7, `RouteNames`
- Produces: `appRouterProvider` with `ShellRoute` wrappers: public routes in `PublicShell`, auth routes in `AuthShell`, student routes in `StudentShell`, learning routes in `LearningShell`, admin routes in `AdminShell`

- [ ] **Step 1: Update router tests**

```dart
// test/app/router/app_router_test.dart — verify existing 5 tests still pass after rewrite
// Run before modifying the router to confirm baseline
```

- [ ] **Step 2: Run baseline — expect PASS**

```bash
flutter test test/app/router/app_router_test.dart
```
Expected: 5/5 pass (baseline).

- [ ] **Step 3: Rewrite app_router.dart with ShellRoutes**

```dart
import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/core/widgets/navigation/admin_shell.dart';
import 'package:acendra/core/widgets/navigation/auth_shell.dart';
import 'package:acendra/core/widgets/navigation/learning_shell.dart';
import 'package:acendra/core/widgets/navigation/public_shell.dart';
import 'package:acendra/core/widgets/navigation/student_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.marketplace,
    debugLogDiagnostics: false,
    routes: [
      // Public routes — wrapped in PublicShell
      ShellRoute(
        builder: (context, state, child) => PublicShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            redirect: (_, __) => RouteNames.marketplace,
          ),
          GoRoute(
            path: RouteNames.marketplace,
            builder: (_, __) =>
                const _PlaceholderScreen(title: 'Marketplace'),
          ),
        ],
      ),

      // Auth routes — wrapped in AuthShell
      ShellRoute(
        builder: (context, state, child) => AuthShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.login,
            builder: (_, __) => const _PlaceholderScreen(title: 'Login'),
          ),
          GoRoute(
            path: RouteNames.register,
            builder: (_, __) => const _PlaceholderScreen(title: 'Register'),
          ),
          GoRoute(
            path: RouteNames.verifyEmail,
            builder: (_, __) =>
                const _PlaceholderScreen(title: 'Verify Email'),
          ),
          GoRoute(
            path: RouteNames.forgotPassword,
            builder: (_, __) =>
                const _PlaceholderScreen(title: 'Forgot Password'),
          ),
          GoRoute(
            path: RouteNames.resetPassword,
            builder: (_, __) =>
                const _PlaceholderScreen(title: 'Reset Password'),
          ),
        ],
      ),

      // Student routes — wrapped in StudentShell
      ShellRoute(
        builder: (context, state, child) => StudentShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.dashboard,
            builder: (_, __) =>
                const _PlaceholderScreen(title: 'Dashboard'),
          ),
          GoRoute(
            path: RouteNames.myCourses,
            builder: (_, __) =>
                const _PlaceholderScreen(title: 'My Courses'),
          ),
        ],
      ),

      // Learning routes — wrapped in LearningShell
      ShellRoute(
        builder: (context, state, child) => LearningShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.learn,
            builder: (_, __) =>
                const _PlaceholderScreen(title: 'Learn'),
          ),
        ],
      ),

      // Admin routes — wrapped in AdminShell
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.admin,
            builder: (_, __) => const _PlaceholderScreen(title: 'Admin'),
          ),
        ],
      ),

      // Standalone routes (no shell)
      GoRoute(
        path: RouteNames.courseDetail,
        builder: (_, state) => _PlaceholderScreen(
          title: 'Course ${state.pathParameters['courseId']}',
        ),
      ),
      GoRoute(
        path: RouteNames.checkout,
        builder: (_, state) => _PlaceholderScreen(
          title: 'Checkout ${state.pathParameters['courseId']}',
        ),
      ),
    ],
  );
});
```

- [ ] **Step 4: Run router tests**

```bash
flutter test test/app/router/app_router_test.dart
```
Expected: 5/5 pass.

- [ ] **Step 5: Run full test suite**

```bash
flutter test
```
Expected: all pass.

- [ ] **Step 6: Run analyzer + format check**

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
```
Expected: both exit 0.

- [ ] **Step 7: Build web**

```bash
flutter build web --release
```
Expected: exit 0, `build/web` created.

- [ ] **Step 8: Commit**

```bash
git add lib/app/router/app_router.dart test/app/router/app_router_test.dart
git commit -m "feat(router): wire ShellRoutes for all navigation shells"
```

---

## Post-implementation checklist

- [ ] `dart format --output=none --set-exit-if-changed .` → exit 0
- [ ] `flutter analyze` → exit 0
- [ ] `flutter test` → all pass
- [ ] `flutter build web --release` → exit 0
- [ ] No secrets committed
- [ ] PR opened against `main` from branch `feat/phase2-design-system`
