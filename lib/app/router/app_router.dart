import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/core/widgets/navigation/admin_shell.dart';
import 'package:acendra/core/widgets/navigation/learning_shell.dart';
import 'package:acendra/core/widgets/navigation/public_shell.dart';
import 'package:acendra/core/widgets/navigation/student_shell.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/login_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/register_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/reset_password_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/verify_email_screen.dart';
import 'package:acendra/features/marketplace/presentation/screens/course_detail_screen.dart';
import 'package:acendra/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:acendra/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:acendra/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _publicRoutes = {
  RouteNames.login,
  RouteNames.register,
  RouteNames.verifyEmail,
  RouteNames.forgotPassword,
  RouteNames.resetPassword,
  RouteNames.home,
  RouteNames.marketplace,
  RouteNames.courseDetail,
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

      if (!sessionRestored) return null;

      final isPublic = _publicRoutes.any(
        (r) => r.contains(':')
            ? location.startsWith(r.substring(0, r.indexOf(':')))
            : location == r,
      );

      if (!isAuthenticated && !isPublic) return RouteNames.login;

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

      // Authentication screens own AuthShell; nesting another scrollable
      // shell here would give their Scaffold unbounded height.
      ShellRoute(
        builder: (context, state, child) => child,
        routes: [
          GoRoute(
            path: RouteNames.login,
            builder: (_, _) => const LoginScreen(),
          ),
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
        ],
      ),

      // Public shell — top-nav bar for marketplace / course browsing.
      ShellRoute(
        builder: (context, state, child) => PublicShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.marketplace,
            builder: (_, _) => const MarketplaceScreen(),
          ),
          GoRoute(
            path: RouteNames.courseDetail,
            builder: (_, state) =>
                CourseDetailScreen(courseId: state.pathParameters['courseId']!),
          ),
        ],
      ),

      // Student shell — AppBar + bottom-nav for authenticated student area.
      ShellRoute(
        builder: (context, state, child) => StudentShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.dashboard,
            builder: (_, _) => const _PlaceholderScreen(title: 'Dashboard'),
          ),
          GoRoute(
            path: RouteNames.myCourses,
            builder: (_, _) => const _PlaceholderScreen(title: 'My Courses'),
          ),
          GoRoute(
            path: RouteNames.checkout,
            builder: (_, _) => const _PlaceholderScreen(title: 'Checkout'),
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
      ),

      // Learning shell — immersive lesson view with back button.
      ShellRoute(
        builder: (context, state, child) => LearningShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.learn,
            builder: (_, _) =>
                const _PlaceholderScreen(title: 'Learning Workspace'),
          ),
        ],
      ),

      // Admin shell — sidebar-nav for the admin dashboard.
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.admin,
            builder: (_, _) => const _PlaceholderScreen(title: 'Admin'),
          ),
        ],
      ),
    ],
  );
});
