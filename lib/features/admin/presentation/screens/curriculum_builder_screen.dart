import 'package:acendra/features/admin/data/repositories/admin_directory_client.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/dialogs/app_dialog.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
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
  final _title = TextEditingController();
  final _expanded = <String>{};
  bool _adding = false;
  bool _busy = false;
  AdminCourseRepository? _formRepository;
  String? _newSectionId;
  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  bool _isCurrentRepository(AdminCourseRepository repository) {
    if (!mounted) return false;
    try {
      return identical(ref.read(adminCourseRepositoryProvider), repository);
    } catch (_) {
      return false;
    }
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (_busy) return;
    final repository = ref.read(adminCourseRepositoryProvider);
    setState(() => _busy = true);
    try {
      await action();
      if (!_isCurrentRepository(repository)) return;
      ref.invalidate(adminCurriculumProvider(widget.courseId));
      ref.invalidate(adminCourseDetailProvider(widget.courseId));
      ref.invalidate(adminCoursesProvider);
    } catch (error) {
      if (mounted && _isCurrentRepository(repository)) {
        AppSnackbar.show(
          context,
          adminDataError(error, 'Unable to save curriculum. Retry.'),
          variant: SnackbarVariant.error,
        );
      }
    } finally {
      if (mounted && _isCurrentRepository(repository)) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _addSection() async {
    if (_title.text.trim().isEmpty || _busy) return;
    final sections = ref
        .read(adminCurriculumProvider(widget.courseId))
        .requireValue;
    final section = AdminCurriculumSection(
      id: _newSectionId ??= newAdminCourseId(),
      courseId: widget.courseId,
      title: _title.text.trim(),
      sortOrder: sections.isEmpty
          ? 0
          : sections.map((s) => s.sortOrder).reduce((a, b) => a > b ? a : b) +
                1,
      lessons: const [],
      rawCourseUpdatedAt: sections.firstOrNull?.rawCourseUpdatedAt,
    );
    final repository = ref.read(adminCourseRepositoryProvider);
    await _mutate(() async {
      await repository.upsertSection(section);
      if (!_isCurrentRepository(repository)) return;
      if (mounted) {
        setState(() => _adding = false);
        _title.clear();
        _newSectionId = null;
      }
    });
  }

  Future<void> _rename(AdminCurriculumSection section) async {
    final repository = ref.read(adminCourseRepositoryProvider);
    String title = section.title;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename section'),
        content: TextFormField(
          initialValue: title,
          autofocus: true,
          maxLength: 200,
          decoration: const InputDecoration(labelText: 'Section Title'),
          onChanged: (value) => title = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (title.trim().isNotEmpty) {
                Navigator.pop(dialogContext, title.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && _isCurrentRepository(repository)) {
      await _mutate(
        () => repository.upsertSection(section.copyWith(title: result)),
      );
    }
  }

  Future<void> _deleteSection(AdminCurriculumSection section) async {
    final repository = ref.read(adminCourseRepositoryProvider);
    final yes = await AppDialog.show(
      context,
      title: 'Delete Section',
      body: 'Delete "${section.title}" and its lessons? This cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      confirmVariant: ButtonVariant.destructive,
    );
    if (yes == true && _isCurrentRepository(repository)) {
      await _mutate(
        () => repository.deleteSection(
          section.id,
          expectedUpdatedAt: section.rawCourseUpdatedAt,
        ),
      );
    }
  }

  Future<void> _deleteLesson(AdminLesson lesson) async {
    final repository = ref.read(adminCourseRepositoryProvider);
    final yes = await AppDialog.show(
      context,
      title: 'Delete lesson',
      body: 'Delete "${lesson.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      confirmVariant: ButtonVariant.destructive,
    );
    if (yes == true && _isCurrentRepository(repository)) {
      await _mutate(
        () => repository.deleteLesson(
          lesson.id,
          expectedUpdatedAt: lesson.rawCourseUpdatedAt,
        ),
      );
    }
  }

  Future<void> _moveLesson(
    AdminCurriculumSection section,
    int index,
    int direction,
  ) async {
    final lessons = List<AdminLesson>.of(section.lessons);
    lessons.insert(index + direction, lessons.removeAt(index));
    await _mutate(
      () => ref
          .read(adminCourseRepositoryProvider)
          .reorderLessons(
            widget.courseId,
            section.id,
            lessons.map((l) => l.id).toList(),
            expectedUpdatedAt: section.rawCourseUpdatedAt,
          ),
    );
  }

  Future<void> _reorder(
    List<AdminCurriculumSection> sections,
    int oldIndex,
    int newIndex,
  ) async {
    final reordered = List<AdminCurriculumSection>.of(sections);
    reordered.insert(newIndex, reordered.removeAt(oldIndex));
    await _mutate(
      () => ref
          .read(adminCourseRepositoryProvider)
          .reorderSections(
            widget.courseId,
            reordered.map((s) => s.id).toList(),
            expectedUpdatedAt: sections.firstOrNull?.rawCourseUpdatedAt,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(adminCourseRepositoryProvider);
    if (!identical(repository, _formRepository)) {
      if (_formRepository != null) {
        _title.clear();
        _expanded.clear();
        _adding = false;
        _busy = false;
        _newSectionId = null;
      }
      _formRepository = repository;
    }
    final data = ref.watch(adminCurriculumProvider(widget.courseId));
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Curriculum', style: Theme.of(context).textTheme.headlineMedium),
          const Text('Unpublish the course before changing its curriculum.'),
          if (_busy) const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorState(
                message: adminDataError(e, 'Unable to load curriculum. Retry.'),
                actionLabel: 'Retry',
                onRetry: () =>
                    ref.invalidate(adminCurriculumProvider(widget.courseId)),
              ),
              data: (sections) => sections.isEmpty
                  ? const AppEmptyState(
                      message: 'No sections yet. Add your first section below.',
                    )
                  : ReorderableListView.builder(
                      itemCount: sections.length,
                      buildDefaultDragHandles: false,
                      onReorderItem: (oldIndex, newIndex) {
                        if (!_busy) _reorder(sections, oldIndex, newIndex);
                      },
                      itemBuilder: (_, index) =>
                          _section(sections[index], index),
                    ),
            ),
          ),
          if (_adding) ...[
            AppTextField(label: 'Section Title', controller: _title),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: 'Cancel',
                  variant: ButtonVariant.outlined,
                  onPressed: _busy
                      ? null
                      : () => setState(() => _adding = false),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  label: 'Add',
                  isLoading: _busy,
                  onPressed: _busy ? null : _addSection,
                ),
              ],
            ),
          ] else
            AppButton(
              label: 'Add Section',
              variant: ButtonVariant.secondary,
              onPressed: _busy || !data.hasValue
                  ? null
                  : () => setState(() => _adding = true),
            ),
        ],
      ),
    );
  }

  Widget _section(AdminCurriculumSection section, int index) {
    final open = _expanded.contains(section.id);
    return Card(
      key: ValueKey(section.id),
      child: Column(
        children: [
          ListTile(
            leading: ReorderableDragStartListener(
              index: index,
              enabled: !_busy,
              child: const Icon(Icons.drag_handle),
            ),
            title: Text(section.title),
            subtitle: Text(
              '${section.lessons.length} lessons · ${section.isPublished ? 'Published' : 'Draft'}',
            ),
            onTap: () => setState(() {
              if (open) {
                _expanded.remove(section.id);
              } else {
                _expanded.add(section.id);
              }
            }),
            trailing: PopupMenuButton<String>(
              tooltip: 'Section actions',
              enabled: !_busy,
              onSelected: (action) {
                if (action == 'rename') _rename(section);
                if (action == 'publication') {
                  _mutate(
                    () => ref
                        .read(adminCourseRepositoryProvider)
                        .upsertSection(
                          section.copyWith(isPublished: !section.isPublished),
                        ),
                  );
                }
                if (action == 'delete') _deleteSection(section);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: Text('Rename section'),
                ),
                PopupMenuItem(
                  value: 'publication',
                  child: Text(
                    section.isPublished
                        ? 'Unpublish section'
                        : 'Publish section',
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete section'),
                ),
              ],
            ),
          ),
          if (open) ...[
            for (final entry in section.lessons.indexed)
              _lesson(section, entry.$2, entry.$1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppButton(
                label: 'Add Lesson',
                variant: ButtonVariant.outlined,
                onPressed: _busy
                    ? null
                    : () => context.go(
                        '/admin/courses/${widget.courseId}/curriculum/new/edit?section_id=${section.id}',
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lesson(
    AdminCurriculumSection section,
    AdminLesson lesson,
    int index,
  ) => ListTile(
    leading: Icon(switch (lesson.lessonType) {
      LessonType.video => Icons.play_circle_outline,
      LessonType.pdf => Icons.picture_as_pdf_outlined,
      LessonType.text => Icons.article_outlined,
      LessonType.image => Icons.image_outlined,
      LessonType.quiz => Icons.quiz_outlined,
    }),
    title: Text(lesson.title),
    subtitle: Text(
      '${lesson.lessonType.name}${lesson.isPreviewed ? ' · Preview' : ''}${lesson.isPublished ? ' · Published' : ''}',
    ),
    onTap: _busy
        ? null
        : () => context.go(
            '/admin/courses/${widget.courseId}/curriculum/${lesson.id}/edit',
          ),
    trailing: PopupMenuButton<String>(
      tooltip: 'Lesson actions',
      enabled: !_busy,
      onSelected: (action) {
        if (action == 'up') _moveLesson(section, index, -1);
        if (action == 'down') _moveLesson(section, index, 1);
        if (action == 'delete') _deleteLesson(lesson);
      },
      itemBuilder: (_) => [
        if (index > 0) const PopupMenuItem(value: 'up', child: Text('Move up')),
        if (index < section.lessons.length - 1)
          const PopupMenuItem(value: 'down', child: Text('Move down')),
        const PopupMenuItem(value: 'delete', child: Text('Delete lesson')),
      ],
    ),
  );
}
