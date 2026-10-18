abstract final class RouteNames {
  static const String home = '/';
  static const String marketplace = '/marketplace';
  static const String courseDetail = '/marketplace/:courseId';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String dashboard = '/dashboard';
  static const String dashboardHome = '/dashboard/home';
  static const String savedCourses = '/dashboard/saved';
  static const String myCourses = '/dashboard/courses';
  static const String learn = '/learn/:courseId';
  static const String learnLesson = '/learn/:courseId/:lessonId';
  static const String admin = '/admin';
  static const String checkout = '/checkout/:courseId';
  static const String checkoutSuccess = '/checkout/:courseId/success';
  static const String checkoutPending = '/checkout/:courseId/pending';
  static const String checkoutFailure = '/checkout/:courseId/failure';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String settings = '/settings';
  static const String changePassword = '/settings/password';

  // Bank transfer flow (CSA-107, 110, 115)
  static const String bankTransfer = '/bank-transfer/:orderId';
  static const String receiptStatus = '/bank-transfer/:orderId/status';
  static const String receiptResubmit = '/bank-transfer/:orderId/resubmit';

  // Finance admin (CSA-111)
  static const String financeReview = '/admin/finance-review';

  // Admin course management (CSA-157)
  static const String adminCourses = '/admin/courses';
  static const String adminCourseEdit = '/admin/courses/:courseId/edit';
  static const String adminCurriculumBuilder =
      '/admin/courses/:courseId/curriculum';
  static const String adminLessonEditor =
      '/admin/courses/:courseId/curriculum/:lessonId/edit';
  static const String adminStudents = '/admin/students';
  static const String adminStudentDetail = '/admin/students/:studentId';
  static const String adminPayments = '/admin/payments';
  static const String adminPaymentHistory = '/admin/payments/history';
}
