import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/core/widgets/navigation/admin_shell.dart';
import 'package:acendra/core/widgets/navigation/learning_shell.dart';
import 'package:acendra/core/widgets/navigation/public_shell.dart';
import 'package:acendra/core/widgets/navigation/student_shell.dart';
import 'package:acendra/features/admin/presentation/screens/admin_courses_screen.dart';
import 'package:acendra/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:acendra/features/admin/presentation/screens/admin_payments_screen.dart';
import 'package:acendra/features/admin/presentation/screens/admin_students_screen.dart';
import 'package:acendra/features/admin/presentation/screens/course_editor_screen.dart';
import 'package:acendra/features/admin/presentation/screens/curriculum_builder_screen.dart';
import 'package:acendra/features/admin/presentation/screens/finance_review_screen.dart';
import 'package:acendra/features/admin/presentation/screens/lesson_editor_screen.dart';
import 'package:acendra/features/admin/presentation/screens/receipt_review_history_screen.dart';
import 'package:acendra/features/admin/presentation/screens/student_enrollment_details_screen.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/login_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/register_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/reset_password_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/verify_email_screen.dart';
import 'package:acendra/features/bank_transfer/presentation/screens/bank_transfer_screen.dart';
import 'package:acendra/features/bank_transfer/presentation/screens/receipt_resubmission_screen.dart';
import 'package:acendra/features/bank_transfer/presentation/screens/receipt_status_screen.dart';
import 'package:acendra/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:acendra/features/checkout/presentation/screens/payment_failure_screen.dart';
import 'package:acendra/features/checkout/presentation/screens/payment_pending_screen.dart';
import 'package:acendra/features/checkout/presentation/screens/payment_success_screen.dart';
import 'package:acendra/features/dashboard/presentation/screens/dashboard_home_screen.dart';
import 'package:acendra/features/dashboard/presentation/screens/dashboard_saved_screen.dart';
import 'package:acendra/features/learning/presentation/screens/learning_workspace_screen.dart';
import 'package:acendra/features/my_courses/presentation/screens/my_courses_screen.dart';
import 'package:acendra/features/marketplace/presentation/screens/course_detail_screen.dart';
import 'package:acendra/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:acendra/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:acendra/features/profile/presentation/screens/profile_screen.dart';
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
            redirect: (_, _) => RouteNames.dashboardHome,
          ),
          GoRoute(
            path: RouteNames.dashboardHome,
            builder: (_, _) => const DashboardHomeScreen(),
          ),
          GoRoute(
            path: RouteNames.savedCourses,
            builder: (_, _) => const DashboardSavedScreen(),
          ),
          GoRoute(
            path: RouteNames.myCourses,
            builder: (_, _) => const MyCoursesScreen(),
          ),
          GoRoute(
            path: RouteNames.checkout,
            builder: (_, state) =>
                CheckoutScreen(courseId: state.pathParameters['courseId']!),
            routes: [
              GoRoute(
                path: 'success',
                builder: (_, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  return PaymentSuccessScreen(
                    courseId: state.pathParameters['courseId']!,
                    courseTitle: extra['courseTitle'] as String? ?? '',
                    orderNumber: extra['orderNumber'] as String? ?? '',
                  );
                },
              ),
              GoRoute(
                path: 'pending',
                builder: (_, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  return PaymentPendingScreen(
                    courseId: state.pathParameters['courseId']!,
                    courseTitle: extra['courseTitle'] as String? ?? '',
                    orderNumber: extra['orderNumber'] as String? ?? '',
                    bankName: extra['bankName'] as String?,
                    accountNumber: extra['accountNumber'] as String?,
                  );
                },
              ),
              GoRoute(
                path: 'failure',
                builder: (_, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  return PaymentFailureScreen(
                    courseId: state.pathParameters['courseId']!,
                    courseTitle: extra['courseTitle'] as String?,
                    reason: extra['reason'] as String?,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.profile,
            builder: (_, _) => const ProfileScreen(),
          ),
          GoRoute(
            path: RouteNames.profileEdit,
            builder: (_, _) => const ProfileEditScreen(),
          ),
          // Bank transfer flow (CSA-107, 110, 115)
          GoRoute(
            path: RouteNames.bankTransfer,
            builder: (_, state) {
              return BankTransferScreen(
                orderId: state.pathParameters['orderId']!,
              );
            },
            routes: [
              GoRoute(
                path: 'status',
                builder: (_, state) => ReceiptStatusScreen(
                  orderId: state.pathParameters['orderId']!,
                ),
              ),
              GoRoute(
                path: 'resubmit',
                builder: (_, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  return ReceiptResubmissionScreen(
                    orderId: state.pathParameters['orderId']!,
                    rejectionReason: extra['rejectionReason'] as String?,
                  );
                },
              ),
            ],
          ),
        ],
      ),

      // Learning shell — immersive lesson view with back button.
      ShellRoute(
        builder: (context, state, child) => LearningShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.learn,
            builder: (_, state) => LearningWorkspaceScreen(
              courseId: state.pathParameters['courseId']!,
            ),
          ),
        ],
      ),

      // Admin shell — sidebar-nav for the admin dashboard.
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.admin,
            builder: (_, _) => const AdminDashboardScreen(),
          ),
          // Finance review — CSA-111 (finance_admin / super_admin only)
          GoRoute(
            path: RouteNames.financeReview,
            builder: (_, _) => const FinanceReviewScreen(),
          ),
          GoRoute(
            path: RouteNames.adminCourses,
            builder: (_, _) => const AdminCoursesScreen(),
            routes: [
              GoRoute(
                path: ':courseId/edit',
                builder: (_, state) => CourseEditorScreen(
                  courseId: state.pathParameters['courseId']!,
                ),
              ),
              GoRoute(
                path: ':courseId/curriculum',
                builder: (_, state) => CurriculumBuilderScreen(
                  courseId: state.pathParameters['courseId']!,
                ),
                routes: [
                  GoRoute(
                    path: ':lessonId/edit',
                    builder: (_, state) => LessonEditorScreen(
                      courseId: state.pathParameters['courseId']!,
                      lessonId: state.pathParameters['lessonId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.adminStudents,
            builder: (_, _) => const AdminStudentsScreen(),
            routes: [
              GoRoute(
                path: ':studentId',
                builder: (_, state) => StudentEnrollmentDetailsScreen(
                  studentId: state.pathParameters['studentId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.adminPayments,
            builder: (_, _) => const AdminPaymentsScreen(),
            routes: [
              GoRoute(
                path: 'history',
                builder: (_, _) => const ReceiptReviewHistoryScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
