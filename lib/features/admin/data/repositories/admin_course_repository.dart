import 'package:acendra/features/admin/data/repositories/admin_directory_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

class SupabaseAdminCourseRepository implements AdminCourseRepository {
  SupabaseAdminCourseRepository(SupabaseClient client)
    : _directory = AdminDirectoryClient(client);
  final AdminDirectoryClient _directory;

  AdminCourse _course(Map<String, dynamic> row) => AdminCourse(
    id: row['id'] as String,
    title: row['title'] as String,
    description: row['description'] as String,
    thumbnailUrl: row['thumbnail_url'] as String?,
    price: num.parse(row['price_minor'].toString()) / 100,
    currency: row['currency_code'] as String,
    isPublished: row['status'] == 'published',
    enrollmentCount: (row['enrollment_count'] as num).toInt(),
    sectionCount: (row['section_count'] as num).toInt(),
    lessonCount: (row['lesson_count'] as num).toInt(),
    createdAt: DateTime.parse(row['created_at'] as String),
    updatedAt: DateTime.parse(row['updated_at'] as String),
  );

  @override
  Future<List<AdminCourse>> listCourses() async =>
      (await _directory.read('courses')).map(_course).toList();

  @override
  Future<AdminCourse> getCourse(String courseId) async {
    final rows = await _directory.read('courses', id: courseId);
    if (rows.isEmpty) {
      throw const AdminDataException(
        'Course not found or no longer available to your account.',
      );
    }
    return _course(rows.single);
  }

  // These forms do not yet collect the required trusted mutation contracts.
  // Never replace a failed write with a local success or direct table mutation.
  Never _unavailable() => throw const AdminDataException(
    'Course editing is not available in this release. Contact your administrator.',
  );
  @override
  Future<void> createCourse(AdminCourse course) async => _unavailable();
  @override
  Future<void> updateCourse(AdminCourse course) async => _unavailable();
  @override
  Future<void> deleteCourse(String courseId) async => _unavailable();
  @override
  Future<void> publishCourse(String courseId) async => _unavailable();
  @override
  Future<void> unpublishCourse(String courseId) async => _unavailable();
  @override
  Future<List<AdminCurriculumSection>> getCurriculum(String courseId) async =>
      _unavailable();
  @override
  Future<void> upsertSection(AdminCurriculumSection section) async =>
      _unavailable();
  @override
  Future<void> deleteSection(String sectionId) async => _unavailable();
  @override
  Future<void> upsertLesson(AdminLesson lesson) async => _unavailable();
  @override
  Future<void> deleteLesson(String lessonId) async => _unavailable();
}

final adminCourseRepositoryProvider = Provider<AdminCourseRepository>((ref) {
  return SupabaseAdminCourseRepository(Supabase.instance.client);
});
