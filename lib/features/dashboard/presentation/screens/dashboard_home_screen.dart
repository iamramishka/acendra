import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/features/dashboard/domain/entities/dashboard_category.dart';
import 'package:acendra/features/dashboard/presentation/dashboard_copy.dart';
import 'package:acendra/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_category_row.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_featured_courses_grid.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_hero_carousel.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_personal_section.dart';
import 'package:acendra/features/dashboard/presentation/widgets/dashboard_why_learn_section.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Student Home composition. StudentShell supplies the app bar/navigation.
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

    return Scaffold(
      body: ref
          .watch(dashboardHomeProvider)
          .when(
            skipLoadingOnRefresh: false,
            loading: () => const Center(
              child: CircularProgressIndicator(
                semanticsLabel: DashboardCopy.loading,
              ),
            ),
            error: (_, _) => AppErrorState(
              message: DashboardCopy.loadError,
              actionLabel: DashboardCopy.retry,
              onRetry: () {
                ref.invalidate(heroSlidesProvider);
                ref.invalidate(dashboardCategoriesProvider);
                ref.invalidate(featuredCoursesProvider);
                ref.invalidate(whyLearnItemsProvider);
                ref.invalidate(dashboardHomeProvider);
              },
            ),
            data: (data) => LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                key: const PageStorageKey('dashboard-home-scroll'),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppBreakpoints.maxContentWidth,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                        constraints.maxWidth < AppBreakpoints.compact
                            ? AppSpacing.md
                            : AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const DashboardPersonalSection(),
                          Text(
                            DashboardCopy.previewNotice,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          DashboardHeroCarousel(
                            slides: data.slides,
                            onAction: (_) => browse(),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          DashboardCategoryRow(
                            categories: data.categories,
                            onViewAll: browse,
                            onCategorySelected:
                                onCategorySelected ??
                                (_) => AppSnackbar.show(
                                  context,
                                  DashboardCopy.previewCategory,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          DashboardFeaturedCoursesGrid(
                            courses: data.courses,
                            categoryNames: {
                              for (final category in data.categories)
                                category.id: category.name,
                            },
                            onViewAll: browse,
                            onCourseSelected:
                                onCourseSelected ??
                                (_) => AppSnackbar.show(
                                  context,
                                  DashboardCopy.previewCourse,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          DashboardWhyLearnSection(items: data.highlights),
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
