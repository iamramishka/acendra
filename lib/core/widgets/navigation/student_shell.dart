import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/core/widgets/layout/responsive_container.dart';
import 'package:acendra/core/widgets/navigation/account_menu.dart';
import 'package:acendra/features/authentication/presentation/providers/navigation_access_provider.dart';
import 'package:acendra/features/dashboard/presentation/dashboard_copy.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StudentShell extends ConsumerWidget {
  const StudentShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompact =
        MediaQuery.sizeOf(context).width < AppBreakpoints.medium ||
        MediaQuery.textScalerOf(context).scale(14) > 21;
    final canOpenAdmin =
        ref.watch(navigationAccessProvider).asData?.value ?? false;
    String location;
    try {
      location = GoRouterState.of(context).matchedLocation;
    } catch (_) {
      location = '/';
    }

    int selectedIndex;
    if (location == RouteNames.marketplace ||
        location.startsWith('${RouteNames.marketplace}/')) {
      selectedIndex = 1;
    } else if (location == RouteNames.myCourses ||
        location.startsWith('${RouteNames.myCourses}/')) {
      selectedIndex = 2;
    } else if (location == RouteNames.profile ||
        location.startsWith('${RouteNames.profile}/') ||
        location == RouteNames.orders ||
        location.startsWith('${RouteNames.orders}/') ||
        location == RouteNames.settings ||
        location.startsWith('${RouteNames.settings}/')) {
      selectedIndex = 3;
    } else {
      selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 28,
                width: 28,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: 8),
              Text(
                DashboardCopy.brand,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (!isCompact) ...[
            TextButton(
              onPressed: () => context.go(RouteNames.dashboardHome),
              child: const Text(DashboardCopy.home),
            ),
            TextButton(
              onPressed: () => context.go(RouteNames.marketplace),
              child: const Text(DashboardCopy.explore),
            ),
            TextButton(
              onPressed: () => context.go(RouteNames.myCourses),
              child: const Text(DashboardCopy.myCourses),
            ),
            if (canOpenAdmin)
              TextButton(
                onPressed: () => context.go(RouteNames.admin),
                child: const Text('Admin'),
              ),
          ],
          IconButton(
            tooltip: DashboardCopy.searchCourses,
            icon: const Icon(Icons.search_outlined),
            onPressed: () {
              ref.read(marketplaceSearchRequestProvider.notifier).state++;
              context.go(
                Uri(
                  path: RouteNames.marketplace,
                  queryParameters: const {'search': 'true'},
                ).toString(),
              );
            },
          ),
          const SizedBox(width: 8),
          const AccountMenu(icon: Icon(Icons.menu)),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: isCompact
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                const destinations = [
                  RouteNames.dashboardHome,
                  RouteNames.marketplace,
                  RouteNames.myCourses,
                  RouteNames.profile,
                ];
                context.go(destinations[index]);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: DashboardCopy.home,
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: DashboardCopy.explore,
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: DashboardCopy.myCourses,
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: DashboardCopy.profile,
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
