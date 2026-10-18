import 'package:acendra/app/providers/theme_mode_provider.dart';
import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/features/authentication/presentation/providers/logout_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Only preferences with working application behavior are exposed here.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Settings'),
      leading: BackButton(onPressed: () => context.go(RouteNames.profile)),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.light, label: Text('Light')),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ButtonSegment(value: ThemeMode.system, label: Text('System')),
          ],
          selected: {ref.watch(themeModeProvider)},
          onSelectionChanged: (values) =>
              ref.read(themeModeProvider.notifier).setMode(values.single),
        ),
        const SizedBox(height: 24),
        Text(
          'Account & Security',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Change Password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('${RouteNames.resetPassword}?mode=change'),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign Out'),
          onTap: ref.watch(logoutProvider).isLoading
              ? null
              : () => ref.read(logoutProvider.notifier).logout(),
        ),
      ],
    ),
  );
}
