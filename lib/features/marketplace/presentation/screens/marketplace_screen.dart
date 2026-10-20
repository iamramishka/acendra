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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore Courses',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      'Discover skills worth mastering.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Material(
                  type: MaterialType.transparency,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          courses.length == 1
                              ? '1 Course'
                              : '${courses.length} Courses',
                        ),
                      ),
                      DropdownButton<CourseSort>(
                        value: ref.watch(courseSortProvider),
                        underline: const SizedBox.shrink(),
                        onChanged: (s) {
                          if (s != null) {
                            ref.read(courseSortProvider.notifier).state = s;
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: CourseSort.newest,
                            child: Text('Newest'),
                          ),
                          DropdownMenuItem(
                            value: CourseSort.priceLow,
                            child: Text('Price: low to high'),
                          ),
                          DropdownMenuItem(
                            value: CourseSort.priceHigh,
                            child: Text('Price: high to low'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            if (courses.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: AppEmptyState(
                    message: (rawState.asData?.value.isEmpty ?? true)
                        ? 'No courses available yet.'
                        : 'No courses found. Try a different word or category.',
                  ),
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
