import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/login_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/register_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/reset_password_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/verify_email_screen.dart';
import 'package:acendra/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:acendra/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Routes that an unauthenticated user may visit.
const _publicRoutes = {
  RouteNames.login,
  RouteNames.register,
  RouteNames.verifyEmail,
  RouteNames.forgotPassword,
  RouteNames.resetPassword,
  RouteNames.home,
  RouteNames.marketplace,
};

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
    initialLocation: RouteNames.login,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final sessionRestored = ref.read(sessionRestoredProvider);
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      final location = state.uri.path;

      // Wait for session restoration before redirecting.
      if (!sessionRestored) return null;

      final isPublic = _publicRoutes.contains(location);

      // Unauthenticated user trying to reach a protected route → login.
      if (!isAuthenticated && !isPublic) return RouteNames.login;

      // Authenticated user on an auth-only route → dashboard.
      if (isAuthenticated &&
          (location == RouteNames.login || location == RouteNames.register)) {
        return RouteNames.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.home,
        redirect: (_, _) => RouteNames.marketplace,
      ),
      GoRoute(path: RouteNames.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: RouteNames.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.verifyEmail,
        builder: (_, _) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.resetPassword,
        builder: (_, _) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.marketplace,
        builder: (_, _) => const _PlaceholderScreen(title: 'Marketplace'),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        builder: (_, _) => const _PlaceholderScreen(title: 'Dashboard'),
      ),
      GoRoute(
        path: RouteNames.admin,
        builder: (_, _) => const _PlaceholderScreen(title: 'Admin'),
      ),
      GoRoute(
        path: RouteNames.profile,
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.profileEdit,
        builder: (_, _) => const ProfileEditScreen(),
      ),
    ],
  );
});
