import 'dart:convert';
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
import 'package:acendra/features/admin/domain/entities/admin_course.dart';
import 'package:acendra/features/admin/presentation/providers/admin_courses_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CourseEditorScreen extends ConsumerStatefulWidget {
  const CourseEditorScreen({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends ConsumerState<CourseEditorScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  final _slugController = TextEditingController();
  final _summaryController = TextEditingController();
  String? _categoryId;
  AdminCourse? _original;
  String _newCourseId = newAdminCourseId();
  AdminCourseRepository? _formRepository;
  String? _savedMetadata;
  bool _created = false;
  bool _persistedPublished = false;
  bool _isPublished = false;
  bool _saving = false;
  bool _initialized = false;

  String? _titleError;
  String? _priceError;

  bool get _isNew => widget.courseId == 'new';

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _slugController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  void _populateFromCourse(AdminCourse course) {
    if (_initialized) return;
    _initialized = true;
    _titleController.text = course.title;
    _descController.text = course.description;
    _original = course;
    _priceController.text = adminCoursePriceText(
      course.priceMinor ??
          adminCoursePriceMinor(course.price.toStringAsFixed(2))!,
    );
    _slugController.text = course.slug;
    _summaryController.text = course.shortDescription;
    _categoryId = course.categoryId;
    _persistedPublished = course.isPublished;
    _isPublished = course.isPublished;
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _titleError = _titleController.text.trim().isEmpty
          ? 'Title is required'
          : null;
      final priceText = _priceController.text.trim();
      if (priceText.isEmpty) {
        _priceError = 'Price is required';
        valid = false;
      } else if (adminCoursePriceMinor(priceText) == null) {
        _priceError =
            'Use a non-negative price with at most two decimal places';
        valid = false;
      } else {
        _priceError = null;
      }
      if (_titleError != null) valid = false;
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
    var publicationAttempted = false;
    AdminCourseRepository? operationRepository;
    try {
      final repo = ref.read(adminCourseRepositoryProvider);
      operationRepository = repo;
      final now = DateTime.now();
      final course = AdminCourse(
        id: _isNew ? _newCourseId : widget.courseId,
        slug: _slugController.text.trim(),
        categoryId: _categoryId,
        shortDescription: _summaryController.text.trim(),
        priceMinor: adminCoursePriceMinor(_priceController.text)!,
        rawUpdatedAt: _original?.rawUpdatedAt,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        currency: 'LKR',
        isPublished: _persistedPublished,
        enrollmentCount: 0,
        sectionCount: 0,
        lessonCount: 0,
        createdAt: now,
        updatedAt: now,
      );
      final signature = jsonEncode([
        course.title,
        course.slug,
        course.categoryId,
        course.shortDescription,
        course.description,
        course.priceMinor,
      ]);
      if (_savedMetadata != signature) {
        if (_isNew && !_created) {
          await repo.createCourse(course);
          if (!_isCurrentRepository(repo)) return;
          _created = true;
        } else {
          await repo.updateCourse(course);
          if (!_isCurrentRepository(repo)) return;
        }
        if (repo is AdminCourseMutationRevisions) {
          _original = (_original ?? course).copyWith(
            rawUpdatedAt: (repo as AdminCourseMutationRevisions)
                .ownMutationRevision(course.id),
          );
        }
        _savedMetadata = signature;
      }
      if (_isPublished != _persistedPublished) {
        publicationAttempted = true;
        if (_isPublished) {
          await repo.publishCourse(
            course.id,
            expectedUpdatedAt: _original?.rawUpdatedAt,
          );
        } else {
          await repo.unpublishCourse(
            course.id,
            expectedUpdatedAt: _original?.rawUpdatedAt,
          );
        }
        if (!_isCurrentRepository(repo)) return;
        _persistedPublished = _isPublished;
      }
      ref.invalidate(adminCourseDetailProvider(course.id));
      ref.invalidate(adminCoursesProvider);
      if (context.mounted) {
        AppSnackbar.show(
          context,
          _isNew ? 'Course created.' : 'Course updated.',
          variant: SnackbarVariant.success,
        );
        context.go('/admin/courses');
      }
    } catch (e) {
      if (context.mounted &&
          operationRepository != null &&
          _isCurrentRepository(operationRepository)) {
        AppSnackbar.show(
          context,
          publicationAttempted
              ? 'Course details saved. ${adminDataError(e, 'Unable to change publication. Retry.')}'
              : adminDataError(e, 'Failed to save course.'),
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
        _created = false;
        _savedMetadata = null;
        _original = null;
        _categoryId = null;
        _isPublished = false;
        _persistedPublished = false;
        _newCourseId = newAdminCourseId();
        _titleController.clear();
        _descController.clear();
        _priceController.clear();
        _slugController.clear();
        _summaryController.clear();
      }
      _formRepository = repository;
    }
    if (_isNew) {
      if (!_initialized) _initialized = true;
      return _buildForm(context);
    }

    final courseAsync = ref.watch(adminCourseDetailProvider(widget.courseId));
    return courseAsync.when(
      loading: () => _buildFormSkeleton(),
      error: (e, _) => AppErrorState(
        message: adminDataError(e, 'Unable to load courses. Retry.'),
        actionLabel: 'Retry',
        onRetry: () =>
            ref.invalidate(adminCourseDetailProvider(widget.courseId)),
      ),
      data: (course) {
        _populateFromCourse(course);
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
                _isNew ? 'New Course' : 'Edit Course',
                style: tt.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: 'Course Title',
                hint: 'e.g. Flutter for Beginners',
                controller: _titleController,
                errorText: _titleError,
                onChanged: (_) {
                  if (_titleError != null) setState(() => _titleError = null);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Description',
                hint: 'Describe what students will learn…',
                controller: _descController,
                maxLines: 5,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Price',
                      hint: '0',
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      errorText: _priceError,
                      onChanged: (_) {
                        if (_priceError != null) {
                          setState(() => _priceError = null);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 120,
                    child: DropdownButtonFormField<String>(
                      initialValue: 'LKR',
                      decoration: const InputDecoration(labelText: 'Currency'),
                      items: const [
                        DropdownMenuItem(value: 'LKR', child: Text('LKR')),
                      ],
                      onChanged: null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Course slug',
                hint: 'course-web-address',
                controller: _slugController,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Short description',
                controller: _summaryController,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              if (_original != null) ...[
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('No category'),
                    ),
                    if (_categoryId != null &&
                        !_original!.categories.containsKey(_categoryId))
                      DropdownMenuItem<String>(
                        value: _categoryId,
                        enabled: false,
                        child: const Text(
                          'Current category (inactive or unavailable)',
                        ),
                      ),
                    ..._original!.categories.entries.map(
                      (c) =>
                          DropdownMenuItem(value: c.key, child: Text(c.value)),
                    ),
                  ],
                  onChanged: (id) => setState(() => _categoryId = id),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (!_isNew)
                MediaUploadControl(courseId: widget.courseId)
              else
                const Text('Save the course before uploading artwork.'),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                title: const Text('Published'),
                subtitle: const Text('Make this course visible to students'),
                value: _isPublished,
                onChanged: (v) => setState(() => _isPublished = v),
                contentPadding: EdgeInsets.zero,
              ),
              if (_created)
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => context.go(
                          '/admin/courses/$_newCourseId/curriculum',
                        ),
                  child: const Text('Edit saved course curriculum'),
                ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: 'Cancel',
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/admin/courses');
                      }
                    },
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
}
