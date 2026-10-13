import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/features/marketplace/domain/entities/category.dart';
import 'package:acendra/features/marketplace/domain/entities/course_detail.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

// ── Search query ──────────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

// ── Selected category ─────────────────────────────────────────────────────────

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

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
    return list;
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

final isEnrolledProvider = FutureProvider.family<bool, String>(
  (ref, courseId) => ref.read(courseRepositoryProvider).isEnrolled(courseId),
);
