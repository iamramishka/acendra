import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/buttons/theme_toggle_button.dart';
import 'package:acendra/core/widgets/layout/responsive_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PublicShell extends ConsumerWidget {
  const PublicShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AppBreakpoints.compact;
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final borderColor = ext?.border ?? Theme.of(context).dividerColor;
    final surface = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: borderColor),
        ),
        title: Text(
          'Acedra',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: isMobile
            ? [
                const ThemeToggleButton(),
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                  ),
                ),
              ]
            : [
                TextButton(
                  onPressed: () => context.go(RouteNames.marketplace),
                  child: const Text('Courses'),
                ),
                TextButton(
                  onPressed: () => context.go(RouteNames.login),
                  child: const Text('Sign in'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => context.go(RouteNames.register),
                  child: const Text('Get Started'),
                ),
                const SizedBox(width: 8),
                const ThemeToggleButton(),
                const SizedBox(width: 8),
              ],
      ),
      endDrawer: isMobile
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(child: Text('Acedra')),
                  ListTile(
                    title: const Text('Courses'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(RouteNames.marketplace);
                    },
                  ),
                  ListTile(
                    title: const Text('Sign in'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(RouteNames.login);
                    },
                  ),
                  ListTile(
                    title: const Text('Get Started'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(RouteNames.register);
                    },
                  ),
                ],
              ),
            )
          : null,
      body: Column(
        children: [
          Expanded(child: ResponsiveContainer(child: child)),
        ],
      ),
    );
  }
}
