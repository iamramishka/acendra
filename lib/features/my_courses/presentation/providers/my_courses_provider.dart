import 'package:acendra/features/my_courses/data/repositories/supabase_my_courses_repository.dart';
import 'package:acendra/features/my_courses/domain/entities/enrolled_course.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyCoursesNotifier extends AsyncNotifier<List<EnrolledCourse>> {
  @override
  Future<List<EnrolledCourse>> build() =>
      ref.read(myCoursesRepositoryProvider).listEnrolled();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(myCoursesRepositoryProvider).listEnrolled(),
    );
  }
}

final myCoursesProvider =
    AsyncNotifierProvider<MyCoursesNotifier, List<EnrolledCourse>>(
      MyCoursesNotifier.new,
    );
