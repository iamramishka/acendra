import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:acendra/features/marketplace/presentation/widgets/course_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(marketplaceProvider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => AppErrorState(
        message: 'Failed to load courses. Please try again.',
        actionLabel: 'Retry',
        onRetry: () => ref.read(marketplaceProvider.notifier).refresh(),
      ),
      data: (courses) {
        if (courses.isEmpty) {
          return const AppEmptyState(message: 'No courses available yet.');
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: CourseGrid(courses: courses),
        );
      },
    );
  }
}
