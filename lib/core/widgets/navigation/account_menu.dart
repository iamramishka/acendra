import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/features/authentication/presentation/providers/logout_provider.dart';
import 'package:acendra/features/authentication/presentation/providers/navigation_access_provider.dart';
import 'package:acendra/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _AccountAction { profile, admin, signOut }

class AccountMenu extends ConsumerWidget {
  const AccountMenu({super.key, this.icon});

  final Widget? icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canOpenAdmin =
        ref.watch(navigationAccessProvider).asData?.value ?? false;
    final name = ref.watch(displayNameProvider)?.trim();
    final email = ref.watch(currentEmailProvider)?.trim();
    final label = name?.isNotEmpty == true ? name! : email;
    final initial = label?.isNotEmpty == true
        ? label!.characters.first.toUpperCase()
        : '?';
    final signingOut = ref.watch(logoutProvider).isLoading;

    return PopupMenuButton<_AccountAction>(
      tooltip: 'Account menu',
      enabled: !signingOut,
      icon: icon ?? CircleAvatar(radius: 16, child: Text(initial)),
      onSelected: (action) async {
        switch (action) {
          case _AccountAction.profile:
            context.go(RouteNames.profile);
          case _AccountAction.admin:
            context.go(RouteNames.admin);
          case _AccountAction.signOut:
            await ref.read(logoutProvider.notifier).logout();
            if (!context.mounted) return;
            if (ref.read(logoutProvider).hasError) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not sign out. Please try again.'),
                ),
              );
            } else {
              context.go(RouteNames.login);
            }
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: _AccountAction.profile,
          child: Text('Profile'),
        ),
        if (canOpenAdmin)
          const PopupMenuItem(
            value: _AccountAction.admin,
            child: Text('Admin'),
          ),
        const PopupMenuItem(
          value: _AccountAction.signOut,
          child: Text('Sign out'),
        ),
      ],
    );
  }
}
