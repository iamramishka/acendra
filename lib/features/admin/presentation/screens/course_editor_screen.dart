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
  final _thumbnailController = TextEditingController();

  String _currency = 'LKR';
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
    _thumbnailController.dispose();
    super.dispose();
  }

  void _populateFromCourse(AdminCourse course) {
    if (_initialized) return;
    _initialized = true;
    _titleController.text = course.title;
    _descController.text = course.description;
    _priceController.text = course.price.toStringAsFixed(0);
    _thumbnailController.text = course.thumbnailUrl ?? '';
    _currency = course.currency;
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
      } else if (double.tryParse(priceText) == null) {
        _priceError = 'Enter a valid number';
        valid = false;
      } else {
        _priceError = null;
      }
      if (_titleError != null) valid = false;
    });
    return valid;
  }

  Future<void> _save(BuildContext context) async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminCourseRepositoryProvider);
      final now = DateTime.now();
      final course = AdminCourse(
        id: _isNew ? 'course-${now.millisecondsSinceEpoch}' : widget.courseId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        currency: _currency,
        isPublished: _isPublished,
        thumbnailUrl: _thumbnailController.text.trim().isEmpty
            ? null
            : _thumbnailController.text.trim(),
        enrollmentCount: 0,
        sectionCount: 0,
        lessonCount: 0,
        createdAt: now,
        updatedAt: now,
      );
      if (_isNew) {
        await repo.createCourse(course);
      } else {
        await repo.updateCourse(course);
      }
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
      if (context.mounted) {
        AppSnackbar.show(
          context,
          'Failed to save course.',
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

    final courseAsync = ref.watch(adminCourseDetailProvider(widget.courseId));
    return courseAsync.when(
      loading: () => _buildFormSkeleton(),
      error: (e, _) => AppErrorState(
        message: e.toString(),
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
                      initialValue: _currency,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      items: const [
                        DropdownMenuItem(value: 'LKR', child: Text('LKR')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                      ],
                      onChanged: (v) => setState(() => _currency = v ?? 'LKR'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Thumbnail URL (optional)',
                hint: 'https://…',
                controller: _thumbnailController,
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                title: const Text('Published'),
                subtitle: const Text('Make this course visible to students'),
                value: _isPublished,
                onChanged: (v) => setState(() => _isPublished = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: 'Cancel',
                    onPressed: () => context.go('/admin/courses'),
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
