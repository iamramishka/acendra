import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/login_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/register_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/reset_password_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/verify_email_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    routes: [
      GoRoute(
        path: RouteNames.home,
        redirect: (_, __) => RouteNames.marketplace,
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.verifyEmail,
        builder: (_, __) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.resetPassword,
        builder: (_, __) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.marketplace,
        builder: (_, __) => const _PlaceholderScreen(title: 'Marketplace'),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        builder: (_, __) => const _PlaceholderScreen(title: 'Dashboard'),
      ),
      GoRoute(
        path: RouteNames.admin,
        builder: (_, __) => const _PlaceholderScreen(title: 'Admin'),
      ),
    ],
  );
});
