import 'package:acendra/features/marketplace/domain/entities/category.dart';
import 'package:acendra/features/marketplace/domain/entities/course_detail.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';

abstract class CourseRepository {
  Future<List<CourseSummary>> listPublished();
  Future<List<Category>> listCategories();
  Future<CourseDetail> getCourseDetail(String courseId);
  Future<bool> isEnrolled(String courseId);
}
