import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/buttons/theme_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  Widget _buildSidebar(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final sidebarBg =
        ext?.surfaceSecondary ??
        Theme.of(context).colorScheme.surfaceContainerHighest;
    final borderColor = ext?.border ?? Theme.of(context).dividerColor;
    String matchedLocation;
    try {
      matchedLocation = GoRouterState.of(context).matchedLocation;
    } catch (_) {
      matchedLocation = '/';
    }

    return Container(
      width: AppBreakpoints.adminSidebarWidth,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acedra',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Admin',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        ext?.textSecondary ??
                        Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          _AdminNavItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            route: '/admin',
            isActive:
                matchedLocation.startsWith('/admin') &&
                !matchedLocation.startsWith('/admin/'),
          ),
          _AdminNavItem(
            icon: Icons.school_outlined,
            label: 'Courses',
            route: '/admin/courses',
            isActive: matchedLocation.startsWith('/admin/courses'),
          ),
          _AdminNavItem(
            icon: Icons.people_outlined,
            label: 'Students',
            route: '/admin/students',
            isActive: matchedLocation.startsWith('/admin/students'),
          ),
          _AdminNavItem(
            icon: Icons.payments_outlined,
            label: 'Payments',
            route: '/admin/payments',
            isActive: matchedLocation.startsWith('/admin/payments'),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: ThemeToggleButton(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AppBreakpoints.compact;

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin'),
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        drawer: Drawer(child: SafeArea(child: _buildSidebar(context))),
        body: child,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(context),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  const _AdminNavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor =
        ext?.textSecondary ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final activeBg =
        ext?.surfaceTertiary ??
        Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? activeColor : inactiveColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isActive ? activeColor : inactiveColor,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
