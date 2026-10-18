// Run explicitly for visual QA; never used by the production entry point.
import 'package:acendra/app/providers/theme_mode_provider.dart';
import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/screens/verify_email_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:acendra/features/authentication/presentation/screens/reset_password_screen.dart';
import 'package:acendra/features/checkout/data/repositories/student_order_repository.dart';
import 'package:acendra/features/checkout/presentation/providers/checkout_actor_provider.dart';
import 'package:acendra/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:acendra/features/checkout/presentation/screens/order_status_screen.dart';
import 'package:acendra/features/learning/presentation/screens/course_overview_screen.dart';
import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/features/marketplace/domain/entities/category.dart';
import 'package:acendra/features/marketplace/domain/entities/course_detail.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/features/marketplace/domain/repositories/course_repository.dart';
import 'package:acendra/features/marketplace/presentation/screens/course_detail_screen.dart';
import 'package:acendra/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:acendra/features/profile/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../test/features/marketplace/fakes/fake_course_repository.dart' show fakeDetail;

class PreviewCourses implements CourseRepository {
  @override
  Future<List<CourseSummary>> listPublished() async => [
    for (final id in ['available', 'owned', 'pending']) CourseSummary(id: id, slug: id,
      title: 'Synthetic $id course', shortDescription: 'UI verification fixture. No real enrollment or payment.',
      priceMinor: id == 'available' ? 990000 : 750000, currencyCode: 'LKR', publishedAt: '2026-10-18', categoryId: 'design'),
  ];
  @override
  Future<List<Category>> listCategories() async => [const Category(id: 'design', name: 'Design', slug: 'design')];
  @override
  Future<CourseDetail> getCourseDetail(String id) async => CourseDetail(id: id, slug: id, title: 'Synthetic $id course', shortDescription: 'UI verification fixture. No real enrollment or payment.', description: 'Synthetic course description for visual verification only.', priceMinor: 990000, currencyCode: 'LKR', publishedAt: '2026-10-18', categoryId: 'design', sections: fakeDetail.sections);
  @override
  Future<bool> isEnrolled(String id) async => id == 'owned';
}
const previewOrder = StudentOrder(id: 'preview-order', courseId: 'pending', title: 'Synthetic pending course', number: 'SYNTHETIC-ONLY', amountMinor: 750000, currency: 'LKR', method: 'online', status: 'pending_verification');
class PreviewOrders implements StudentOrderRepository {
  @override
  Future<StudentOrder?> findOpen(String actor, String course) async => course == 'pending' ? previewOrder : null;
  @override
  Future<StudentOrder> read(String actor, String order) async => previewOrder;
}
class PreviewAuth extends AuthRepository {
  const PreviewAuth() : super.forTesting();
  @override
  Future<void> resendVerification({required String email}) async {}
  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}
  @override
  Future<void> updatePassword({required String newPassword}) async => throw UnsupportedError('Preview cannot update passwords');
  @override
  Future<void> signOut() async {}
}

void main() => runApp(ProviderScope(overrides: [
  courseRepositoryProvider.overrideWithValue(PreviewCourses()),
  studentOrderRepositoryProvider.overrideWithValue(PreviewOrders()),
  checkoutActorProvider.overrideWithValue('synthetic-preview'),
  authRepositoryProvider.overrideWithValue(const PreviewAuth()),
  pendingVerificationEmailProvider.overrideWith((ref) => 'demo@example.com'),
  courseProgressProvider('owned').overrideWith((ref) async => []),
], child: const PreviewApp()));

final previewRouter = GoRouter(initialLocation: '/marketplace', routes: [
  GoRoute(path: '/marketplace', builder: (_, _) => const Scaffold(body: MarketplaceScreen())),
  GoRoute(path: '/marketplace/:courseId', builder: (_, state) => CourseDetailScreen(courseId: state.pathParameters['courseId']!)),
  GoRoute(path: '/checkout/:courseId', builder: (_, state) => CheckoutScreen(courseId: state.pathParameters['courseId']!)),
  GoRoute(path: '/orders/:orderId', builder: (_, state) => OrderStatusScreen(orderId: state.pathParameters['orderId']!)),
  GoRoute(path: '/verify-email', builder: (_, _) => const VerifyEmailScreen()),
  GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
  GoRoute(path: '/reset-password', builder: (_, state) => ResetPasswordScreen(changePassword: state.uri.queryParameters['mode'] == 'change')),
  GoRoute(path: '/profile/settings', builder: (_, _) => const SettingsScreen()),
  GoRoute(path: '/courses/:courseId/overview', builder: (_, state) => CourseOverviewScreen(courseId: state.pathParameters['courseId']!)),
  GoRoute(path: '/login', builder: (_, _) => const Scaffold(body: Center(child: Text('Synthetic sign-in destination')))),
]);
class PreviewApp extends ConsumerWidget {
  const PreviewApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    debugShowCheckedModeBanner: false, theme: AppTheme.light, darkTheme: AppTheme.dark,
    themeMode: ref.watch(themeModeProvider), routerConfig: previewRouter,
    builder: (context, child) => Banner(message: 'SYNTHETIC PREVIEW', location: BannerLocation.topEnd, child: child!),
  );
}
