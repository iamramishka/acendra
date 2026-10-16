import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_skeleton.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/core/widgets/feedback/status_badge.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:acendra/core/widgets/layout/responsive_container.dart';
import 'package:acendra/features/admin/domain/entities/admin_student.dart';
import 'package:acendra/features/admin/presentation/providers/admin_students_provider.dart';
import 'package:acendra/features/admin/presentation/widgets/students/student_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminStudentsScreen extends ConsumerStatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  ConsumerState<AdminStudentsScreen> createState() =>
      _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends ConsumerState<AdminStudentsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(adminStudentsProvider.notifier).search(query);
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(adminStudentsProvider);
    final tt = Theme.of(context).textTheme;
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.medium;

    return ResponsiveContainer(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.lg,
                bottom: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Students', style: tt.headlineMedium),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _searchController,
                    hint: 'Search by name or email…',
                    onChanged: _onSearch,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
          ),
          studentsAsync.when(
            loading: () => SliverList(
              delegate: SliverChildListDelegate([const _LoadingSkeleton()]),
            ),
            error: (e, _) => SliverFillRemaining(
              child: AppErrorState(
                message: 'Failed to load students.',
                actionLabel: 'Retry',
                onRetry: () =>
                    ref.read(adminStudentsProvider.notifier).refresh(),
              ),
            ),
            data: (students) {
              if (students.isEmpty) {
                return const SliverFillRemaining(
                  child: AppEmptyState(message: 'No students found.'),
                );
              }
              return SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        '${students.length} student${students.length == 1 ? '' : 's'}',
                        style: tt.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    isWide
                        ? _StudentsDataTable(students: students)
                        : _StudentsCardList(students: students),
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
}

class _StudentsCardList extends StatelessWidget {
  const _StudentsCardList({required this.students});

  final List<AdminStudent> students;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: students
          .map(
            (s) => StudentListCard(
              key: ValueKey(s.id),
              student: s,
              onViewDetails: () => context.go('/admin/students/${s.id}'),
            ),
          )
          .toList(),
    );
  }
}

class _StudentsDataTable extends StatelessWidget {
  const _StudentsDataTable({required this.students});

  final List<AdminStudent> students;

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Student')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Courses'), numeric: true),
            DataColumn(label: Text('Amount Paid'), numeric: true),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: students.map((s) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: cs.primaryContainer,
                        child: Text(
                          _initials(s),
                          style: tt.labelSmall?.copyWith(
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(s.displayName ?? '—'),
                    ],
                  ),
                ),
                DataCell(Text(s.email)),
                DataCell(Text('${s.enrolledCourseCount}')),
                DataCell(
                  Text('${s.currency} ${s.totalAmountPaid.toStringAsFixed(0)}'),
                ),
                DataCell(
                  StatusBadge(
                    label: s.isActive ? 'Active' : 'Inactive',
                    variant: s.isActive
                        ? BadgeVariant.success
                        : BadgeVariant.warning,
                  ),
                ),
                DataCell(
                  AppButton(
                    label: 'View Details',
                    onPressed: () => context.go('/admin/students/${s.id}'),
                    variant: ButtonVariant.secondary,
                    size: ButtonSize.small,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
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
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSkeleton(
                          width: 140,
                          height: 14,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppSkeleton(
                          width: 200,
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
