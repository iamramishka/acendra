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
    this.sectionId,
  });

  final String courseId;
  final String lessonId;
  final String? sectionId;

  @override
  ConsumerState<LessonEditorScreen> createState() => _LessonEditorScreenState();
}

class _LessonEditorScreenState extends ConsumerState<LessonEditorScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _durationController = TextEditingController();

  LessonType _lessonType = LessonType.video;
  bool _isPreviewed = false;
  bool _isPublished = false;
  AdminLesson? _original;
  String? _sectionId;
  int _sortOrder = 0;
  String _newLessonId = newAdminCourseId();
  AdminCourseRepository? _formRepository;
  String? _durationError;
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
    _original = lesson;
    _sectionId = lesson.sectionId;
    _sortOrder = lesson.sortOrder;
    _isPublished = lesson.isPublished;
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
      final duration = _durationController.text.trim();
      _durationError =
          _hasDuration &&
              duration.isNotEmpty &&
              (int.tryParse(duration) == null || int.parse(duration) < 0)
          ? 'Enter a non-negative whole number of seconds'
          : null;
      if (_titleError != null || _durationError != null) valid = false;
    });
    return valid;
  }

  bool _isCurrentRepository(AdminCourseRepository repository) {
    if (!mounted) return false;
    try {
      return identical(ref.read(adminCourseRepositoryProvider), repository);
    } catch (_) {
      return false;
    }
  }

  Future<void> _save(BuildContext context) async {
    if (_saving || !_validate()) return;
    setState(() => _saving = true);
    AdminCourseRepository? operationRepository;
    try {
      final repo = ref.read(adminCourseRepositoryProvider);
      operationRepository = repo;
      if (_sectionId == null) {
        throw const AdminDataException(
          'Choose an existing section before saving a lesson.',
        );
      }

      final durationText = _durationController.text.trim();
      final lesson = AdminLesson(
        id: _isNew ? _newLessonId : widget.lessonId,
        sectionId: _sectionId!,
        courseId: widget.courseId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        lessonType: _lessonType,
        sortOrder: _sortOrder,
        isPublished: _isPublished,
        rawCourseUpdatedAt:
            _original?.rawCourseUpdatedAt ??
            ref
                .read(adminCurriculumProvider(widget.courseId))
                .requireValue
                .where((s) => s.id == _sectionId)
                .firstOrNull
                ?.rawCourseUpdatedAt,
        isPreviewed: _isPreviewed,
        durationSeconds: _hasDuration && durationText.isNotEmpty
            ? int.tryParse(durationText)
            : null,
      );
      await repo.upsertLesson(lesson);
      if (!_isCurrentRepository(repo)) return;
      ref.invalidate(adminCurriculumProvider(widget.courseId));
      ref.invalidate(adminCourseDetailProvider(widget.courseId));
      if (context.mounted) {
        AppSnackbar.show(
          context,
          _isNew ? 'Lesson created.' : 'Lesson updated.',
          variant: SnackbarVariant.success,
        );
        context.go('/admin/courses/${widget.courseId}/curriculum');
      }
    } catch (e) {
      if (context.mounted &&
          operationRepository != null &&
          _isCurrentRepository(operationRepository)) {
        AppSnackbar.show(
          context,
          adminDataError(e, 'Failed to save lesson.'),
          variant: SnackbarVariant.error,
        );
      }
    } finally {
      if (mounted &&
          (operationRepository == null ||
              _isCurrentRepository(operationRepository))) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(adminCourseRepositoryProvider);
    if (!identical(repository, _formRepository)) {
      if (_formRepository != null) {
        _initialized = false;
        _saving = false;
        _original = null;
        _sectionId = null;
        _sortOrder = 0;
        _isPublished = false;
        _isPreviewed = false;
        _lessonType = LessonType.video;
        _newLessonId = newAdminCourseId();
        _titleController.clear();
        _descController.clear();
        _durationController.clear();
      }
      _formRepository = repository;
    }
    final curriculum = ref.watch(adminCurriculumProvider(widget.courseId));
    if (curriculum.isLoading) return _buildFormSkeleton();
    if (curriculum.hasError) {
      return AppErrorState(
        message: adminDataError(
          curriculum.error!,
          'Unable to load curriculum.',
        ),
        actionLabel: 'Retry',
        onRetry: () => ref.invalidate(adminCurriculumProvider(widget.courseId)),
      );
    }
    if (_isNew) {
      if (!_initialized) {
        _initialized = true;
        final sections = curriculum.requireValue;
        _sectionId =
            widget.sectionId ?? (sections.isEmpty ? null : sections.first.id);
        final selected = sections.where((section) => section.id == _sectionId);
        if (selected.isNotEmpty && selected.first.lessons.isNotEmpty) {
          _sortOrder =
              selected.first.lessons
                  .map((lesson) => lesson.sortOrder)
                  .reduce((a, b) => a > b ? a : b) +
              1;
        }
      }
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
        if (lesson == null) {
          return const AppErrorState(
            message: 'Lesson not found. Return to the curriculum.',
          );
        }
        _populateFromLesson(lesson);
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
              DropdownButtonFormField<String>(
                initialValue: _sectionId,
                decoration: const InputDecoration(labelText: 'Section'),
                items:
                    (ref
                                .watch(adminCurriculumProvider(widget.courseId))
                                .asData
                                ?.value ??
                            [])
                        .map(
                          (section) => DropdownMenuItem(
                            value: section.id,
                            child: Text(section.title),
                          ),
                        )
                        .toList(),
                onChanged: _original != null
                    ? null
                    : (id) => setState(() {
                        _sectionId = id;
                        final lessons = ref
                            .read(adminCurriculumProvider(widget.courseId))
                            .requireValue
                            .firstWhere((s) => s.id == id)
                            .lessons;
                        _sortOrder = lessons.isEmpty
                            ? 0
                            : lessons
                                      .map((l) => l.sortOrder)
                                      .reduce((a, b) => a > b ? a : b) +
                                  1;
                      }),
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
                  errorText: _durationError,
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
              SwitchListTile(
                title: const Text('Published lesson'),
                value: _isPublished,
                onChanged: (v) => setState(() => _isPublished = v),
                contentPadding: EdgeInsets.zero,
              ),
              const Text(
                'Descriptions are public metadata. Do not enter paid lesson content here.',
              ),
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
    return DropdownButtonFormField<LessonType>(
      initialValue: _lessonType,
      decoration: const InputDecoration(labelText: 'Lesson type'),
      items: const [
        DropdownMenuItem(value: LessonType.video, child: Text('Video')),
        DropdownMenuItem(value: LessonType.pdf, child: Text('PDF')),
        DropdownMenuItem(value: LessonType.text, child: Text('Text')),
        DropdownMenuItem(value: LessonType.image, child: Text('Image')),
      ],
      onChanged: (value) => setState(() {
        _lessonType = value!;
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
      LessonType.image => null,
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
