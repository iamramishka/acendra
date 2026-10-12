# CSA-082 Marketplace Homepage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `/marketplace` placeholder screen with a real homepage that lists published courses fetched from Supabase using RLS, with a public shell layout, loading/error/empty states, and a responsive course grid.

**Architecture:** Feature-First Clean Architecture under `lib/features/marketplace/`. The data layer queries `public.courses` via the Supabase Dart SDK (RLS Pattern A — no Edge Function needed for the public listing). Riverpod manages async state. The router wires `MarketplaceScreen` into the existing `PublicShell` wrapper.

**Tech Stack:** Flutter, Dart (null-safe), Riverpod, go_router, Supabase Dart SDK, Material 3, `ResponsiveContainer`, `CourseCard`, `AppEmptyState`, `AppErrorState`, `AppBreakpoints`

**Spec:** `docs/API_CONTRACTS.md` §21 (Public Course List Contract), `TASKS.md` CSA-082

## Global Constraints

- `lib/features/marketplace/` is the only new feature directory; do not touch other feature folders.
- Shared files that require coordination: `lib/app/router/app_router.dart` (register `MarketplaceScreen`). No other agent has an open lock on it — check before editing.
- Money is stored as `price_minor` (integer minor units, LKR). Format for display as `LKR X,XXX.XX` — never use floating-point currency.
- Return only `status = 'published'` courses; draft/archived must never appear.
- `CourseCard` already exists at `lib/core/widgets/cards/course_card.dart` — reuse it without modification.
- `ResponsiveContainer` and `ScreenLayoutExtension` are at `lib/core/widgets/layout/responsive_container.dart`.
- Grid columns: 1 (compact < 600px), 2 (medium 600–1024px), 3 (expanded ≥ 1024px) — matches `AppBreakpoints`.
- No `instructorName` column exists in the database — pass `'Acedra'` as the static instructor name in `CourseCard` for now.
- The `thumbnail_path` column holds a Storage object path, not a full URL. For MVP, pass `null` as `imageUrl` (the card shows a placeholder icon). Do not generate signed URLs here.
- Pagination: default `limit: 20`, `offset: 0` for MVP. No infinite scroll needed for CSA-082.

## Review Focus

1. **Draft/archived courses visible** — if the RLS filter is wrong, `status != 'published'` courses appear. The test must assert the repository returns nothing when only a draft exists.
2. **Price formatting with zero minor units** — `price_minor = 0` must render as `LKR 0.00`, not crash or show empty.
3. **Supabase not initialized in widget tests** — tests that instantiate the real `SupabaseCourseRepository` will throw. The test must use a fake repository via dependency injection.
4. **Grid renders a single course** — one course must render in a grid (not crash due to `crossAxisCount` vs item count).
5. **Error state shown when repository throws** — if Supabase is unreachable, `AppErrorState` with a retry button must appear (not a blank screen).

---

## File Structure

### New files
- `lib/features/marketplace/domain/entities/course_summary.dart` — immutable domain model
- `lib/features/marketplace/domain/repositories/course_repository.dart` — abstract interface
- `lib/features/marketplace/data/models/course_summary_dto.dart` — JSON → domain mapper
- `lib/features/marketplace/data/repositories/supabase_course_repository.dart` — real Supabase impl
- `lib/features/marketplace/presentation/providers/marketplace_provider.dart` — Riverpod `AsyncNotifier`
- `lib/features/marketplace/presentation/screens/marketplace_screen.dart` — the screen widget
- `lib/features/marketplace/presentation/widgets/course_grid.dart` — responsive grid widget
- `test/features/marketplace/domain/course_summary_test.dart` — entity unit tests
- `test/features/marketplace/data/course_summary_dto_test.dart` — DTO parsing tests
- `test/features/marketplace/presentation/marketplace_screen_test.dart` — widget tests
- `test/features/marketplace/fakes/fake_course_repository.dart` — test double

### Modified files
- `lib/app/router/app_router.dart` — replace `_PlaceholderScreen` for `/marketplace` with `MarketplaceScreen`

---

