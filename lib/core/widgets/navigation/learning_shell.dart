import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/core/widgets/buttons/theme_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LearningShell extends ConsumerWidget {
  const LearningShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.myCourses),
        ),
        title: Text('Learning', style: Theme.of(context).textTheme.titleMedium),
        actions: const [ThemeToggleButton()],
      ),
      body: child,
    );
  }
}
