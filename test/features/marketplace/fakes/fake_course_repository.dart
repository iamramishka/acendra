import 'package:acendra/features/marketplace/domain/entities/category.dart';
import 'package:acendra/features/marketplace/domain/entities/course_detail.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:acendra/features/marketplace/domain/repositories/course_repository.dart';

class FakeCourseRepository implements CourseRepository {
  FakeCourseRepository({
    this.result = const [],
    this.shouldThrow = false,
    this.categories = const [],
    this.detail,
    this.enrolled = false,
  });

  final List<CourseSummary> result;
  final bool shouldThrow;
  final List<Category> categories;
  final CourseDetail? detail;
  final bool enrolled;

  @override
  Future<List<CourseSummary>> listPublished() async {
    if (shouldThrow) throw Exception('Simulated network error');
    return result;
  }

  @override
  Future<List<Category>> listCategories() async => categories;

  @override
  Future<CourseDetail> getCourseDetail(String courseId) async {
    if (shouldThrow) throw Exception('Simulated network error');
    return detail ?? fakeDetail;
  }

  @override
  Future<bool> isEnrolled(String courseId) async => enrolled;
}

const fakeCourse = CourseSummary(
  id: 'fake-id-1',
  slug: 'fake-course',
  title: 'Fake Course',
  shortDescription: 'A fake course for tests.',
  priceMinor: 125000,
  currencyCode: 'LKR',
  publishedAt: '2026-10-11T00:00:00Z',
  categoryId: 'cat-1',
);

const fakeCategory = Category(id: 'cat-1', name: 'Flutter', slug: 'flutter');

final fakeDetail = const CourseDetail(
  id: 'fake-id-1',
  slug: 'fake-course',
  title: 'Fake Course',
  shortDescription: 'A fake course for tests.',
  description: 'Full description here.',
  priceMinor: 125000,
  currencyCode: 'LKR',
  publishedAt: '2026-10-11T00:00:00Z',
  sections: [
    CurriculumSection(
      id: 'sec-1',
      title: 'Getting Started',
      position: 0,
      lessons: [
        LessonItem(
          id: 'les-1',
          title: 'Introduction',
          lessonType: 'video',
          position: 0,
          isPreview: true,
          durationSeconds: 300,
        ),
      ],
    ),
  ],
);
