import 'dart:convert';
import 'dart:math';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/admin/data/repositories/admin_directory_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:acendra/features/admin/domain/entities/admin_course.dart';
import 'package:acendra/features/admin/domain/entities/admin_lesson.dart';
import 'package:acendra/features/admin/domain/entities/curriculum_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UUID v4, used for entity IDs and retry-safe mutation IDs.
String newAdminCourseId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Parses decimal currency without binary floating-point rounding/truncation.
String? adminCoursePriceMinor(String text) {
  final match = RegExp(
    r'^(0|[1-9][0-9]{0,16})(?:\.([0-9]{1,2}))?$',
  ).firstMatch(text.trim());
  if (match == null) return null;
  final minor =
      BigInt.parse(match[1]!) * BigInt.from(100) +
      BigInt.parse((match[2] ?? '').padRight(2, '0'));
  return minor <= BigInt.parse('9223372036854775807') ? minor.toString() : null;
}

String adminCoursePriceText(String minor) => formatAdminCourseMinorPrice(minor);

abstract interface class AdminCourseRepository {
  Future<List<AdminCourse>> listCourses();
  Future<AdminCourse> getCourse(String courseId);
  Future<void> createCourse(AdminCourse course);
  Future<void> updateCourse(AdminCourse course);
  Future<void> archiveCourse(String courseId, {String? expectedUpdatedAt});
  Future<void> publishCourse(String courseId, {String? expectedUpdatedAt});
  Future<void> unpublishCourse(String courseId, {String? expectedUpdatedAt});
  Future<List<AdminCurriculumSection>> getCurriculum(String courseId);
  Future<void> upsertSection(AdminCurriculumSection section);
  Future<void> deleteSection(String sectionId, {String? expectedUpdatedAt});
  Future<void> upsertLesson(AdminLesson lesson);
  Future<void> deleteLesson(String lessonId, {String? expectedUpdatedAt});
  Future<void> reorderSections(
    String courseId,
    List<String> ids, {
    String? expectedUpdatedAt,
  });
  Future<void> reorderLessons(
    String courseId,
    String sectionId,
    List<String> ids, {
    String? expectedUpdatedAt,
  });
}

/// Revisions returned only by this repository's successful writes, never reads.
abstract interface class AdminCourseMutationRevisions {
  String? ownMutationRevision(String courseId);
}

