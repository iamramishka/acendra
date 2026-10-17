import 'package:flutter/material.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.child, this.banner});

  final Widget child;
  final Widget? banner;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
                  // Header: logo + app name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 28,
                        errorBuilder: (_, _a, _b) => Icon(
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
