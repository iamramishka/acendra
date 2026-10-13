import 'package:acendra/features/my_courses/domain/entities/enrolled_course.dart';

abstract interface class MyCoursesRepository {
  Future<List<EnrolledCourse>> listEnrolled();
}
