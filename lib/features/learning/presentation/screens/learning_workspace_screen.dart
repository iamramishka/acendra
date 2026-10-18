import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/feedback/app_skeleton.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/features/learning/domain/entities/lesson_content.dart';
import 'package:acendra/features/learning/presentation/providers/learning_provider.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/learning/presentation/widgets/curriculum_nav.dart';
import 'package:acendra/features/learning/presentation/widgets/image_lesson_viewer.dart';
import 'package:acendra/features/learning/presentation/widgets/text_lesson_viewer.dart';
import 'package:flutter/material.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/protected_pdf_lesson.dart';
import 'package:acendra/features/video_player/presentation/widgets/authorized_video_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const double _kSidebarWidth = 280.0;
const double _kDesktopBreakpoint = 900.0;

class LearningWorkspaceScreen extends ConsumerStatefulWidget {
  const LearningWorkspaceScreen({
    super.key,
    required this.courseId,
    this.initialLessonId,
  });

  final String courseId;
  final String? initialLessonId;
  @override
  ConsumerState<LearningWorkspaceScreen> createState() =>
      _LearningWorkspaceScreenState();
}

class _LearningWorkspaceScreenState
    extends ConsumerState<LearningWorkspaceScreen> {
  bool _openedInitialLesson = false;
  String get courseId => widget.courseId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learningWorkspaceProvider(courseId));
    final notifier = ref.read(learningWorkspaceProvider(courseId).notifier);
    if (!_openedInitialLesson &&
        !state.isLoading &&
        state.currentContent != null) {
      _openedInitialLesson = true;
      final requested = widget.initialLessonId;
      if (requested != null &&
          state.flatLessons.any((lesson) => lesson.id == requested)) {
        Future.microtask(() {
          if (mounted) notifier.selectLesson(requested);
        });
      }
    }

    if (state.error != null && !state.isLoading) {
      return AppErrorState(
        message: 'Could not load course content.',
        actionLabel: 'Retry',
        onRetry: () => notifier.loadCourse(courseId),
      );
    }

    if (state.isLoading && state.sections.isEmpty) {
      return const _LoadingSkeleton();
    }

    final flat = state.flatLessons;
    final currentIndex = flat.indexWhere((l) => l.id == state.currentLessonId);

    void onPrevious() {
      if (currentIndex > 0) {
        notifier.selectLesson(flat[currentIndex - 1].id);
      }
    }

    void onNext() {
      if (currentIndex >= 0 && currentIndex < flat.length - 1) {
        notifier.selectLesson(flat[currentIndex + 1].id);
      }
    }

    final contentArea = Column(
      children: [
        if (state.progressError != null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Expanded(child: Text(state.progressError!)),
                TextButton(
                  onPressed: () => notifier.loadCourse(courseId),
                  child: const Text('Reload progress'),
                ),
              ],
            ),
          ),
        if (state.currentLessonId != null && !state.isLoading)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: TextButton.icon(
                onPressed:
                    state.isSavingProgress ||
                        !state.progressReady ||
                        state.progressError != null
                    ? null
                    : () => notifier.setCompleted(
                        !(state.progress[state.currentLessonId]?.completed ??
                            false),
                      ),
                icon: Icon(
                  state.progress[state.currentLessonId]?.completed == true
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                ),
                label: Text(
                  state.isSavingProgress
                      ? 'Saving progress…'
                      : state.progress[state.currentLessonId]?.completed == true
                      ? 'Mark incomplete'
                      : 'Mark complete',
                ),
              ),
            ),
          ),
        Expanded(
          child: _LessonContentArea(
            content: state.currentContent,
            isLoading: state.isLoading,
            onPrevious: currentIndex > 0 ? onPrevious : null,
            onNext: currentIndex >= 0 && currentIndex < flat.length - 1
                ? onNext
                : null,
            initialVideoSeconds:
                state.progress[state.currentLessonId]?.videoSeconds,
            onVideoSeconds: state.currentLessonId != null
                ? (seconds) => notifier.saveVideoPosition(
                    state.currentLessonId!,
                    seconds,
                  )
                : null,
          ),
        ),
      ],
    );

    final curriculumNav = CurriculumNav(
      sections: state.sections,
      currentLessonId: state.currentLessonId,
      onLessonTap: (lessonId) => notifier.selectLesson(lessonId),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _kDesktopBreakpoint) {
          // Desktop: sidebar + content
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _kSidebarWidth,
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: curriculumNav,
                ),
              ),
              VerticalDivider(
                width: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              Expanded(child: contentArea),
            ],
          );
        } else {
          // Mobile/tablet: content + FAB to open curriculum drawer
          return Stack(
            children: [
              contentArea,
              Positioned(
                bottom: AppSpacing.xl,
                right: AppSpacing.md,
                child: FloatingActionButton.small(
                  heroTag: 'curriculum_fab',
                  tooltip: 'Course curriculum',
                  onPressed: () => _showCurriculumDrawer(
                    context: context,
                    sections: state.sections,
                    currentLessonId: state.currentLessonId,
                    onLessonTap: (lessonId) => notifier.selectLesson(lessonId),
                  ),
                  child: const Icon(Icons.list),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  void _showCurriculumDrawer({
    required BuildContext context,
    required List<CurriculumSection> sections,
    required String? currentLessonId,
    required void Function(String) onLessonTap,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.dialog),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                'Curriculum',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: CurriculumNav(
                sections: sections,
                currentLessonId: currentLessonId,
                onLessonTap: onLessonTap,
                scrollController: scrollController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lesson content area
// ---------------------------------------------------------------------------

class _LessonContentArea extends StatelessWidget {
  const _LessonContentArea({
    required this.content,
    required this.isLoading,
    this.onPrevious,
    this.onNext,
    this.initialVideoSeconds,
    this.onVideoSeconds,
  });

  final LessonContent? content;
  final bool isLoading;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final int? initialVideoSeconds;
  final ValueChanged<int>? onVideoSeconds;

  @override
  Widget build(BuildContext context) {
    if (isLoading && content == null) {
      return const _LessonLoadingSkeleton();
    }

    if (content == null) {
      return const Center(child: Text('Select a lesson to begin.'));
    }

    if ((content!.lessonType == 'text' && content!.contentText == null) ||
        (content!.lessonType == 'image' && content!.contentImageUrl == null)) {
      return Column(
        children: [
          const Expanded(
            child: Center(
              child: Text('This lesson content is currently unavailable.'),
            ),
          ),
          _LessonNavBar(onPrevious: onPrevious, onNext: onNext),
        ],
      );
    }

    return switch (content!.lessonType) {
      'video' => Column(
        children: [
          Expanded(
            child: AuthorizedVideoWidget(
              lessonId: content!.id,
              title: content!.title,
              initialVideoSeconds: initialVideoSeconds,
              onVideoSeconds: onVideoSeconds,
            ),
          ),
          _LessonNavBar(onPrevious: onPrevious, onNext: onNext),
        ],
      ),
      'pdf' => Column(
        children: [
          Expanded(child: ProtectedPdfLesson(lessonId: content!.id)),
          _LessonNavBar(onPrevious: onPrevious, onNext: onNext),
        ],
      ),
      'text' => TextLessonViewer(
        title: content!.title,
        content: content!.contentText ?? '',
        onPrevious: onPrevious,
        onNext: onNext,
      ),
      'image' => ImageLessonViewer(
        title: content!.title,
        imageUrl: content!.contentImageUrl ?? '',
        onPrevious: onPrevious,
        onNext: onNext,
      ),
      _ => _PlaceholderLessonViewer(
        title: content!.title,
        lessonType: content!.lessonType,
        onPrevious: onPrevious,
        onNext: onNext,
      ),
    };
  }
}

// ---------------------------------------------------------------------------
// Placeholder for video / pdf lesson types
// ---------------------------------------------------------------------------

class _PlaceholderLessonViewer extends StatelessWidget {
  const _PlaceholderLessonViewer({
    required this.title,
    required this.lessonType,
    this.onPrevious,
    this.onNext,
  });

  final String title;
  final String lessonType;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = lessonType == 'video' ? 'Video' : 'PDF';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Card(
                    color: colorScheme.surfaceContainerHighest,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                        vertical: AppSpacing.xl,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            lessonType == 'video'
                                ? Icons.videocam_outlined
                                : Icons.picture_as_pdf_outlined,
                            size: 48,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            '$label content is currently unavailable',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _LessonNavBar(onPrevious: onPrevious, onNext: onNext),
      ],
    );
  }
}

class _LessonNavBar extends StatelessWidget {
  const _LessonNavBar({this.onPrevious, this.onNext});
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (onPrevious != null)
            TextButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
            )
          else
            const SizedBox.shrink(),
          if (onNext != null)
            TextButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
              iconAlignment: IconAlignment.end,
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton loading states
// ---------------------------------------------------------------------------

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= _kDesktopBreakpoint;
        if (isDesktop) {
          return Row(
            children: [
              SizedBox(width: _kSidebarWidth, child: _SidebarSkeleton()),
              const VerticalDivider(width: 1),
              const Expanded(child: _LessonLoadingSkeleton()),
            ],
          );
        }
        return const _LessonLoadingSkeleton();
      },
    );
  }
}

class _SidebarSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(6, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppSkeleton(
              height: 20,
              width: i % 3 == 0 ? 180 : 140,
              semanticLabel: 'Loading lesson list',
            ),
          );
        }),
      ),
    );
  }
}

class _LessonLoadingSkeleton extends StatelessWidget {
  const _LessonLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeleton(
            height: 32,
            width: 320,
            semanticLabel: 'Loading lesson title',
          ),
          const SizedBox(height: AppSpacing.lg),
          ...List.generate(4, (i) {
            return const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppSkeleton(
                height: 16,
                semanticLabel: 'Loading lesson content',
              ),
            );
          }),
        ],
      ),
    );
  }
}
