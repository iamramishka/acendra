import 'package:acendra/app/router/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Placeholder screens replaced by real feature screens in later tasks.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.home,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const _PlaceholderScreen(title: 'Home'),
        redirect: (context, state) => RouteNames.marketplace,
      ),
      GoRoute(
        path: RouteNames.marketplace,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Marketplace'),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const _PlaceholderScreen(title: 'Login'),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Register'),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Dashboard'),
      ),
      GoRoute(
        path: RouteNames.admin,
        builder: (context, state) => const _PlaceholderScreen(title: 'Admin'),
      ),
    ],
  );
});