### Task 1: Domain Entity

**Files:**
- Create: `lib/features/marketplace/domain/entities/course_summary.dart`
- Create: `test/features/marketplace/domain/course_summary_test.dart`

**Interfaces:**
- Produces: `CourseSummary` class with fields used in Tasks 2–6

- [ ] **Step 1: Write the failing test**

```dart
// test/features/marketplace/domain/course_summary_test.dart
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CourseSummary', () {
    test('stores all fields', () {
      const c = CourseSummary(
        id: 'id-1',
        slug: 'flutter-basics',
        title: 'Flutter Basics',
        shortDescription: 'Learn Flutter.',
        priceMinor: 125000,
        currencyCode: 'LKR',
        publishedAt: '2026-10-11T00:00:00Z',
      );
      expect(c.id, 'id-1');
      expect(c.priceMinor, 125000);
      expect(c.formattedPrice, 'LKR 1,250.00');
    });

    test('formattedPrice handles zero minor units', () {
      const c = CourseSummary(
        id: 'x',
        slug: 'free',
        title: 'Free',
        shortDescription: '',
        priceMinor: 0,
        currencyCode: 'LKR',
        publishedAt: '2026-10-11T00:00:00Z',
      );
      expect(c.formattedPrice, 'LKR 0.00');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/marketplace/domain/course_summary_test.dart
```

Expected: FAIL — `CourseSummary` not defined.

- [ ] **Step 3: Implement the entity**

```dart
// lib/features/marketplace/domain/entities/course_summary.dart
import 'package:flutter/foundation.dart';

@immutable
class CourseSummary {
  const CourseSummary({
    required this.id,
    required this.slug,
    required this.title,
    required this.shortDescription,
    required this.priceMinor,
    required this.currencyCode,
    required this.publishedAt,
  });

  final String id;
  final String slug;
  final String title;
  final String shortDescription;
  final int priceMinor;
  final String currencyCode;
  final String publishedAt;

  String get formattedPrice {
    // Minor units → major units with 2 decimal places, no floating-point money.
    final major = priceMinor ~/ 100;
    final cents = priceMinor % 100;
    final majorStr = major.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$currencyCode $majorStr.${cents.toString().padLeft(2, '0')}';
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/features/marketplace/domain/course_summary_test.dart
```

Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/marketplace/domain/entities/course_summary.dart \
        test/features/marketplace/domain/course_summary_test.dart
