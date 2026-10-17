import 'package:acendra/app/providers/theme_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthShell extends ConsumerWidget {
  const AuthShell({super.key, required this.child, this.banner});

  final Widget child;
  final Widget? banner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header: logo + app name + theme toggle
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/logo_icon.png',
                        height: 28,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.school_rounded,
                          color: cs.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Acedra',
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      _ThemeToggle(isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Optional banner (e.g. signin hero image)
                  if (banner != null) ...[banner!, const SizedBox(height: 24)],
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => ref.read(themeModeProvider.notifier).toggle(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 72,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F3254) : const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2A3B55) : const Color(0xFFDCE6F2),
          ),
        ),
        child: Stack(
          children: [
            // Sliding thumb
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment:
                  isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    size: 16,
                    color: cs.onPrimary,
                  ),
                ),
              ),
            ),
            // Background icon (the opposite mode)
            Align(
              alignment:
                  isDark ? Alignment.centerLeft : Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 16,
                  color: isDark
                      ? const Color(0xFF8BA4C8)
                      : const Color(0xFF54647E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
