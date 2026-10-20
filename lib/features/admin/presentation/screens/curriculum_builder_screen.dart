import 'package:acendra/features/admin/data/repositories/admin_directory_client.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/dialogs/app_dialog.dart';
import 'package:acendra/core/widgets/feedback/app_skeleton.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:acendra/features/admin/data/repositories/admin_course_repository.dart';
import 'package:acendra/features/admin/domain/entities/admin_lesson.dart';
import 'package:acendra/features/admin/domain/entities/curriculum_section.dart';
import 'package:acendra/features/admin/presentation/providers/admin_courses_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CurriculumBuilderScreen extends ConsumerStatefulWidget {
  const CurriculumBuilderScreen({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CurriculumBuilderScreen> createState() =>
      _CurriculumBuilderScreenState();
}

class _CurriculumBuilderScreenState
    extends ConsumerState<CurriculumBuilderScreen> {
  final _sectionTitleController = TextEditingController();
  bool _addingSection = false;
  bool _savingSection = false;
  final Set<String> _expandedSections = {};

  @override
  void dispose() {
    _sectionTitleController.dispose();
    super.dispose();
  }

  Future<void> _addSection() async {
    final title = _sectionTitleController.text.trim();
    if (title.isEmpty) return;
    setState(() => _savingSection = true);
    try {
      final sections =
          ref.read(adminCurriculumProvider(widget.courseId)).asData?.value ??
          [];
      final section = AdminCurriculumSection(
        id: 'section-${DateTime.now().millisecondsSinceEpoch}',
        courseId: widget.courseId,
        title: title,
        sortOrder: sections.length,
        lessons: const [],
      );
      await ref.read(adminCourseRepositoryProvider).upsertSection(section);
      ref.invalidate(adminCurriculumProvider(widget.courseId));
      _sectionTitleController.clear();
      setState(() => _addingSection = false);
      if (mounted) {
        AppSnackbar.show(
          context,
          'Section added.',
          variant: SnackbarVariant.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          adminDataError(e, 'Failed to add section.'),
          variant: SnackbarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _savingSection = false);
    }
  }

  Future<void> _deleteSection(String sectionId, String title) async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Delete Section',
      body: 'Delete "$title" and all its lessons? This cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      confirmVariant: ButtonVariant.destructive,
    );
    if (confirmed == true && mounted) {
      try {
        await ref.read(adminCourseRepositoryProvider).deleteSection(sectionId);
        ref.invalidate(adminCurriculumProvider(widget.courseId));
        if (mounted) {
          AppSnackbar.show(
            context,
            'Section deleted.',
            variant: SnackbarVariant.success,
          );
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.show(
            context,
            adminDataError(e, 'Failed to delete section.'),
            variant: SnackbarVariant.error,
          );
        }
      }
    }
  }

  Future<void> _reorderSections(
    List<AdminCurriculumSection> sections,
    int oldIndex,
    int newIndex,
  ) async {
    final reordered = List<AdminCurriculumSection>.from(sections);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    final repo = ref.read(adminCourseRepositoryProvider);
    for (var i = 0; i < reordered.length; i++) {
      await repo.upsertSection(reordered[i].copyWith(sortOrder: i));
    }
    ref.invalidate(adminCurriculumProvider(widget.courseId));
  }

  IconData _lessonTypeIcon(LessonType type) {
    return switch (type) {
      LessonType.video => Icons.play_circle_outline,
      LessonType.pdf => Icons.picture_as_pdf_outlined,
      LessonType.text => Icons.article_outlined,
      LessonType.quiz => Icons.quiz_outlined,
    };
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final curriculumAsync = ref.watch(adminCurriculumProvider(widget.courseId));

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Curriculum', style: tt.headlineMedium),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: curriculumAsync.when(
              loading: _buildSkeleton,
              error: (e, _) => AppErrorState(
                message: adminDataError(e, 'Unable to load courses. Retry.'),
                actionLabel: 'Retry',
                onRetry: () =>
                    ref.invalidate(adminCurriculumProvider(widget.courseId)),
              ),
              data: (sections) => sections.isEmpty && !_addingSection
                  ? AppEmptyState(
                      message: 'No sections yet. Add your first section.',
                      actionLabel: 'Add Section',
                      onAction: () => setState(() => _addingSection = true),
                    )
                  : _buildSectionList(context, sections),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_addingSection) _buildAddSectionForm(context),
          if (!_addingSection)
            AppButton(
              label: 'Add Section',
              onPressed: () => setState(() => _addingSection = true),
              variant: ButtonVariant.secondary,
              icon: const Icon(Icons.add, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionList(
    BuildContext context,
    List<AdminCurriculumSection> sections,
  ) {
    return ReorderableListView.builder(
      itemCount: sections.length,
      onReorderItem: (o, n) => _reorderSections(sections, o, n),
      buildDefaultDragHandles: false,
      itemBuilder: (_, i) => _buildSectionCard(context, sections[i], i),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    AdminCurriculumSection section,
    int index,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isExpanded = _expandedSections.contains(section.id);

    return Card(
      key: ValueKey(section.id),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.card),
            ),
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedSections.remove(section.id);
              } else {
                _expandedSections.add(section.id);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Icon(Icons.drag_handle, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      section.title,
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${section.lessons.length} lessons',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  IconButton(
                    tooltip: 'Delete section',
                    icon: const Icon(Icons.delete_outline),
                    color: cs.error,
                    onPressed: () => _deleteSection(section.id, section.title),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: cs.outlineVariant),
            ...section.lessons.map((l) => _buildLessonRow(context, l)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppButton(
                label: 'Add Lesson',
                onPressed: () => context.go(
                  '/admin/courses/${widget.courseId}/curriculum/new/edit',
                ),
                variant: ButtonVariant.outlined,
                size: ButtonSize.medium,
                icon: const Icon(Icons.add, size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLessonRow(BuildContext context, AdminLesson lesson) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => context.go(
        '/admin/courses/${widget.courseId}/curriculum/${lesson.id}/edit',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.lg),
            Icon(
              _lessonTypeIcon(lesson.lessonType),
              size: 20,
              color: cs.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(lesson.title, style: tt.bodyMedium)),
            if (lesson.durationSeconds != null) ...[
              Text(
                _formatDuration(lesson.durationSeconds!),
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (lesson.isPreviewed)
              const StatusBadge(label: 'Preview', variant: BadgeVariant.info),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSectionForm(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Section Title',
              hint: 'e.g. Getting Started',
              controller: _sectionTitleController,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: 'Cancel',
                  onPressed: () {
                    _sectionTitleController.clear();
                    setState(() => _addingSection = false);
                  },
                  variant: ButtonVariant.outlined,
                  size: ButtonSize.medium,
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  label: 'Add',
                  onPressed: _savingSection ? null : _addSection,
                  variant: ButtonVariant.primary,
                  size: ButtonSize.medium,
                  isLoading: _savingSection,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, _) => AppSkeleton(
        height: 64,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    );
  }
}
