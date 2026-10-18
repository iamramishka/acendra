import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:acendra/features/marketplace/presentation/widgets/category_filter.dart';
import 'package:acendra/features/marketplace/presentation/widgets/course_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key, this.focusSearch = false});

  final bool focusSearch;

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _searchFocus = FocusNode();
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
  }

  @override
  void didUpdateWidget(MarketplaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusSearch && !oldWidget.focusSearch) {
      _searchFocus.requestFocus();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(searchQueryProvider, (_, query) {
      if (_searchController.text != query) {
        _searchController.value = TextEditingValue(
          text: query,
          selection: TextSelection.collapsed(offset: query.length),
        );
      }
    });
    ref.listen(marketplaceSearchRequestProvider, (_, _) {
      _searchFocus.requestFocus();
    });
    final rawState = ref.watch(marketplaceProvider);
    final filtered = ref.watch(filteredCoursesProvider);
    final categories = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return rawState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => AppErrorState(
        message: 'Failed to load courses. Please try again.',
        actionLabel: 'Retry',
        onRetry: () => ref.read(marketplaceProvider.notifier).refresh(),
      ),
      data: (_) {
        final courses = filtered.asData?.value ?? [];
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SearchBar(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  autoFocus: widget.focusSearch,
                  hintText: 'Search courses…',
                  leading: const Icon(Icons.search),
                  onChanged: (q) =>
                      ref.read(searchQueryProvider.notifier).state = q,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: categories.when(
                data: (cats) => CategoryFilter(
                  categories: cats,
                  selectedId: selectedCategory,
                  onSelected: (id) =>
                      ref.read(selectedCategoryProvider.notifier).state = id,
                ),
                loading: () => const SizedBox.shrink(),
                error: (err, _) => const SizedBox.shrink(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            if (courses.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: AppEmptyState(message: 'No courses available yet.'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: CourseGrid(
                    courses: courses,
                    onCourseTap: (course) => context.go(
                      RouteNames.courseDetail.replaceFirst(
                        ':courseId',
                        Uri.encodeComponent(course.id),
                      ),
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}
