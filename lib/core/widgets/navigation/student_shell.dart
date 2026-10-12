import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/core/widgets/buttons/theme_toggle_button.dart';
import 'package:acendra/core/widgets/layout/responsive_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StudentShell extends ConsumerWidget {
  const StudentShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompact = MediaQuery.of(context).size.width < 600;
    String location;
    try {
      location = GoRouterState.of(context).matchedLocation;
    } catch (_) {
      location = '/';
    }

    int selectedIndex;
    if (location.startsWith('/dashboard')) {
      selectedIndex = 0;
    } else if (location.startsWith('/marketplace')) {
      selectedIndex = 1;
    } else {
      selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Acedra',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
          if (!isCompact) ...[
            TextButton(
              onPressed: () => context.go(RouteNames.myCourses),
              child: const Text('My Courses'),
            ),
            TextButton(
              onPressed: () => context.go(RouteNames.marketplace),
              child: const Text('Explore'),
            ),
          ],
          const ThemeToggleButton(),
          const SizedBox(width: 8),
          const CircleAvatar(radius: 16, child: Text('S')),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: isCompact
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                if (index == 0) {
                  context.go(RouteNames.myCourses);
                } else {
                  context.go(RouteNames.marketplace);
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.school_outlined),
                  label: 'My Courses',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  label: 'Explore',
                ),
              ],
            )
          : null,
      // Routed pages own their scrolling and may contain a Scaffold. Keep
      // their viewport bounded instead of nesting it in a scroll view.
      body: ResponsiveContainer(child: child),
    );
  }
}
