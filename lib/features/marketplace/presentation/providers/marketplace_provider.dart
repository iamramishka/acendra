import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/marketplace/domain/entities/category.dart';
import 'package:acendra/features/marketplace/domain/entities/course_detail.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

// ── Search query ──────────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

/// A focus request, separate from the actual search query/filter state.
final marketplaceSearchRequestProvider = StateProvider<int>((ref) => 0);

// ── Selected category ─────────────────────────────────────────────────────────

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

enum CourseSort { newest, priceLow, priceHigh }

final courseSortProvider = StateProvider<CourseSort>(
  (ref) => CourseSort.newest,
);

// ── All published courses (raw) ───────────────────────────────────────────────

class MarketplaceNotifier extends AsyncNotifier<List<CourseSummary>> {
  @override
  Future<List<CourseSummary>> build() =>
      ref.read(courseRepositoryProvider).listPublished();

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

// ── Filtered course list (CSA-084 + CSA-085) ──────────────────────────────────

final filteredCoursesProvider = Provider<AsyncValue<List<CourseSummary>>>((
  ref,
) {
  final all = ref.watch(marketplaceProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final categoryId = ref.watch(selectedCategoryProvider);
  final sort = ref.watch(courseSortProvider);

  return all.whenData((courses) {
    var list = courses;
    if (query.isNotEmpty) {
      list = list
          .where(
            (c) =>
                c.title.toLowerCase().contains(query) ||
                c.shortDescription.toLowerCase().contains(query),
          )
          .toList();
    }
    if (categoryId != null) {
      list = list.where((c) => c.categoryId == categoryId).toList();
    }
    final sorted = [...list];
    sorted.sort((a, b) {
      final order = switch (sort) {
        CourseSort.newest => b.publishedAt.compareTo(a.publishedAt),
        CourseSort.priceLow => a.priceMinor.compareTo(b.priceMinor),
        CourseSort.priceHigh => b.priceMinor.compareTo(a.priceMinor),
      };
      return order == 0 ? a.id.compareTo(b.id) : order;
    });
    return sorted;
  });
});

// ── Categories (CSA-085) ──────────────────────────────────────────────────────

final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.read(courseRepositoryProvider).listCategories(),
);

// ── Course detail (CSA-086 + CSA-087) ─────────────────────────────────────────

final courseDetailProvider = FutureProvider.family<CourseDetail, String>(
  (ref, courseId) =>
      ref.read(courseRepositoryProvider).getCourseDetail(courseId),
);

// ── Enrollment status (CSA-088) ───────────────────────────────────────────────

final isEnrolledProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  courseId,
) {
  ref.watch(currentSessionProvider.select((session) => session?.user.id));
  return ref.read(courseRepositoryProvider).isEnrolled(courseId);
});
