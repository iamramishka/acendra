import 'package:acendra/features/admin/data/repositories/admin_directory_client.dart';
import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/dialogs/app_dialog.dart';
import 'package:acendra/core/widgets/feedback/app_skeleton.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:acendra/features/admin/domain/entities/admin_course.dart';
import 'package:acendra/features/admin/presentation/providers/admin_courses_provider.dart';
import 'package:acendra/features/admin/presentation/widgets/courses/course_card_tile.dart';
import 'package:acendra/features/admin/presentation/widgets/courses/course_table_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminCoursesScreen extends ConsumerStatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  ConsumerState<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends ConsumerState<AdminCoursesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminCourse> _filtered(List<AdminCourse> courses) {
    if (_query.isEmpty) return courses;
    final q = _query.toLowerCase();
    return courses.where((c) => c.title.toLowerCase().contains(q)).toList();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String courseId,
    String title,
  ) async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Delete Course',
      body: 'Delete "$title"? This cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      confirmVariant: ButtonVariant.destructive,
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref.read(adminCoursesProvider.notifier).deleteCourse(courseId);
        if (context.mounted) {
          AppSnackbar.show(
            context,
            'Course deleted.',
            variant: SnackbarVariant.success,
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.show(
            context,
            adminDataError(e, 'Failed to delete course.'),
            variant: SnackbarVariant.error,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(adminCoursesProvider);
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.medium;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppSpacing.md),
          _buildSearchBar(),
          const SizedBox(height: AppSpacing.md),
          if (isWide) _buildTableHeader(context),
          Expanded(
            child: coursesAsync.when(
              loading: _buildSkeleton,
              error: (e, _) => AppErrorState(
                message: adminDataError(e, 'Unable to load courses. Retry.'),
                actionLabel: 'Retry',
                onRetry: () => ref.invalidate(adminCoursesProvider),
              ),
              data: (courses) {
                final filtered = _filtered(courses);
                if (filtered.isEmpty) {
                  return AppEmptyState(
                    message: courses.isEmpty
                        ? 'No courses yet. Create your first course.'
                        : 'No courses match your search.',
                    actionLabel: courses.isEmpty ? 'Add Course' : null,
                    onAction: courses.isEmpty
                        ? () => context.go('/admin/courses/new/edit')
                        : null,
                  );
                }
                return isWide
                    ? _buildTable(context, filtered)
                    : _buildCards(context, filtered);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Text('Courses', style: tt.headlineMedium),
        const Spacer(),
        AppButton(
          label: 'Add Course',
          onPressed: () => context.go('/admin/courses/new/edit'),
          variant: ButtonVariant.primary,
          icon: const Icon(Icons.add, size: 18),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return AppTextField(
      hint: 'Search courses…',
      controller: _searchController,
      prefixIcon: const Icon(Icons.search),
      onChanged: (v) => setState(() => _query = v),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.md),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const SizedBox(width: 56 + AppSpacing.md),
          Expanded(
            flex: 3,
            child: Text(
              'Course',
              style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Enrolled',
              style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const SizedBox(width: 80),
          const SizedBox(width: AppSpacing.md),
          const SizedBox(width: 220),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<AdminCourse> courses) {
    return ListView.builder(
      itemCount: courses.length,
      itemBuilder: (_, i) => CourseTableRow(
        course: courses[i],
        onEdit: () => context.go('/admin/courses/${courses[i].id}/edit'),
        onCurriculum: () =>
            context.go('/admin/courses/${courses[i].id}/curriculum'),
        onDelete: () =>
            _confirmDelete(context, courses[i].id, courses[i].title),
      ),
    );
  }

  Widget _buildCards(BuildContext context, List<AdminCourse> courses) {
    return ListView.builder(
      itemCount: courses.length,
      itemBuilder: (_, i) => CourseCardTile(
        course: courses[i],
        onEdit: () => context.go('/admin/courses/${courses[i].id}/edit'),
        onCurriculum: () =>
            context.go('/admin/courses/${courses[i].id}/curriculum'),
        onDelete: () =>
            _confirmDelete(context, courses[i].id, courses[i].title),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, _) => AppSkeleton(
        height: 80,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    );
  }
}
