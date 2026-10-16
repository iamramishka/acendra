import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:acendra/features/admin/domain/entities/admin_student.dart';
import 'package:flutter/material.dart';

class StudentListCard extends StatelessWidget {
  const StudentListCard({
    super.key,
    required this.student,
    required this.onViewDetails,
  });

  final AdminStudent student;
  final VoidCallback onViewDetails;

  String _initials(AdminStudent s) {
    final name = s.displayName ?? s.email;
    final parts = name
        .split(RegExp(r'[\s@]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: cs.primaryContainer,
              child: Text(
                _initials(student),
                style: tt.titleMedium?.copyWith(color: cs.onPrimaryContainer),
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
                      style: tt.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    student.email,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _InfoChip(
                        label: '${student.enrolledCourseCount} courses',
                        icon: Icons.school_outlined,
                      ),
                      _InfoChip(
                        label:
                            '${student.currency} ${student.totalAmountPaid.toStringAsFixed(0)}',
                        icon: Icons.payments_outlined,
                      ),
                      StatusBadge(
                        label: student.isActive ? 'Active' : 'Inactive',
                        variant: student.isActive
                            ? BadgeVariant.success
                            : BadgeVariant.warning,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton(
              label: 'View Details',
              onPressed: onViewDetails,
              variant: ButtonVariant.secondary,
              size: ButtonSize.small,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}
