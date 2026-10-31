import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/feedback/app_skeleton.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/features/learning/domain/course_progress_summary.dart';
import 'package:acendra/features/learning/domain/entities/lesson_content.dart';
import 'package:acendra/features/learning/presentation/providers/learning_provider.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/learning/presentation/widgets/curriculum_nav.dart';
import 'package:acendra/features/learning/presentation/widgets/image_lesson_viewer.dart';
import 'package:acendra/features/learning/presentation/widgets/text_lesson_viewer.dart';
import 'package:flutter/material.dart';
import 'package:acendra/features/pdf_reader/presentation/widgets/protected_pdf_lesson.dart';
import 'package:acendra/features/learning/presentation/widgets/video_lesson_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const double _kSidebarWidth = 280.0;
const double _kDesktopBreakpoint = 900.0;

class LearningWorkspaceScreen extends ConsumerStatefulWidget {
  const LearningWorkspaceScreen({
    super.key,
    required this.courseId,
    this.initialLessonId,
  });

  final String courseId;

  /// Lesson from the URL; falls back to the saved resume lesson when null.
  final String? initialLessonId;

  @override
  ConsumerState<LearningWorkspaceScreen> createState() =>
      _LearningWorkspaceScreenState();
}

class _LearningWorkspaceScreenState
    extends ConsumerState<LearningWorkspaceScreen> {
  @override
  void initState() {
    super.initState();
    _requestInitialLesson();
  }

  @override
  void didUpdateWidget(covariant LearningWorkspaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.courseId != oldWidget.courseId ||
        widget.initialLessonId != oldWidget.initialLessonId) {
      _requestInitialLesson();
    }
  }

  void _requestInitialLesson() {
    final lessonId = widget.initialLessonId;
    final courseId = widget.courseId;
    if (lessonId != null) {
      // A retained workspace can already have loaded sections. Selecting then
      // changes notifier state, so wait until this widget finishes mounting.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            widget.courseId != courseId ||
            widget.initialLessonId != lessonId) {
          return;
        }
        ref
            .read(learningWorkspaceProvider(courseId).notifier)
            .requestLesson(lessonId);
      });
    }
  }

  void _openLesson(String lessonId) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(
        '/learn/${Uri.encodeComponent(widget.courseId)}/'
        '${Uri.encodeComponent(lessonId)}',
      );
    } else {
      // Standalone workspace hosts can select lessons without a router.
      ref
          .read(learningWorkspaceProvider(widget.courseId).notifier)
          .requestLesson(lessonId);
    }
  }

  Future<void> _completeAndContinue(LearningNotifier notifier) async {
    final outcome = await notifier.completeAndContinue();
    if (!mounted) return;
    switch (outcome) {
      case ContinueOutcome.advanced:
        final lessonId = ref
            .read(learningWorkspaceProvider(widget.courseId))
            .currentLessonId;
        if (lessonId != null) _openLesson(lessonId);
        break;
      case ContinueOutcome.failed:
        break;
      case ContinueOutcome.moduleFinished:
      case ContinueOutcome.courseFinished:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              outcome == ContinueOutcome.courseFinished
                  ? 'Course finished'
                  : 'Module finished',
            ),
          ),
        );
        context.go('/learn/${widget.courseId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseId = widget.courseId;
    final state = ref.watch(learningWorkspaceProvider(courseId));
    final notifier = ref.read(learningWorkspaceProvider(courseId).notifier);
    final summary = CourseProgressSummary.from(state.sections, state.progress);
    final completed = state.progress[state.currentLessonId]?.completed ?? false;
    final busy =
        state.isSavingProgress ||
        !state.progressReady ||
        state.progressError != null;
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
        _openLesson(flat[currentIndex - 1].id);
      }
    }

    void onNext() {
      if (currentIndex >= 0 && currentIndex < flat.length - 1) {
        _openLesson(flat[currentIndex + 1].id);
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
        if (state.currentLessonId != null &&
            !state.isLoading &&
            state.currentContent != null)
          _LessonHeader(
            lessonNumber: currentIndex + 1,
            typeLabel: flat[currentIndex].typeLabel,
            completed: completed,
            summary: summary,
            onMarkIncomplete: busy ? null : () => notifier.setCompleted(false),
          ),
        Expanded(
          child: _LessonContentArea(
            sections: state.sections,
            onResource: _openLesson,
            content: state.currentContent,
            isLoading: state.isLoading,
            onPrevious: currentIndex > 0 ? onPrevious : null,
            onNext: currentIndex >= 0 && currentIndex < flat.length - 1
                ? onNext
                : null,
            forwardLabel: completed
                ? null
                : currentIndex == flat.length - 1
                ? 'Mark Complete'
                : 'Mark Complete & Continue',
            onForward: completed || busy
                ? null
                : () => _completeAndContinue(notifier),
            forwardBusy: state.isSavingProgress,
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
      onLessonTap: _openLesson,
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
                // Keep curriculum access above the sticky completion footer.
                bottom:
                    AppSpacing.xl +
                    kMinInteractiveDimension +
                    2 * AppSpacing.md,
                right: AppSpacing.md,
                child: FloatingActionButton.small(
                  heroTag: 'curriculum_fab',
                  tooltip: 'Course curriculum',
                  onPressed: () => _showCurriculumDrawer(
                    context: context,
                    sections: state.sections,
                    currentLessonId: state.currentLessonId,
                    onLessonTap: _openLesson,
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
      builder: (drawerContext) => DraggableScrollableSheet(
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
                  color: Theme.of(drawerContext).colorScheme.outlineVariant,
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
                style: Theme.of(drawerContext).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: CurriculumNav(
                sections: sections,
                currentLessonId: currentLessonId,
                onLessonTap: (lessonId) {
                  Navigator.of(drawerContext).pop();
                  onLessonTap(lessonId);
                },
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
    required this.sections,
    required this.onResource,
    this.onPrevious,
    this.onNext,
    this.forwardLabel,
    this.onForward,
    this.forwardBusy = false,
    this.initialVideoSeconds,
    this.onVideoSeconds,
  });

  final LessonContent? content;
  final List<CurriculumSection> sections;
  final ValueChanged<String> onResource;
  final bool isLoading;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final String? forwardLabel;
  final VoidCallback? onForward;
  final bool forwardBusy;
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
          _LessonNavBar(
            onPrevious: onPrevious,
            onNext: onNext,
            forwardLabel: forwardLabel,
            onForward: onForward,
            forwardBusy: forwardBusy,
          ),
        ],
      );
    }

    return switch (content!.lessonType) {
      'video' => Column(
        children: [
          Expanded(
            child: VideoLessonPanel(
              key: ValueKey(content!.id),
              lessonId: content!.id,
              title: content!.title,
              sectionId: content!.sectionId,
              sections: sections,
              onResource: onResource,
              initialVideoSeconds: initialVideoSeconds,
              onVideoSeconds: onVideoSeconds,
            ),
          ),
          _LessonNavBar(
            onPrevious: onPrevious,
            onNext: onNext,
            forwardLabel: forwardLabel,
            onForward: onForward,
            forwardBusy: forwardBusy,
          ),
        ],
      ),
      'pdf' => Column(
        children: [
          Expanded(child: ProtectedPdfLesson(lessonId: content!.id)),
          _LessonNavBar(
            onPrevious: onPrevious,
            onNext: onNext,
            forwardLabel: forwardLabel,
            onForward: onForward,
            forwardBusy: forwardBusy,
          ),
        ],
      ),
      'text' => Column(
        children: [
          Expanded(
            child: TextLessonViewer(
              title: content!.title,
              content: content!.contentText ?? '',
            ),
          ),
          _LessonNavBar(
            onPrevious: onPrevious,
            onNext: onNext,
            forwardLabel: forwardLabel,
            onForward: onForward,
            forwardBusy: forwardBusy,
          ),
        ],
      ),
      'image' => Column(
        children: [
          Expanded(
            child: ImageLessonViewer(
              title: content!.title,
              imageUrl: content!.contentImageUrl ?? '',
            ),
          ),
          _LessonNavBar(
            onPrevious: onPrevious,
            onNext: onNext,
            forwardLabel: forwardLabel,
            onForward: onForward,
            forwardBusy: forwardBusy,
          ),
        ],
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

/// Lesson number, type, status and a compact course-progress readout.
class _LessonHeader extends StatelessWidget {
  const _LessonHeader({
    required this.lessonNumber,
    required this.typeLabel,
    required this.completed,
    required this.summary,
    this.onMarkIncomplete,
  });

  final int lessonNumber;
  final String typeLabel;
  final bool completed;
  final CourseProgressSummary summary;
  final VoidCallback? onMarkIncomplete;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Lesson ${lessonNumber.toString().padLeft(2, '0')} · '
                '$typeLabel Lesson',
                style: tt.labelLarge,
              ),
              Chip(
                visualDensity: VisualDensity.compact,
                avatar: Icon(
                  completed ? Icons.check_circle : Icons.timelapse,
                  size: 16,
                  color: completed ? cs.primary : cs.onSurfaceVariant,
                ),
                label: Text(completed ? 'Completed' : 'In Progress'),
              ),
              if (completed && onMarkIncomplete != null)
                TextButton(
                  onPressed: onMarkIncomplete,
                  child: const Text('Mark incomplete'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            label:
                'Course progress ${summary.percent} percent, '
                '${summary.completedLessons} of ${summary.totalLessons} '
                'lessons completed',
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(value: summary.percent / 100),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${summary.completedLessons}/${summary.totalLessons} · '
                  '${summary.percent}%',
                  style: tt.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonNavBar extends StatelessWidget {
  const _LessonNavBar({
    this.onPrevious,
    this.onNext,
    this.forwardLabel,
    this.onForward,
    this.forwardBusy = false,
  });
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  /// When set, replaces "Next" with a primary complete-and-continue action.
  final String? forwardLabel;
  final VoidCallback? onForward;
  final bool forwardBusy;

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
          if (forwardLabel != null)
            Flexible(
              child: FilledButton(
                onPressed: onForward,
                child: Text(
                  forwardBusy ? 'Saving progress…' : forwardLabel!,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          else if (onNext != null)
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
