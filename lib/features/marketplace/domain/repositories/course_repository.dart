import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';

abstract class CourseRepository {
  Future<List<CourseSummary>> listPublished();
}
