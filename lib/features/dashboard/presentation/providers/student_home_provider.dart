import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/dashboard/data/student_home_repository.dart';
import 'package:acendra/features/dashboard/domain/entities/student_home.dart';
import 'package:acendra/features/dashboard/domain/repositories/student_home_repository.dart';
import 'package:acendra/features/learning/data/repositories/learning_progress_repository.dart';
import 'package:acendra/features/learning/data/repositories/supabase_learning_repository.dart';
import 'package:acendra/features/my_courses/data/repositories/supabase_course_progress_repository.dart';
import 'package:acendra/features/my_courses/data/repositories/supabase_my_courses_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final studentHomeRepositoryProvider = Provider<StudentHomeRepository>((ref) {
  return ReadStudentHomeRepository(
    courses: ref.watch(myCoursesRepositoryProvider),
    progress: ref.watch(courseProgressRepositoryProvider),
    learning: ref.watch(learningRepositoryProvider),
    lessonProgress: ref.watch(learningProgressRepositoryProvider),
  );
});

final studentHomeProvider = FutureProvider.autoDispose<StudentHome>((ref) {
  // Rebuild on sign-out, account change and session refresh. A late result from
  // an old provider computation cannot replace the current session's Home.
  final session = ref.watch(currentSessionProvider);
  if (session == null) return const StudentHome();
  return ref.watch(studentHomeRepositoryProvider).load();
});
