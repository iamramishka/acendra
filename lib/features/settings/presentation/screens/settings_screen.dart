import 'package:acendra/app/providers/theme_mode_provider.dart';
import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/features/authentication/presentation/providers/logout_provider.dart';
import 'package:acendra/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Account settings (COM-022 / UI-ST-021).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final isSigningOut = ref.watch(logoutProvider).isLoading;
    final prefsAsync = ref.watch(userPreferencesProvider);
    final isSavingLocale = ref.watch(localeUpdateProvider).isLoading;
    final isSavingNotif = ref.watch(emailNotificationsProvider).isLoading;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final selectedLocale = prefsAsync.asData?.value.locale ?? 'en';
    final emailEnabled =
        prefsAsync.asData?.value.emailNotificationsEnabled ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Appearance ─────────────────────────────────────────────────
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

            // ── Preferences ─────────────────────────────────────────────────
            Text('Preferences', style: tt.titleMedium),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              minTileHeight: 48,
              leading: const Icon(Icons.language_outlined),
              title: const Text('Language'),
              trailing: prefsAsync.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : DropdownButton<String>(
                      value: selectedLocale,
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      onChanged: isSavingLocale
                          ? null
                          : (v) => ref
                                .read(localeUpdateProvider.notifier)
                                .setLocale(v),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'si', child: Text('සිංහල')),
                      ],
                    ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.email_outlined),
              title: const Text('Email notifications'),
              value: emailEnabled,
              onChanged: (prefsAsync.isLoading || isSavingNotif)
                  ? null
                  : (v) => ref
                        .read(emailNotificationsProvider.notifier)
                        .setEnabled(v),
            ),
            const SizedBox(height: 32),

            // ── Account & Security ──────────────────────────────────────────
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
            OutlinedButton.icon(
              icon: isSigningOut
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout),
              label: const Text('Sign out'),
              onPressed: isSigningOut
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
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.error,
                side: BorderSide(color: cs.error),
                minimumSize: const Size(0, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
