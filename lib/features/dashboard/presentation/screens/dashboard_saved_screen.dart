import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/features/dashboard/presentation/dashboard_copy.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Explicit future-feature destination; does not imply saved-course storage.
class DashboardSavedScreen extends StatelessWidget {
  const DashboardSavedScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              DashboardCopy.savedComingSoon,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(DashboardCopy.savedExplanation),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => context.go(RouteNames.marketplace),
            child: const Text(DashboardCopy.exploreCourses),
          ),
        ],
      ),
    ),
  );
}
