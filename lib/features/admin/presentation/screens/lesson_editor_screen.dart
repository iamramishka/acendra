import 'package:acendra/features/admin/presentation/widgets/media_upload_control.dart';
import 'package:acendra/features/admin/data/repositories/admin_directory_client.dart';
import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_skeleton.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:acendra/features/admin/data/repositories/admin_course_repository.dart';
import 'package:acendra/features/admin/domain/entities/admin_lesson.dart';
import 'package:acendra/features/admin/presentation/providers/admin_courses_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LessonEditorScreen extends ConsumerStatefulWidget {
  const LessonEditorScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  final String courseId;
  final String lessonId;

  @override
  ConsumerState<LessonEditorScreen> createState() => _LessonEditorScreenState();
}

class _LessonEditorScreenState extends ConsumerState<LessonEditorScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _durationController = TextEditingController();

  LessonType _lessonType = LessonType.video;
  bool _isPreviewed = false;
  bool _saving = false;
  bool _initialized = false;

  String? _titleError;

  bool get _isNew => widget.lessonId == 'new';

  bool get _hasDuration =>
      _lessonType == LessonType.video || _lessonType == LessonType.pdf;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _populateFromLesson(AdminLesson lesson) {
    if (_initialized) return;
    _initialized = true;
    _titleController.text = lesson.title;
    _descController.text = lesson.description;
    _lessonType = lesson.lessonType;
    _isPreviewed = lesson.isPreviewed;
    if (lesson.durationSeconds != null) {
      _durationController.text = lesson.durationSeconds.toString();
    }
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _titleError = _titleController.text.trim().isEmpty
          ? 'Title is required'
          : null;
      if (_titleError != null) valid = false;
    });
    return valid;
  }

  Future<void> _save(BuildContext context) async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminCourseRepositoryProvider);
      final sections =
          ref.read(adminCurriculumProvider(widget.courseId)).asData?.value ??
          [];
      final sectionId = sections.isNotEmpty
          ? sections.first.id
          : 'default-section';

      final durationText = _durationController.text.trim();
      final lesson = AdminLesson(
        id: _isNew
            ? 'lesson-${DateTime.now().millisecondsSinceEpoch}'
            : widget.lessonId,
        sectionId: sectionId,
        courseId: widget.courseId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        lessonType: _lessonType,
        sortOrder: 0,
        isPreviewed: _isPreviewed,
        durationSeconds: _hasDuration && durationText.isNotEmpty
            ? int.tryParse(durationText)
            : null,
      );
      await repo.upsertLesson(lesson);
      ref.invalidate(adminCurriculumProvider(widget.courseId));
      if (context.mounted) {
        AppSnackbar.show(
          context,
          _isNew ? 'Lesson created.' : 'Lesson updated.',
          variant: SnackbarVariant.success,
        );
        context.go('/admin/courses/${widget.courseId}/curriculum');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.show(
          context,
          adminDataError(e, 'Failed to save lesson.'),
          variant: SnackbarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isNew) {
      if (!_initialized) _initialized = true;
      return _buildForm(context);
    }

    final lessonAsync = ref.watch(
      adminLessonDetailProvider((
        courseId: widget.courseId,
        lessonId: widget.lessonId,
      )),
    );

    return lessonAsync.when(
      loading: _buildFormSkeleton,
      error: (e, _) => AppErrorState(
        message: adminDataError(e, 'Unable to load courses. Retry.'),
        actionLabel: 'Retry',
        onRetry: () => ref.invalidate(
          adminLessonDetailProvider((
            courseId: widget.courseId,
            lessonId: widget.lessonId,
          )),
        ),
      ),
      data: (lesson) {
        if (lesson != null) _populateFromLesson(lesson);
        return _buildForm(context);
      },
    );
  }

  Widget _buildFormSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(
          5,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppSkeleton(
              height: 56,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final maxWidth = MediaQuery.sizeOf(context).width >= AppBreakpoints.medium
        ? 640.0
        : double.infinity;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isNew ? 'New Lesson' : 'Edit Lesson',
                style: tt.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: 'Lesson Title',
                hint: 'e.g. Introduction to Widgets',
                controller: _titleController,
                errorText: _titleError,
                onChanged: (_) {
                  if (_titleError != null) setState(() => _titleError = null);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Description',
                hint: 'What will students learn in this lesson…',
                controller: _descController,
                maxLines: 4,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Lesson Type', style: tt.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              _buildLessonTypeSelector(context),
              const SizedBox(height: AppSpacing.md),
              if (_hasDuration) ...[
                AppTextField(
                  label: 'Duration (seconds)',
                  hint: 'e.g. 480',
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              SwitchListTile(
                title: const Text('Allow Free Preview'),
                subtitle: const Text(
                  'Students can view this lesson without enrolling',
                ),
                value: _isPreviewed,
                onChanged: (v) => setState(() => _isPreviewed = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildMediaUploadPlaceholder(context, cs, tt),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: 'Cancel',
                    onPressed: () => context.go(
                      '/admin/courses/${widget.courseId}/curriculum',
                    ),
                    variant: ButtonVariant.outlined,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  AppButton(
                    label: 'Save',
                    onPressed: _saving ? null : () => _save(context),
                    variant: ButtonVariant.primary,
                    isLoading: _saving,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonTypeSelector(BuildContext context) {
    return SegmentedButton<LessonType>(
      segments: const [
        ButtonSegment(
          value: LessonType.video,
          label: Text('Video'),
          icon: Icon(Icons.play_circle_outline),
        ),
        ButtonSegment(
          value: LessonType.pdf,
          label: Text('PDF'),
          icon: Icon(Icons.picture_as_pdf_outlined),
        ),
        ButtonSegment(
          value: LessonType.text,
          label: Text('Text'),
          icon: Icon(Icons.article_outlined),
        ),
        ButtonSegment(
          value: LessonType.quiz,
          label: Text('Quiz'),
          icon: Icon(Icons.quiz_outlined),
        ),
      ],
      selected: {_lessonType},
      onSelectionChanged: (s) => setState(() {
        _lessonType = s.first;
        if (!_hasDuration) _durationController.clear();
      }),
    );
  }

  Widget _buildMediaUploadPlaceholder(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
  ) {
    if (_lessonType == LessonType.pdf) {
      return _isNew
          ? const Text('Save the lesson before uploading its PDF.')
          : MediaUploadControl(
              courseId: widget.courseId,
              lessonId: widget.lessonId,
            );
    }
    final typeLabel = switch (_lessonType) {
      LessonType.video => 'Video',
      LessonType.pdf => 'PDF',
      LessonType.text => null,
      LessonType.quiz => null,
    };

    if (typeLabel == null) return const SizedBox.shrink();

    return Container(
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(
          color: cs.outlineVariant,
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: cs.surfaceContainerLow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _lessonType == LessonType.video
                ? Icons.upload_file_outlined
                : Icons.upload_file_outlined,
            size: 32,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Upload $typeLabel file',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'File upload requires backend integration', // TODO: Connect to Supabase storage upload
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
