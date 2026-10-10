import 'package:acendra/features/authentication/presentation/providers/logout_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A reusable icon button that signs the user out.
/// Disables itself while the sign-out request is in progress.
class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoutState = ref.watch(logoutProvider);
    final isLoading = logoutState.isLoading;

    return IconButton(
      tooltip: 'Sign out',
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.logout),
      onPressed: isLoading
          ? null
          : () => ref.read(logoutProvider.notifier).logout(),
    );
  }
}
