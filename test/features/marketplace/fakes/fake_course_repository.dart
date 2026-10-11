import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/features/marketplace/domain/repositories/course_repository.dart';

class FakeCourseRepository implements CourseRepository {
  FakeCourseRepository({this.result = const [], this.shouldThrow = false});

  final List<CourseSummary> result;
  final bool shouldThrow;

  @override
  Future<List<CourseSummary>> listPublished() async {
    if (shouldThrow) throw Exception('Simulated network error');
    return result;
  }
}

const fakeCourse = CourseSummary(
  id: 'fake-id-1',
  slug: 'fake-course',
  title: 'Fake Course',
  shortDescription: 'A fake course for tests.',
  priceMinor: 125000,
  currencyCode: 'LKR',
  publishedAt: '2026-10-11T00:00:00Z',
);
