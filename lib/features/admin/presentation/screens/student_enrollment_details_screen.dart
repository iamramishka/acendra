import 'package:acendra/features/admin/data/repositories/admin_directory_client.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/dialogs/app_dialog.dart';
import 'package:acendra/core/widgets/feedback/app_skeleton.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:acendra/core/widgets/layout/responsive_container.dart';
import 'package:acendra/features/admin/data/repositories/admin_student_repository.dart';
import 'package:acendra/features/admin/domain/entities/student_enrollment.dart';
import 'package:acendra/features/admin/presentation/providers/admin_students_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StudentEnrollmentDetailsScreen extends ConsumerStatefulWidget {
  const StudentEnrollmentDetailsScreen({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<StudentEnrollmentDetailsScreen> createState() =>
      _StudentEnrollmentDetailsScreenState();
}

class _StudentEnrollmentDetailsScreenState
    extends ConsumerState<StudentEnrollmentDetailsScreen> {
  final _courseIdController = TextEditingController();
  bool _isDeactivating = false;
  bool _isGranting = false;

  @override
  void dispose() {
    _courseIdController.dispose();
    super.dispose();
  }

  String _initials(String email, String? displayName) {
    final name = displayName ?? email;
    final parts = name
        .split(RegExp(r'[\s@]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  Future<void> _confirmDeactivate() async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Deactivate Student',
      body:
          'This will deactivate the student account. They will no longer be able to sign in. Are you sure?',
      confirmLabel: 'Deactivate',
      cancelLabel: 'Cancel',
      confirmVariant: ButtonVariant.destructive,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeactivating = true);
    try {
      await ref
          .read(adminStudentRepositoryProvider)
          .deactivateStudent(widget.studentId);
      if (!mounted) return;
      ref.invalidate(studentDetailProvider(widget.studentId));
      AppSnackbar.show(
        context,
        'Student account deactivated.',
        variant: SnackbarVariant.success,
      );
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          adminDataError(e, 'Failed to deactivate student. Please try again.'),
          variant: SnackbarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isDeactivating = false);
    }
  }

  Future<void> _revokeEnrollment(StudentEnrollment enrollment) async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Revoke Enrollment',
      body:
          'Revoke access to "${enrollment.courseTitle}"? The student will lose access immediately.',
      confirmLabel: 'Revoke',
      cancelLabel: 'Cancel',
      confirmVariant: ButtonVariant.destructive,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(adminStudentRepositoryProvider)
          .revokeEnrollment(enrollment.id);
      if (!mounted) return;
      ref.invalidate(studentEnrollmentsProvider(widget.studentId));
      AppSnackbar.show(
        context,
        'Enrollment revoked.',
        variant: SnackbarVariant.success,
      );
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          adminDataError(e, 'Failed to revoke enrollment. Please try again.'),
          variant: SnackbarVariant.error,
        );
      }
    }
  }

  Future<void> _grantEnrollment() async {
    final courseId = _courseIdController.text.trim();
    if (courseId.isEmpty) {
      AppSnackbar.show(
        context,
        'Please enter a course ID.',
        variant: SnackbarVariant.warning,
      );
      return;
    }

    setState(() => _isGranting = true);
    try {
      // TODO: Connect to real course lookup before granting
      await ref
          .read(adminStudentRepositoryProvider)
          .grantEnrollment(widget.studentId, courseId);
      if (!mounted) return;
      _courseIdController.clear();
      ref.invalidate(studentEnrollmentsProvider(widget.studentId));
      ref.invalidate(studentDetailProvider(widget.studentId));
      AppSnackbar.show(
        context,
        'Enrollment granted successfully.',
        variant: SnackbarVariant.success,
      );
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          adminDataError(e, 'Failed to grant enrollment. Please try again.'),
          variant: SnackbarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isGranting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(studentDetailProvider(widget.studentId));
    final enrollmentsAsync = ref.watch(
      studentEnrollmentsProvider(widget.studentId),
    );
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return ResponsiveContainer(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.lg,
                bottom: AppSpacing.md,
              ),
              child: AppButton(
                label: '← Back to Students',
                onPressed: () => context.go('/admin/students'),
                variant: ButtonVariant.outlined,
                size: ButtonSize.small,
              ),
            ),
          ),
          studentAsync.when(
            loading: () => SliverToBoxAdapter(child: _ProfileSkeleton()),
            error: (e, _) => SliverFillRemaining(
              child: AppErrorState(
                message: adminDataError(e, 'Failed to load student profile.'),
                actionLabel: 'Retry',
                onRetry: () =>
                    ref.invalidate(studentDetailProvider(widget.studentId)),
              ),
            ),
            data: (student) => SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: cs.primaryContainer,
                            child: Text(
                              _initials(student.email, student.displayName),
                              style: tt.titleLarge?.copyWith(
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (student.displayName != null)
                                  Text(
                                    student.displayName!,
                                    style: tt.titleLarge,
                                  ),
                                Text(
                                  student.email,
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Joined ${_formatDate(student.createdAt)}',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                StatusBadge(
                                  label: student.isActive
                                      ? 'Active'
                                      : 'Inactive',
                                  variant: student.isActive
                                      ? BadgeVariant.success
                                      : BadgeVariant.warning,
                                ),
                              ],
                            ),
                          ),
                          if (student.isActive)
                            AppButton(
                              label: 'Deactivate',
                              onPressed: _isDeactivating
                                  ? null
                                  : _confirmDeactivate,
                              variant: ButtonVariant.destructive,
                              size: ButtonSize.small,
                              isLoading: _isDeactivating,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          enrollmentsAsync.when(
            loading: () => SliverToBoxAdapter(child: _EnrollmentsSkeleton()),
            error: (e, _) => SliverToBoxAdapter(
              child: AppErrorState(
                message: adminDataError(e, 'Failed to load enrollments.'),
                actionLabel: 'Retry',
                onRetry: () => ref.invalidate(
                  studentEnrollmentsProvider(widget.studentId),
                ),
              ),
            ),
            data: (enrollments) {
              final avgProgress = enrollments.isEmpty
                  ? 0
                  : (enrollments
                            .map((e) => e.progressPercent)
                            .reduce((a, b) => a + b) ~/
                        enrollments.length);
              final totalPaid = enrollments.fold<double>(
                0,
                (sum, e) => sum + e.amountPaid,
              );
              return SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatRow(
                      enrolledCount: enrollments.length,
                      totalPaid: totalPaid,
                      avgProgress: avgProgress,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _GrantEnrollmentSection(
                      controller: _courseIdController,
                      isLoading: _isGranting,
                      onGrant: _grantEnrollment,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Enrollments', style: tt.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    if (enrollments.isEmpty)
                      const AppEmptyState(
                        message: 'No enrollments found for this student.',
                      )
                    else
                      ...enrollments.map(
                        (e) => _EnrollmentCard(
                          key: ValueKey(e.id),
                          enrollment: e,
                          onRevoke: e.status == EnrollmentStatus.active
                              ? () => _revokeEnrollment(e)
                              : null,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.enrolledCount,
    required this.totalPaid,
    required this.avgProgress,
  });

  final int enrolledCount;
  final double totalPaid;
  final int avgProgress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: 'Enrolled Courses',
            value: '$enrolledCount',
            icon: Icons.school_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatBox(
            label: 'Total Paid',
            value: 'LKR ${totalPaid.toStringAsFixed(0)}',
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatBox(
            label: 'Avg Progress',
            value: '$avgProgress%',
            icon: Icons.trending_up,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: tt.titleMedium),
            Text(
              label,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrantEnrollmentSection extends StatelessWidget {
  const _GrantEnrollmentSection({
    required this.controller,
    required this.isLoading,
    required this.onGrant,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grant Enrollment', style: tt.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AppTextField(
                    controller: controller,
                    label: 'Course ID',
                    hint: 'Enter course ID to grant access',
                    enabled: !isLoading,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  label: 'Grant Access',
                  onPressed: isLoading ? null : onGrant,
                  variant: ButtonVariant.primary,
                  size: ButtonSize.medium,
                  isLoading: isLoading,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrollmentCard extends StatelessWidget {
  const _EnrollmentCard({super.key, required this.enrollment, this.onRevoke});

  final StudentEnrollment enrollment;
  final VoidCallback? onRevoke;

  BadgeVariant _statusBadgeVariant(EnrollmentStatus status) => switch (status) {
    EnrollmentStatus.active => BadgeVariant.success,
    EnrollmentStatus.expired => BadgeVariant.warning,
    EnrollmentStatus.revoked => BadgeVariant.error,
  };

  String _statusLabel(EnrollmentStatus status) => switch (status) {
    EnrollmentStatus.active => 'Active',
    EnrollmentStatus.expired => 'Expired',
    EnrollmentStatus.revoked => 'Revoked',
  };

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.menu_book_outlined,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enrollment.courseTitle,
                        style: tt.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Enrolled ${_formatDate(enrollment.enrolledAt)}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                StatusBadge(
                  label: _statusLabel(enrollment.status),
                  variant: _statusBadgeVariant(enrollment.status),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _PaymentMethodChip(method: enrollment.paymentMethod),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${enrollment.currency} ${enrollment.amountPaid.toStringAsFixed(0)}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress: ${enrollment.progressPercent}%',
                        style: tt.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      LinearProgressIndicator(
                        value: enrollment.progressPercent / 100,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                    ],
                  ),
                ),
                if (onRevoke != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  AppButton(
                    label: 'Revoke',
                    onPressed: onRevoke,
                    variant: ButtonVariant.destructive,
                    size: ButtonSize.small,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  const _PaymentMethodChip({required this.method});

  final String method;

  String _label(String method) => switch (method) {
    'stripe' => 'Card',
    'bank_transfer' => 'Bank Transfer',
    'admin_grant' => 'Admin Grant',
    _ => method,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        _label(method),
        style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            AppSkeleton(
              width: 64,
              height: 64,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton(
                    width: 160,
                    height: 16,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppSkeleton(
                    width: 220,
                    height: 13,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppSkeleton(
                    width: 60,
                    height: 22,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrollmentsSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  AppSkeleton(
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSkeleton(
                          width: 180,
                          height: 14,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppSkeleton(
                          width: 120,
                          height: 12,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
