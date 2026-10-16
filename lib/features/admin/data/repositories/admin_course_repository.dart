import 'package:acendra/features/admin/domain/entities/admin_course.dart';
import 'package:acendra/features/admin/domain/entities/admin_lesson.dart';
import 'package:acendra/features/admin/domain/entities/curriculum_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class AdminCourseRepository {
  Future<List<AdminCourse>> listCourses();
  Future<AdminCourse> getCourse(String courseId);
  Future<void> createCourse(AdminCourse course);
  Future<void> updateCourse(AdminCourse course);
  Future<void> deleteCourse(String courseId);
  Future<void> publishCourse(String courseId);
  Future<void> unpublishCourse(String courseId);
  Future<List<AdminCurriculumSection>> getCurriculum(String courseId);
  Future<void> upsertSection(AdminCurriculumSection section);
  Future<void> deleteSection(String sectionId);
  Future<void> upsertLesson(AdminLesson lesson);
  Future<void> deleteLesson(String lessonId);
}

class StubAdminCourseRepository implements AdminCourseRepository {
  final List<AdminCourse> _courses = [
    AdminCourse(
      id: 'course-1',
      title: 'Flutter for Beginners',
      description: 'Learn Flutter from scratch with hands-on projects.',
      price: 4500,
      currency: 'LKR',
      isPublished: true,
      enrollmentCount: 142,
      sectionCount: 5,
      lessonCount: 24,
      createdAt: DateTime(2026, 1, 10),
      updatedAt: DateTime(2026, 3, 15),
    ),
    AdminCourse(
      id: 'course-2',
      title: 'Advanced Dart Programming',
      description: 'Deep dive into Dart language features and best practices.',
      price: 6500,
      currency: 'LKR',
      isPublished: true,
      enrollmentCount: 87,
      sectionCount: 8,
      lessonCount: 36,
      createdAt: DateTime(2026, 2, 20),
      updatedAt: DateTime(2026, 4, 5),
    ),
    AdminCourse(
      id: 'course-3',
      title: 'Supabase & Backend Integration',
      description:
          'Build production-ready backends with Supabase and PostgreSQL.',
      price: 8000,
      currency: 'LKR',
      isPublished: false,
      enrollmentCount: 0,
      sectionCount: 3,
      lessonCount: 12,
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 10),
    ),
  ];

  final Map<String, List<AdminCurriculumSection>> _curriculum = {
    'course-1': [
      const AdminCurriculumSection(
        id: 's1',
        courseId: 'course-1',
        title: 'Getting Started',
        sortOrder: 0,
        lessons: [
          AdminLesson(
            id: 'l1',
            sectionId: 's1',
            courseId: 'course-1',
            title: 'Introduction to Flutter',
            description: 'Overview of the Flutter framework.',
            lessonType: LessonType.video,
            sortOrder: 0,
            isPreviewed: true,
            durationSeconds: 480,
          ),
          AdminLesson(
            id: 'l2',
            sectionId: 's1',
            courseId: 'course-1',
            title: 'Setting Up Your Environment',
            description: 'Install Flutter SDK and configure your IDE.',
            lessonType: LessonType.pdf,
            sortOrder: 1,
            isPreviewed: false,
            durationSeconds: 300,
          ),
        ],
      ),
      const AdminCurriculumSection(
        id: 's2',
        courseId: 'course-1',
        title: 'Widgets Fundamentals',
        sortOrder: 1,
        lessons: [
          AdminLesson(
            id: 'l3',
            sectionId: 's2',
            courseId: 'course-1',
            title: 'Stateless vs Stateful Widgets',
            description: 'Understanding the widget lifecycle.',
            lessonType: LessonType.video,
            sortOrder: 0,
            isPreviewed: false,
            durationSeconds: 720,
          ),
        ],
      ),
    ],
  };

  @override
  Future<List<AdminCourse>> listCourses() async {
    // TODO: Replace with Supabase query: SELECT * FROM courses ORDER BY created_at DESC
    await Future.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_courses);
  }

  @override
  Future<AdminCourse> getCourse(String courseId) async {
    // TODO: Replace with Supabase query: SELECT * FROM courses WHERE id = :courseId
    await Future.delayed(const Duration(milliseconds: 200));
    return _courses.firstWhere((c) => c.id == courseId);
  }

  @override
  Future<void> createCourse(AdminCourse course) async {
    // TODO: Replace with Supabase insert into courses table
    await Future.delayed(const Duration(milliseconds: 300));
    _courses.add(course);
  }

  @override
  Future<void> updateCourse(AdminCourse course) async {
    // TODO: Replace with Supabase update: UPDATE courses SET ... WHERE id = :id
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _courses.indexWhere((c) => c.id == course.id);
    if (index != -1) _courses[index] = course;
  }

  @override
  Future<void> deleteCourse(String courseId) async {
    // TODO: Replace with Supabase delete: DELETE FROM courses WHERE id = :courseId
    await Future.delayed(const Duration(milliseconds: 300));
    _courses.removeWhere((c) => c.id == courseId);
  }

  @override
  Future<void> publishCourse(String courseId) async {
    // TODO: Replace with Supabase update: UPDATE courses SET is_published = true WHERE id = :courseId
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _courses.indexWhere((c) => c.id == courseId);
    if (index != -1) {
      _courses[index] = _courses[index].copyWith(isPublished: true);
    }
  }

  @override
  Future<void> unpublishCourse(String courseId) async {
    // TODO: Replace with Supabase update: UPDATE courses SET is_published = false WHERE id = :courseId
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _courses.indexWhere((c) => c.id == courseId);
    if (index != -1) {
      _courses[index] = _courses[index].copyWith(isPublished: false);
    }
  }

  @override
  Future<List<AdminCurriculumSection>> getCurriculum(String courseId) async {
    // TODO: Replace with Supabase query joining sections and lessons for courseId
    await Future.delayed(const Duration(milliseconds: 300));
    return _curriculum[courseId] ?? [];
  }

  @override
  Future<void> upsertSection(AdminCurriculumSection section) async {
    // TODO: Replace with Supabase upsert into curriculum_sections table
    await Future.delayed(const Duration(milliseconds: 200));
    final sections = _curriculum[section.courseId] ?? [];
    final index = sections.indexWhere((s) => s.id == section.id);
    if (index != -1) {
      sections[index] = section;
    } else {
      sections.add(section);
    }
    _curriculum[section.courseId] = sections;
  }

  @override
  Future<void> deleteSection(String sectionId) async {
    // TODO: Replace with Supabase delete: DELETE FROM curriculum_sections WHERE id = :sectionId
    await Future.delayed(const Duration(milliseconds: 200));
    for (final key in _curriculum.keys) {
      _curriculum[key]?.removeWhere((s) => s.id == sectionId);
    }
  }

  @override
  Future<void> upsertLesson(AdminLesson lesson) async {
    // TODO: Replace with Supabase upsert into lessons table
    await Future.delayed(const Duration(milliseconds: 200));
    final sections = _curriculum[lesson.courseId] ?? [];
    final sIndex = sections.indexWhere((s) => s.id == lesson.sectionId);
    if (sIndex != -1) {
      final lessons = List<AdminLesson>.from(sections[sIndex].lessons);
      final lIndex = lessons.indexWhere((l) => l.id == lesson.id);
      if (lIndex != -1) {
        lessons[lIndex] = lesson;
      } else {
        lessons.add(lesson);
      }
      sections[sIndex] = sections[sIndex].copyWith(lessons: lessons);
      _curriculum[lesson.courseId] = sections;
    }
  }

  @override
  Future<void> deleteLesson(String lessonId) async {
    // TODO: Replace with Supabase delete: DELETE FROM lessons WHERE id = :lessonId
    await Future.delayed(const Duration(milliseconds: 200));
    for (final sections in _curriculum.values) {
      for (var i = 0; i < sections.length; i++) {
        final lessons = sections[i].lessons
            .where((l) => l.id != lessonId)
            .toList();
        sections[i] = sections[i].copyWith(lessons: lessons);
      }
    }
  }
}

final adminCourseRepositoryProvider = Provider<AdminCourseRepository>((ref) {
  return StubAdminCourseRepository();
});