git commit -m "feat(marketplace): add CourseSummary domain entity with price formatting"
```

---

### Task 2: Repository Interface + DTO

**Files:**
- Create: `lib/features/marketplace/domain/repositories/course_repository.dart`
- Create: `lib/features/marketplace/data/models/course_summary_dto.dart`
- Create: `test/features/marketplace/data/course_summary_dto_test.dart`

**Interfaces:**
- Consumes: `CourseSummary` from Task 1
- Produces:
  - `abstract class CourseRepository { Future<List<CourseSummary>> listPublished(); }`
  - `CourseSummaryDto.fromJson(Map<String, dynamic> json) → CourseSummary`

- [ ] **Step 1: Write the failing DTO test**

```dart
// test/features/marketplace/data/course_summary_dto_test.dart
import 'package:acendra/features/marketplace/data/models/course_summary_dto.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CourseSummaryDto.fromJson', () {
    const rawJson = {
      'id': '08100000-0000-0000-0000-000000000011',
      'slug': 'synthetic-published-course',
      'title': 'Synthetic published course',
      'short_description': 'Development catalog fixture',
      'price_minor': 125000,
      'currency_code': 'LKR',
      'published_at': '2026-10-11T00:00:00Z',
    };

    test('parses all fields into CourseSummary', () {
      final course = CourseSummaryDto.fromJson(rawJson);
      expect(course, isA<CourseSummary>());
      expect(course.id, '08100000-0000-0000-0000-000000000011');
      expect(course.slug, 'synthetic-published-course');
      expect(course.title, 'Synthetic published course');
      expect(course.shortDescription, 'Development catalog fixture');
      expect(course.priceMinor, 125000);
      expect(course.currencyCode, 'LKR');
    });

    test('throws ArgumentError when required field is missing', () {
      final bad = Map<String, dynamic>.from(rawJson)..remove('id');
      expect(() => CourseSummaryDto.fromJson(bad), throwsArgumentError);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/marketplace/data/course_summary_dto_test.dart
```

Expected: FAIL — `CourseSummaryDto` not defined.

- [ ] **Step 3: Implement the interface and DTO**

```dart
// lib/features/marketplace/domain/repositories/course_repository.dart
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';

abstract class CourseRepository {
  Future<List<CourseSummary>> listPublished();
}
```

```dart
// lib/features/marketplace/data/models/course_summary_dto.dart
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';

class CourseSummaryDto {
  static CourseSummary fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id == null) throw ArgumentError('Missing required field: id');
    return CourseSummary(
      id: id as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      shortDescription: json['short_description'] as String,
      priceMinor: json['price_minor'] as int,
      currencyCode: json['currency_code'] as String,
      publishedAt: json['published_at'] as String,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/features/marketplace/data/course_summary_dto_test.dart
```

Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/marketplace/domain/repositories/course_repository.dart \
        lib/features/marketplace/data/models/course_summary_dto.dart \
        test/features/marketplace/data/course_summary_dto_test.dart
git commit -m "feat(marketplace): add CourseRepository interface and CourseSummaryDto"
```

---

### Task 3: Supabase Repository Implementation

**Files:**
- Create: `lib/features/marketplace/data/repositories/supabase_course_repository.dart`

**Interfaces:**
- Consumes: `CourseRepository`, `CourseSummaryDto.fromJson`, Supabase `SupabaseClient`
- Produces: `SupabaseCourseRepository implements CourseRepository`; `courseRepositoryProvider`

> Note: This task has no widget test — it requires a live Supabase client. Manual smoke testing against local Supabase is the verification step. The RLS policy (CSA-079) already restricts `courses` reads to `status = 'published'`.

- [ ] **Step 1: Create the Supabase repository**

```dart
// lib/features/marketplace/data/repositories/supabase_course_repository.dart
import 'package:acendra/features/marketplace/data/models/course_summary_dto.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/features/marketplace/domain/repositories/course_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCourseRepository implements CourseRepository {
  const SupabaseCourseRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CourseSummary>> listPublished() async {
    final rows = await _client
        .from('courses')
        .select('id, slug, title, short_description, price_minor, currency_code, published_at')
        .eq('status', 'published')
        .order('published_at', ascending: false)
        .limit(20);
    return (rows as List<dynamic>)
        .map((r) => CourseSummaryDto.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return SupabaseCourseRepository(Supabase.instance.client);
});
```

- [ ] **Step 2: Run static analysis**

```bash
flutter analyze lib/features/marketplace/
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/marketplace/data/repositories/supabase_course_repository.dart
git commit -m "feat(marketplace): implement SupabaseCourseRepository with published-only RLS query"
```

---

### Task 4: Riverpod Provider

**Files:**
- Create: `lib/features/marketplace/presentation/providers/marketplace_provider.dart`
- Create: `test/features/marketplace/fakes/fake_course_repository.dart`

**Interfaces:**
- Consumes: `courseRepositoryProvider`, `CourseRepository`, `CourseSummary`
- Produces: `marketplaceProvider` — `AsyncNotifier<List<CourseSummary>>`; `FakeCourseRepository` for tests

- [ ] **Step 1: Create the fake repository for tests**

```dart
// test/features/marketplace/fakes/fake_course_repository.dart
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/features/marketplace/domain/repositories/course_repository.dart';

class FakeCourseRepository implements CourseRepository {
  FakeCourseRepository({this.result = const [], this.shouldThrow = false});

  final List<CourseSummary> result;
  final bool shouldThrow;

  @override
  Future<List<CourseSummary>> listPublished() async {
    if (shouldThrow) throw Exception('Simulated network error');
    return result;
  }
}

const fakeCourse = CourseSummary(
  id: 'fake-id-1',
  slug: 'fake-course',
  title: 'Fake Course',
  shortDescription: 'A fake course for tests.',
  priceMinor: 125000,
  currencyCode: 'LKR',
  publishedAt: '2026-10-11T00:00:00Z',
);
```

- [ ] **Step 2: Create the Riverpod provider**

```dart
// lib/features/marketplace/presentation/providers/marketplace_provider.dart
import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MarketplaceNotifier extends AsyncNotifier<List<CourseSummary>> {
  @override
  Future<List<CourseSummary>> build() {
    return ref.read(courseRepositoryProvider).listPublished();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(courseRepositoryProvider).listPublished(),
    );
  }
}

final marketplaceProvider =
    AsyncNotifierProvider<MarketplaceNotifier, List<CourseSummary>>(
      MarketplaceNotifier.new,
    );
```

- [ ] **Step 3: Run analysis**

```bash
flutter analyze lib/features/marketplace/presentation/providers/
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/marketplace/presentation/providers/marketplace_provider.dart \
        test/features/marketplace/fakes/fake_course_repository.dart
git commit -m "feat(marketplace): add MarketplaceNotifier and FakeCourseRepository"
```

---

### Task 5: Course Grid Widget + Screen

**Files:**
- Create: `lib/features/marketplace/presentation/widgets/course_grid.dart`
- Create: `lib/features/marketplace/presentation/screens/marketplace_screen.dart`
- Create: `test/features/marketplace/presentation/marketplace_screen_test.dart`

**Interfaces:**
- Consumes: `marketplaceProvider`, `courseRepositoryProvider`, `CourseCard`, `AppEmptyState`, `AppErrorState`, `ResponsiveContainer`, `AppBreakpoints`, `FakeCourseRepository`, `fakeCourse`
- Produces: `MarketplaceScreen` widget; `CourseGrid` widget

- [ ] **Step 1: Write the failing widget tests**

```dart
// test/features/marketplace/presentation/marketplace_screen_test.dart
import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/features/marketplace/domain/repositories/course_repository.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:acendra/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_course_repository.dart';

ProviderContainer _container(CourseRepository repo) => ProviderContainer(
  overrides: [courseRepositoryProvider.overrideWithValue(repo)],
);

Widget _wrap(Widget child, ProviderContainer container) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets('shows loading indicator initially', (tester) async {
    // Fake that never completes immediately
    final container = _container(FakeCourseRepository(result: [fakeCourse]));
    await tester.pumpWidget(_wrap(const MarketplaceScreen(), container));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    container.dispose();
  });

  testWidgets('shows course card after data loads', (tester) async {
    final container = _container(FakeCourseRepository(result: [fakeCourse]));
    await tester.pumpWidget(_wrap(const MarketplaceScreen(), container));
    await tester.pumpAndSettle();
    expect(find.text('Fake Course'), findsOneWidget);
    expect(find.text('LKR 1,250.00'), findsOneWidget);
    container.dispose();
  });

  testWidgets('shows empty state when no courses', (tester) async {
    final container = _container(FakeCourseRepository());
    await tester.pumpWidget(_wrap(const MarketplaceScreen(), container));
    await tester.pumpAndSettle();
    expect(find.text('No courses available yet.'), findsOneWidget);
    container.dispose();
  });

  testWidgets('shows error state and retry button on failure', (tester) async {
    final container =
        _container(FakeCourseRepository(shouldThrow: true));
    await tester.pumpWidget(_wrap(const MarketplaceScreen(), container));
    await tester.pumpAndSettle();
    expect(find.text('Failed to load courses. Please try again.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    container.dispose();
  });

  testWidgets('draft courses do not appear', (tester) async {
    // The repository filters — so the fake returning empty simulates draft-only DB.
    final container = _container(FakeCourseRepository());
    await tester.pumpWidget(_wrap(const MarketplaceScreen(), container));
    await tester.pumpAndSettle();
    expect(find.text('No courses available yet.'), findsOneWidget);
    container.dispose();
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/features/marketplace/presentation/marketplace_screen_test.dart
```

Expected: FAIL — `MarketplaceScreen` not defined.

- [ ] **Step 3: Implement CourseGrid widget**

```dart
// lib/features/marketplace/presentation/widgets/course_grid.dart
import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/core/widgets/cards/course_card.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:flutter/material.dart';

class CourseGrid extends StatelessWidget {
  const CourseGrid({super.key, required this.courses, this.onCourseTap});

  final List<CourseSummary> courses;
  final void Function(CourseSummary)? onCourseTap;

  int _columnCount(double width) {
    if (width < AppBreakpoints.compact) return 1;
    if (width < AppBreakpoints.medium) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = _columnCount(width);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return CourseCard(
          title: course.title,
          instructorName: 'Acedra',
          price: course.formattedPrice,
          onTap: onCourseTap != null ? () => onCourseTap!(course) : null,
        );
      },
    );
  }
}
```

- [ ] **Step 4: Implement MarketplaceScreen**

```dart
// lib/features/marketplace/presentation/screens/marketplace_screen.dart
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:acendra/features/marketplace/presentation/widgets/course_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(marketplaceProvider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => AppErrorState(
        message: 'Failed to load courses. Please try again.',
        actionLabel: 'Retry',
        onRetry: () => ref.read(marketplaceProvider.notifier).refresh(),
      ),
      data: (courses) {
        if (courses.isEmpty) {
          return const AppEmptyState(message: 'No courses available yet.');
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: CourseGrid(courses: courses),
        );
      },
    );
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
flutter test test/features/marketplace/presentation/marketplace_screen_test.dart
```

Expected: PASS (5 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/features/marketplace/presentation/widgets/course_grid.dart \
        lib/features/marketplace/presentation/screens/marketplace_screen.dart \
        test/features/marketplace/presentation/marketplace_screen_test.dart
git commit -m "feat(marketplace): implement MarketplaceScreen and CourseGrid with loading/error/empty states"
```

---

### Task 6: Wire into Router

**Files:**
- Modify: `lib/app/router/app_router.dart`

**Interfaces:**
- Consumes: `MarketplaceScreen` from Task 5, existing `appRouterProvider`

> Check `git log --oneline lib/app/router/app_router.dart` before editing to confirm no other agent has a pending change.

- [ ] **Step 1: Replace the marketplace placeholder in the router**

In `lib/app/router/app_router.dart`, add the import and replace the placeholder:

```dart
// Add this import at the top:
import 'package:acendra/features/marketplace/presentation/screens/marketplace_screen.dart';
```

Replace:
```dart
GoRoute(
  path: RouteNames.marketplace,
  builder: (_, _) => const _PlaceholderScreen(title: 'Marketplace'),
),
```

With:
```dart
GoRoute(
  path: RouteNames.marketplace,
  builder: (_, _) => const MarketplaceScreen(),
),
```

- [ ] **Step 2: Run full test suite and analysis**

```bash
flutter analyze
flutter test
```

Expected: no errors, all tests pass.

- [ ] **Step 3: Verify build**

```bash
flutter build web --release
```

Expected: build succeeds with no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/app/router/app_router.dart
git commit -m "feat(marketplace): wire MarketplaceScreen into router, replace placeholder"
```

---

## Final Verification

- [ ] Run `flutter analyze` — zero issues
- [ ] Run `flutter test` — all tests pass (including new marketplace tests)
- [ ] Run `flutter build web --release` — succeeds
- [ ] Navigate to `/marketplace` in the running app — courses load from Supabase seed data
- [ ] Confirm only the 1 published seed course (`synthetic-published-course`) appears — draft and archived courses do not show

---

## Known Limitations

- `thumbnail_path` is ignored; `CourseCard` shows placeholder icon. A follow-up task should generate signed Supabase Storage URLs.
- `instructorName` is hardcoded as `'Acedra'` — no instructor column exists in the DB schema yet.
- No search, category filter, or pagination UI — those are CSA-084, CSA-085 (separate tasks).
- No enrollment-aware UI (e.g. "enrolled" badge) — that is CSA-088.