class SupabaseAdminCourseRepository
    implements AdminCourseRepository, AdminCourseMutationRevisions {
  SupabaseAdminCourseRepository(this._client)
    : _directory = AdminDirectoryClient(_client);
  final SupabaseClient _client;
  final AdminDirectoryClient _directory;
  final _revisions = <String, String>{};
  final _ownMutationRevisions = <String, String>{};
  @override
  String? ownMutationRevision(String courseId) =>
      _ownMutationRevisions[courseId];
  final _curriculumRevisions = <String, String>{};
  final _sectionCourses = <String, String>{};
  final _lessonCourses = <String, String>{};
  final _busy = <String>{};
  // Keep the exact operation ID for an ambiguous transport failure. Retrying
  // unchanged input reconciles the original transaction rather than duplicating it.
  final _requestIds = <String, String>{};

  AdminCourse _course(
    Map<String, dynamic> row, [
    Map<String, String> categories = const {},
  ]) {
    final revision = row['updated_at'] as String;
    _revisions[row['id'] as String] = revision;
    return AdminCourse(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String? ?? '',
      thumbnailUrl: row['thumbnail_url'] as String?,
      price: num.parse(row['price_minor'].toString()) / 100,
      priceMinor: row['price_minor'].toString(),
      currency: row['currency_code'] as String,
      slug: row['slug'] as String? ?? '',
      categoryId: row['category_id'] as String?,
      shortDescription: row['short_description'] as String? ?? '',
      categories: categories,
      isPublished: row['status'] == 'published',
      enrollmentCount: (row['enrollment_count'] as num? ?? 0).toInt(),
      sectionCount: (row['section_count'] as num? ?? 0).toInt(),
      lessonCount: (row['lesson_count'] as num? ?? 0).toInt(),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(revision),
      rawUpdatedAt: revision,
    );
  }

  @override
  Future<List<AdminCourse>> listCourses() async => (await _directory.read(
    'courses',
  )).where((row) => row['status'] != 'archived').map(_course).toList();
  @override
  Future<AdminCourse> getCourse(String courseId) async {
    final data = await _invoke('admin-course-management', {
      'action': 'get',
      'course_id': courseId,
    });
    return _course(Map<String, dynamic>.from(data['course'] as Map), {
      for (final category in data['categories'] as List)
        (category as Map)['id'] as String: category['name'] as String,
    });
  }

  String _revision(String courseId) =>
      _revisions[courseId] ??
      (throw const AdminDataException(
        'Reload this course before making changes.',
      ));
  Map<String, dynamic> _metadata(AdminCourse course) {
    final minor =
        course.priceMinor ??
        adminCoursePriceMinor(course.price.toStringAsFixed(2));
    if (minor == null || course.currency != 'LKR') {
      throw const AdminDataException(
        'Enter a valid non-negative LKR price with at most two decimal places.',
      );
    }
    final derivedSlug = course.slug.isEmpty
        ? course.title
              .toLowerCase()
              .replaceAll(RegExp('[^a-z0-9]+'), '-')
              .replaceAll(RegExp(r'^-|-$'), '')
        : course.slug;
    return {
      'title': course.title,
      'slug': derivedSlug.isEmpty ? 'course-${course.id}' : derivedSlug,
      'category_id': course.categoryId,
      'short_description': course.shortDescription,
      'description': course.description,
      'price_minor': minor,
      'currency_code': 'LKR',
    };
  }

  Future<Map<String, dynamic>> _invoke(
    String name,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client.functions.invoke(
        name,
        body: body,
        headers: headers,
      );
      final payload = response.data;
      if (response.status != 200 ||
          payload is! Map ||
          payload['data'] is! Map) {
        throw const AdminDataException(
          'Unable to complete the course action. Retry.',
        );
      }
      return Map<String, dynamic>.from(payload['data'] as Map);
    } on FunctionException catch (error) {
      if (error.status == 401) {
        throw const AdminDataException('Your session expired. Sign in again.');
      }
      if (error.status == 403) {
        throw const AdminDataException(
          'Current course-management permission and multi-factor authentication are required.',
        );
      }
      if (error.status == 409) {
        final details = error.details;
        final errorData = details is Map ? details['error'] : null;
        final code = errorData is Map ? errorData['code'] : null;
        throw AdminDataException(switch (code) {
          'UNPUBLISH_FIRST' =>
            'Unpublish this course before editing its curriculum.',
          'CONTENT_IN_USE' =>
            'This content is linked to existing purchases, progress or media and must be retained.',
          'COURSE_NOT_READY' =>
            'This course is not ready to publish. Complete its metadata and published curriculum first.',
          _ =>
            'This course changed while you were editing. Reload to review current changes before saving.',
        });
      }
      if (error.status == 400 || error.status == 422) {
        throw const AdminDataException(
          'Check the course fields and publication readiness. Unpublish before editing curriculum.',
        );
      }
      throw const AdminDataException(
        'Unable to complete the course action. Retry.',
      );
    }
  }

  Future<void> _write(
    String action,
    String courseId, [
    Map<String, dynamic>? payload,
    String? expected,
  ]) async {
    if (!_busy.add(courseId)) {
      throw const AdminDataException(
        'A course change is already being saved. Wait and retry.',
      );
    }
    try {
      final body = <String, dynamic>{
        'action': action,
        'course_id': courseId,
        if (action != 'create')
          'expected_updated_at':
              expected ??
              (action == 'update'
                  ? _revision(courseId)
                  : _curriculumRevisions[courseId] ?? _revision(courseId)),
        'payload': ?payload,
      };
      final signature = jsonEncode(body);
      final requestId = _requestIds.putIfAbsent(signature, newAdminCourseId);
      body['request_id'] = requestId;
      final data = await _invoke('admin-course-management', body);
      _revisions[courseId] = data['updated_at'] as String;
      _ownMutationRevisions[courseId] = data['updated_at'] as String;
      if (action != 'create' && action != 'update') {
        _curriculumRevisions[courseId] = data['updated_at'] as String;
      }
      _requestIds.remove(signature);
    } finally {
      _busy.remove(courseId);
    }
  }

  @override
  Future<void> createCourse(AdminCourse course) =>
      _write('create', course.id, _metadata(course));
  @override
  Future<void> updateCourse(AdminCourse course) =>
      _write('update', course.id, _metadata(course), course.rawUpdatedAt);
  @override
  Future<void> archiveCourse(String courseId, {String? expectedUpdatedAt}) =>
      _write(
        'archive',
        courseId,
        const {},
        expectedUpdatedAt ?? _revision(courseId),
      );
  Future<void> _publish(
    String courseId,
    String action, {
    String? expectedUpdatedAt,
  }) async {
    if (!_busy.add(courseId)) {
      throw const AdminDataException(
        'A course change is already being saved. Wait and retry.',
      );
    }
    try {
      final body = {
        'course_id': courseId,
        'expected_updated_at': expectedUpdatedAt ?? _revision(courseId),
        'action': action,
      };
      final signature = jsonEncode(body);
      final id = _requestIds.putIfAbsent(signature, newAdminCourseId);
      final data = await _invoke(
        'admin-publish-course',
        body,
        headers: {'Idempotency-Key': id},
      );
      _revisions[courseId] = data['updated_at'] as String;
      _ownMutationRevisions[courseId] = data['updated_at'] as String;
      _requestIds.remove(signature);
    } finally {
      _busy.remove(courseId);
    }
  }

  @override
  Future<void> publishCourse(String courseId, {String? expectedUpdatedAt}) =>
      _publish(courseId, 'publish', expectedUpdatedAt: expectedUpdatedAt);
  @override
  Future<void> unpublishCourse(String courseId, {String? expectedUpdatedAt}) =>
      _publish(courseId, 'unpublish', expectedUpdatedAt: expectedUpdatedAt);
  @override
  Future<List<AdminCurriculumSection>> getCurriculum(String courseId) async {
    final data = await _invoke('admin-course-management', {
      'action': 'curriculum',
      'course_id': courseId,
    });
    _revisions[courseId] = data['updated_at'] as String;
    _curriculumRevisions[courseId] = data['updated_at'] as String;
    return (data['sections'] as List).map((raw) {
      final row = raw as Map;
      final id = row['id'] as String;
      _sectionCourses[id] = courseId;
      return AdminCurriculumSection(
        id: id,
        courseId: courseId,
        rawCourseUpdatedAt: data['updated_at'] as String,
        title: row['title'] as String,
        sortOrder: (row['position'] as num).toInt(),
        isPublished: row['is_published'] as bool,
        lessons: (row['lessons'] as List).map((rawLesson) {
          final lesson = rawLesson as Map;
          final lessonId = lesson['id'] as String;
          _lessonCourses[lessonId] = courseId;
          return AdminLesson(
            id: lessonId,
            rawCourseUpdatedAt: data['updated_at'] as String,
            sectionId: id,
            courseId: courseId,
            title: lesson['title'] as String,
            description: lesson['description'] as String? ?? '',
            lessonType: LessonType.values.byName(
              lesson['lesson_type'] as String,
            ),
            sortOrder: (lesson['position'] as num).toInt(),
            isPreviewed: lesson['is_preview'] as bool,
            isPublished: lesson['is_published'] as bool,
            durationSeconds: (lesson['duration_seconds'] as num?)?.toInt(),
          );
        }).toList(),
      );
    }).toList();
  }

  @override
  Future<void> upsertSection(AdminCurriculumSection section) =>
      _write('upsert_section', section.courseId, {
        'id': section.id,
        'title': section.title,
        'position': section.sortOrder,
        'is_published': section.isPublished,
      }, section.rawCourseUpdatedAt);
  @override
  Future<void> deleteSection(String sectionId, {String? expectedUpdatedAt}) =>
      _write(
        'delete_section',
        _sectionCourses[sectionId] ??
            (throw const AdminDataException(
              'Reload the curriculum before deleting a section.',
            )),
        {'id': sectionId},
        expectedUpdatedAt,
      );
  @override
  Future<void> upsertLesson(AdminLesson lesson) {
    if (lesson.lessonType == LessonType.quiz) {
      throw const AdminDataException('Quiz lessons are not supported.');
    }
    return _write('upsert_lesson', lesson.courseId, {
      'id': lesson.id,
      'section_id': lesson.sectionId,
      'title': lesson.title,
      'description': lesson.description,
      'lesson_type': lesson.lessonType.name,
      'position': lesson.sortOrder,
      'is_preview': lesson.isPreviewed,
      'is_published': lesson.isPublished,
      'duration_seconds': lesson.durationSeconds,
    }, lesson.rawCourseUpdatedAt);
  }

  @override
  Future<void> deleteLesson(String lessonId, {String? expectedUpdatedAt}) =>
      _write(
        'delete_lesson',
        _lessonCourses[lessonId] ??
            (throw const AdminDataException(
              'Reload the curriculum before deleting a lesson.',
            )),
        {'id': lessonId},
        expectedUpdatedAt,
      );
  @override
  Future<void> reorderSections(
    String courseId,
    List<String> ids, {
    String? expectedUpdatedAt,
  }) => _write('reorder_sections', courseId, {'ids': ids}, expectedUpdatedAt);
  @override
  Future<void> reorderLessons(
    String courseId,
    String sectionId,
    List<String> ids, {
    String? expectedUpdatedAt,
  }) => _write('reorder_lessons', courseId, {
    'section_id': sectionId,
    'ids': ids,
  }, expectedUpdatedAt);
}

/// Cache boundary only; backend authorization still verifies every request.
({String userId, String sessionId, String aal})? adminCourseSessionBoundary(
  Session? session,
) {
  if (session == null) return null;
  try {
    final claims =
        jsonDecode(
              utf8.decode(
                base64Url.decode(
                  base64Url.normalize(session.accessToken.split('.')[1]),
                ),
              ),
            )
            as Map<String, dynamic>;
    return (
      userId: session.user.id,
      sessionId: claims['session_id'] as String? ?? session.accessToken,
      aal: claims['aal'] as String? ?? 'aal1',
    );
  } catch (_) {
    return (
      userId: session.user.id,
      sessionId: session.accessToken,
      aal: 'unknown',
    );
  }
}

final adminCourseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);
final adminCourseRepositoryProvider = Provider<AdminCourseRepository>((ref) {
  final boundary = ref.watch(
    currentSessionProvider.select(adminCourseSessionBoundary),
  );
  if (boundary == null) {
    throw const AdminDataException('Your session expired. Sign in again.');
  }
  return SupabaseAdminCourseRepository(ref.watch(adminCourseClientProvider));
});
