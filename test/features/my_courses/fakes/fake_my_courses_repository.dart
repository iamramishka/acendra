import 'package:acendra/features/my_courses/domain/entities/enrolled_course.dart';
import 'package:acendra/features/my_courses/domain/repositories/my_courses_repository.dart';

class FakeMyCoursesRepository implements MyCoursesRepository {
  FakeMyCoursesRepository({
    this.result = const [],
    this.shouldThrow = false,
  });

  final List<EnrolledCourse> result;
  final bool shouldThrow;

  @override
  Future<List<EnrolledCourse>> listEnrolled() async {
    if (shouldThrow) throw Exception('Simulated network error');
    return result;
  }
}

const fakeEnrolledCourse = EnrolledCourse(
  id: 'enroll-1',
  courseId: 'course-1',
  title: 'Flutter Fundamentals',
  shortDescription: 'Learn Flutter from scratch.',
  thumbnailUrl: null,
  status: 'active',
  enrolledAt: '2026-10-01T00:00:00Z',
);
