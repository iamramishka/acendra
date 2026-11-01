import 'package:acendra/features/marketplace/domain/entities/category.dart';
import 'package:acendra/features/marketplace/domain/entities/course_detail.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';

import '../fakes/fake_course_repository.dart';

// Synthetic metadata for offline QA only. These are never catalog fallbacks.
const catalogPreviewCategories = [
  Category(id: 'development', name: 'Development', slug: 'development'),
  Category(id: 'design', name: 'Design', slug: 'design'),
  Category(id: 'business', name: 'Business', slug: 'business'),
];

final catalogPreviewCourses = [
  for (final (id, title, blurb, category, price) in const [
    (
      'flutter',
      'Flutter Development Essentials',
      'Build responsive apps with Dart, reusable widgets and practical projects.',
      'development',
      1250000,
    ),
    (
      'design',
      'UI Design Foundations',
      'Explore typography, color and layouts that make everyday interfaces clear.',
      'design',
      850000,
    ),
    (
      'business',
      'Start Your Small Business',
      'Turn an idea into a practical plan, from customers to your first launch.',
      'business',
      650000,
    ),
    (
      'dart',
      'Dart for Confident Developers',
      'Practice null safety, asynchronous code and maintainable application logic.',
      'development',
      950000,
    ),
    (
      'accessibility',
      'Accessible Product Design',
      'Create useful experiences with readable content and inclusive interactions.',
      'design',
      750000,
    ),
    (
      'planning',
      'Project Planning Basics',
      'Set clear goals and organize a realistic roadmap for your next project.',
      'business',
      450000,
    ),
  ])
    CourseSummary(
      id: id,
      slug: id,
      title: title,
      shortDescription: blurb,
      priceMinor: price,
      currencyCode: 'LKR',
      publishedAt: id == 'flutter' ? '2026-10-21' : '2026-10-20',
      categoryId: category,
    ),
];

class CatalogPreviewRepository extends FakeCourseRepository {
  CatalogPreviewRepository()
    : super(
        result: catalogPreviewCourses,
        categories: catalogPreviewCategories,
      );

  @override
  Future<CourseDetail> getCourseDetail(String courseId) async {
    final course = result.firstWhere((course) => course.id == courseId);
    return CourseDetail(
      id: course.id,
      slug: course.slug,
      title: course.title,
      shortDescription: course.shortDescription,
      description:
          'Synthetic course details for local layout and navigation verification. '
          'This preview does not create orders or grant course access.',
      priceMinor: course.priceMinor,
      currencyCode: course.currencyCode,
      publishedAt: course.publishedAt,
      categoryId: course.categoryId,
      sections: const [
        CurriculumSection(
          id: 'introduction',
          title: 'Learn the fundamentals',
          position: 0,
          lessons: [
            LessonItem(
              id: 'welcome',
              title: 'Welcome and course overview',
              lessonType: 'video',
              isPreview: true,
              position: 0,
              durationSeconds: 300,
            ),
            LessonItem(
              id: 'practice',
              title: 'Your first practice activity',
              lessonType: 'text',
              isPreview: false,
              position: 1,
              durationSeconds: 600,
            ),
          ],
        ),
      ],
    );
  }
}
