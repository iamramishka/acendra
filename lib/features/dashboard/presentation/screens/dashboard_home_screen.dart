import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/features/dashboard/domain/entities/dashboard_category.dart';
import 'package:acendra/features/dashboard/presentation/dashboard_copy.dart';
import 'package:acendra/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:acendra/features/dashboard/presentation/providers/student_home_provider.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_category_row.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_featured_courses_grid.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_hero_carousel.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_personal_section.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_why_learn_section.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// StudentShell supplies the existing brand/avatar and four-tab navigation.
class DashboardHomeScreen extends ConsumerWidget {
  const DashboardHomeScreen({
    super.key,
    this.onBrowseCourses,
    this.onCategorySelected,
    this.onCourseSelected,
  });
  final VoidCallback? onBrowseCourses;
  final ValueChanged<DashboardCategory>? onCategorySelected;
  final ValueChanged<CourseSummary>? onCourseSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void browse() => onBrowseCourses != null
        ? onBrowseCourses!()
        : context.go(RouteNames.marketplace);
    void retryDiscovery() {
      ref.invalidate(categoriesProvider);
      ref.invalidate(marketplaceProvider);
      ref.invalidate(heroSlidesProvider);
      ref.invalidate(dashboardCategoriesProvider);
      ref.invalidate(featuredCoursesProvider);
      ref.invalidate(whyLearnItemsProvider);
      ref.invalidate(dashboardHomeProvider);
    }

    final discovery = ref.watch(dashboardHomeProvider);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentHomeProvider);
          retryDiscovery();
          await Future.wait<Object?>([
            ref
                .read(studentHomeProvider.future)
                .then<Object?>(
                  (_) => null,
                  onError: (Object _, StackTrace stack) => null,
                ),
            ref
                .read(dashboardHomeProvider.future)
                .then<Object?>(
                  (_) => null,
                  onError: (Object _, StackTrace stack) => null,
                ),
          ]);
        },
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            key: const PageStorageKey('dashboard-home-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.maxContentWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.all(
                    constraints.maxWidth < AppBreakpoints.compact ? 16 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DashboardPersonalSection(onExplore: browse),
                      discovery.when(
                        skipLoadingOnReload: false,
                        skipLoadingOnRefresh: false,
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: CircularProgressIndicator(
                              semanticsLabel: DashboardCopy.loading,
                            ),
                          ),
                        ),
                        error: (_, _) => AppErrorState(
                          message: DashboardCopy.loadError,
                          actionLabel: DashboardCopy.retry,
                          onRetry: retryDiscovery,
                        ),
                        data: (data) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DashboardHeroCarousel(
                              slides: data.slides,
                              onAction: (_) => browse(),
                            ),
                            const SizedBox(height: 32),
                            DashboardCategoryRow(
                              categories: data.categories,
                              onViewAll: browse,
                              onCategorySelected:
                                  onCategorySelected ??
                                  (category) {
                                    ref
                                        .read(selectedCategoryProvider.notifier)
                                        .state = category
                                        .id;
                                    browse();
                                  },
                            ),
                            const SizedBox(height: 32),
                            DashboardFeaturedCoursesGrid(
                              courses: data.courses,
                              categoryNames: {
                                for (final category in data.categories)
                                  category.id: category.name,
                              },
                              onViewAll: browse,
                              onCourseSelected:
                                  onCourseSelected ??
                                  (course) =>
                                      context.go('/marketplace/${course.id}'),
                            ),
                            const SizedBox(height: 32),
                            DashboardWhyLearnSection(items: data.highlights),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
