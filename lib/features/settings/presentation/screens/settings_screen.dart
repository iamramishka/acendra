import 'package:acendra/app/providers/theme_mode_provider.dart';
import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/features/authentication/presentation/providers/logout_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Account settings (COM-022 / UI-ST-021). Language and email notifications
/// are intentionally absent until owner decisions D-4 / D-8 are made.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final isSigningOut = ref.watch(logoutProvider).isLoading;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Appearance', style: tt.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.settings_suggest_outlined),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).setMode(s.first),
            ),
            const SizedBox(height: 32),
            Text('Account & Security', style: tt.titleMedium),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              minTileHeight: 48,
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RouteNames.changePassword),
            ),
            const SizedBox(height: 24),
            Card(
              color: cs.errorContainer,
              child: InkWell(
                onTap: isSigningOut
                    ? null
                    : () async {
                        await ref.read(logoutProvider.notifier).logout();
                        if (!context.mounted) return;
                        if (ref.read(logoutProvider).hasError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not sign out. Please try again.',
                              ),
                            ),
                          );
                        } else {
                          context.go(RouteNames.login);
                        }
                      },
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: isSigningOut
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.error,
                          ),
                        )
                      : Icon(Icons.logout_rounded, color: cs.error),
                  title: Text(
                    'Sign out',
                    style: tt.bodyLarge?.copyWith(
                      color: cs.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: cs.error.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
