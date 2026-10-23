import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/features/checkout/data/repositories/student_order_repository.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:acendra/core/widgets/cards/course_thumbnail.dart';
import 'package:acendra/features/marketplace/presentation/widgets/curriculum_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({super.key, required this.courseId});
  final String courseId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(courseDetailProvider(courseId));
    final enrollment = ref.watch(isEnrolledProvider(courseId));
    final enrolled = enrollment.asData?.value ?? false;
    final open = enrolled
        ? const AsyncData<StudentOrder?>(null)
        : ref.watch(openCourseOrderProvider(courseId));
    void back() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RouteNames.marketplace);
      }
    }

    final appBar = AppBar(
      title: const Text('Course Details'),
      leading: BackButton(onPressed: back),
    );
    return detailState.when(
      loading: () => Scaffold(
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: appBar,
        body: AppErrorState(
          message: 'Failed to load course details.',
          actionLabel: 'Retry',
          onRetry: () => ref.invalidate(courseDetailProvider(courseId)),
        ),
      ),
      data: (detail) {
        final theme = Theme.of(context);
        final categories = ref.watch(categoriesProvider).asData?.value ?? [];
        final category = categories.where((c) => c.id == detail.categoryId);
        final waiting = enrollment.isLoading || open.isLoading;
        final failed = enrollment.hasError || open.hasError;
        final order = open.asData?.value;
        final label = enrollment.isLoading
            ? 'Checking enrollment…'
            : enrollment.hasError
            ? 'Enrollment status unavailable'
            : open.isLoading
            ? 'Checking payment…'
            : open.hasError
            ? 'Payment status unavailable'
            : enrolled
            ? 'Go to Course'
            : order != null
            ? 'Payment Status'
            : 'Buy Course';
        Widget section(String title, Widget content) => Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                content,
              ],
            ),
          ),
        );
        return Scaffold(
          appBar: appBar,
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    enrolled
                        ? 'You own this course'
                        : order?.statusLabel ?? detail.formattedPrice,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    size: ButtonSize.large,
                    label: label,
                    onPressed: waiting || failed
                        ? null
                        : () {
                            if (enrolled) {
                              context.go(
                                RouteNames.courseOverview.replaceFirst(
                                  ':courseId',
                                  Uri.encodeComponent(courseId),
                                ),
                              );
                            } else if (order != null) {
                              context.go(
                                RouteNames.orderStatus.replaceFirst(
                                  ':orderId',
                                  order.id,
                                ),
                              );
                            } else {
                              context.go(
                                RouteNames.checkout.replaceFirst(
                                  ':courseId',
                                  Uri.encodeComponent(courseId),
                                ),
                              );
                            }
                          },
                  ),
                  if (failed)
                    TextButton(
                      onPressed: () {
                        ref.invalidate(isEnrolledProvider(courseId));
                        ref.invalidate(openCourseOrderProvider(courseId));
                      },
                      child: Text(
                        enrollment.hasError
                            ? 'Retry enrollment status'
                            : 'Retry payment status',
                      ),
                    ),
                ],
              ),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SizedBox(
                    height: 220,
                    child: CourseThumbnail(
                      courseId: courseId,
                      title: detail.title,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (category.isNotEmpty)
                    Text(
                      category.first.name.toUpperCase(),
                      style: theme.textTheme.labelLarge,
                    ),
                  Text(detail.title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    detail.shortDescription,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    children: [
                      Chip(
                        label: Text(
                          '${detail.sections.length} module${detail.sections.length == 1 ? '' : 's'}',
                        ),
                      ),
                      Chip(label: Text('${detail.totalLessons} lessons')),
                    ],
                  ),
                  if (detail.sections.isNotEmpty)
                    section(
                      "What You'll Learn",
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: detail.sections
                            .map(
                              (s) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(s.title)),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  if (detail.description?.isNotEmpty ?? false)
                    section('About This Course', Text(detail.description!)),
                  section(
                    'Course Curriculum',
                    CurriculumPreview(
                      sections: detail.sections,
                      isEnrolled: enrolled,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
