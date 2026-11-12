import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:acendra/features/admin/data/repositories/admin_course_repository.dart';
import 'package:acendra/features/admin/data/repositories/admin_directory_client.dart';
import 'package:acendra/features/admin/domain/entities/admin_course.dart';
import 'package:acendra/features/admin/domain/entities/curriculum_section.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const courseId = '6e5fd532-8833-4431-82ce-e765a9ef6eae';
const revision = '2026-10-20T00:00:00.123456+00:00';
Map<String, dynamic> courseRow() => {
  'id': courseId,
  'title': 'Exact price',
  'slug': 'exact-price',
  'category_id': null,
  'short_description': 'Overview',
  'description': 'Description',
  'price_minor': '1999',
  'currency_code': 'LKR',
  'status': 'draft',
  'enrollment_count': 0,
  'section_count': 0,
  'lesson_count': 0,
  'created_at': revision,
  'updated_at': revision,
};
AdminCourse course() => AdminCourse(
  id: courseId,
  title: 'Exact price',
  description: 'Description',
  price: 19.99,
  isPublished: false,
  enrollmentCount: 0,
  sectionCount: 0,
  lessonCount: 0,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
final _sessionState = StateProvider<Session?>((ref) => null);
Session _session(
  String userId,
  String sessionId,
  int expiry, {
  String aal = 'aal2',
}) {
  final header = base64Url.encode(utf8.encode('{}'));
  final claims = base64Url.encode(
    utf8.encode(
      jsonEncode({
        'sub': userId,
        'session_id': sessionId,
        'aal': aal,
        'exp': expiry,
      }),
    ),
  );
  return Session(
    accessToken: '$header.$claims.signature',
    tokenType: 'bearer',
    user: User(
      id: userId,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-10-20T00:00:00Z',
    ),
  );
}

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late SupabaseAdminCourseRepository repo;
  late List<({String path, Map<String, dynamic> body, String? key})> requests;
  late Map<String, dynamic> response;
  int status = 200;
  Completer<void>? hold;
  setUp(() async {
    status = 200;
    hold = null;
    requests = [];
    response = {'course_id': courseId, 'updated_at': revision};
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'test-key');
    repo = SupabaseAdminCourseRepository(client);
    server.listen((request) async {
      requests.add((
        path: request.uri.path,
        body:
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>,
        key: request.headers.value('idempotency-key'),
      ));
      if (hold != null) await hold!.future;
      request.response.headers.contentType = ContentType.json;
      request.response.statusCode = status;
      request.response.write(
        jsonEncode(status == 200 ? {'data': response} : response),
      );
      await request.response.close();
    });
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  test(
    'same-session refresh preserves repository, pending UUID and own acknowledged revision',
    () async {
      final container = ProviderContainer(
        overrides: [
          currentSessionProvider.overrideWith(
            (ref) => ref.watch(_sessionState),
          ),
          adminCourseClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);
      container.read(_sessionState.notifier).state = _session(
        'admin',
        'same-session',
        1,
      );
      final before = container.read(adminCourseRepositoryProvider);
      status = 503;
      response = {
        'error': {'code': 'UNAVAILABLE'},
      };
      await expectLater(
        before.createCourse(course()),
        throwsA(isA<AdminDataException>()),
      );
      final requestId = requests.single.body['request_id'];
      container.read(_sessionState.notifier).state = _session(
        'admin',
        'same-session',
        2,
      );
      final refreshed = container.read(adminCourseRepositoryProvider);
      expect(identical(before, refreshed), true);
      status = 200;
      response = {'course_id': courseId, 'updated_at': revision};
      await refreshed.createCourse(course());
      expect(requests.last.body['request_id'], requestId);
      expect(
        (refreshed as AdminCourseMutationRevisions).ownMutationRevision(
          courseId,
        ),
        revision,
      );
      container.read(_sessionState.notifier).state = _session(
        'admin',
        'new-session',
        3,
      );
      expect(
        identical(refreshed, container.read(adminCourseRepositoryProvider)),
        false,
      );
      final other = container.read(adminCourseRepositoryProvider);
      container.read(_sessionState.notifier).state = _session(
        'admin',
        'new-session',
        4,
        aal: 'aal1',
      );
      expect(
        identical(other, container.read(adminCourseRepositoryProvider)),
        false,
      );
    },
  );

  test(
    'delete and reorder pin visible curriculum revision across independent reads',
    () async {
      response = {
        'updated_at': revision,
        'sections': [
          {
            'id': 'section',
            'title': 'Section',
            'position': 0,
            'is_published': false,
            'lessons': [
              {
                'id': 'lesson',
                'title': 'Lesson',
                'description': 'Metadata',
                'lesson_type': 'text',
                'position': 0,
                'is_preview': false,
                'is_published': false,
                'duration_seconds': null,
              },
            ],
          },
        ],
      };
      final visible = (await repo.getCurriculum(courseId)).single;
      const newer = '2026-10-20T03:00:00.111111+00:00';
      response['updated_at'] = newer;
      await repo.getCurriculum(courseId);
      status = 409;
      response = {
        'error': {'code': 'COURSE_CONFLICT'},
      };
      await expectLater(
        repo.deleteSection(
          'section',
          expectedUpdatedAt: visible.rawCourseUpdatedAt,
        ),
        throwsA(isA<AdminDataException>()),
      );
      expect(requests.last.body['expected_updated_at'], revision);
      await expectLater(
        repo.deleteLesson(
          'lesson',
          expectedUpdatedAt: visible.lessons.single.rawCourseUpdatedAt,
        ),
        throwsA(isA<AdminDataException>()),
      );
      expect(requests.last.body['expected_updated_at'], revision);
      await expectLater(
        repo.reorderSections(courseId, [
          'section',
        ], expectedUpdatedAt: visible.rawCourseUpdatedAt),
        throwsA(isA<AdminDataException>()),
      );
      expect(requests.last.body['expected_updated_at'], revision);
      await expectLater(
        repo.reorderLessons(courseId, 'section', [
          'lesson',
        ], expectedUpdatedAt: visible.rawCourseUpdatedAt),
        throwsA(isA<AdminDataException>()),
      );
      expect(requests.last.body['expected_updated_at'], revision);
    },
  );
  test(
    'publication pins acknowledged revision across background reads',
    () async {
      await repo.createCourse(course());
      expect(repo.ownMutationRevision(courseId), revision);
      const newer = '2026-10-20T02:00:00.654321+00:00';
      response = {
        'course': {...courseRow(), 'updated_at': newer},
        'categories': <dynamic>[],
      };
      final reviewed = await repo.getCourse(courseId);
      expect(repo.ownMutationRevision(courseId), revision);
      status = 409;
      response = {
        'error': {'code': 'COURSE_CONFLICT'},
      };
      await expectLater(
        repo.publishCourse(courseId, expectedUpdatedAt: revision),
        throwsA(isA<AdminDataException>()),
      );
      expect(requests.last.body['expected_updated_at'], revision);
      status = 200;
      response = {'course_id': courseId, 'updated_at': newer};
      await repo.publishCourse(
        courseId,
        expectedUpdatedAt: reviewed.rawUpdatedAt,
      );
      expect(requests.last.body['expected_updated_at'], newer);
    },
  );
  test(
    'create sends exact minor price and a UUID to trusted endpoint',
    () async {
      await repo.createCourse(course());
      expect(requests.single.path, '/functions/v1/admin-course-management');
      expect(requests.single.body['action'], 'create');
      expect((requests.single.body['payload'] as Map)['price_minor'], '1999');
      expect(
        requests.single.body['request_id'],
        matches(RegExp(r'^[0-9a-f-]{36}$')),
      );
      expect(
        (requests.single.body['payload'] as Map).containsKey('status'),
        false,
      );
    },
  );
  test(
    'course removal archives using the revision shown before confirmation',
    () async {
      await repo.createCourse(course());
      response = {
        'course': {
          ...courseRow(),
          'updated_at': '2026-10-20T02:00:00.654321+00:00',
        },
        'categories': <dynamic>[],
      };
      await repo.getCourse(courseId);
      response = {'course_id': courseId, 'updated_at': revision};
      await repo.archiveCourse(courseId, expectedUpdatedAt: revision);
      expect(requests.last.path, '/functions/v1/admin-course-management');
      expect(requests.last.body['action'], 'archive');
      expect(requests.last.body['expected_updated_at'], revision);
      expect(requests.last.body['payload'], isEmpty);
    },
  );
  test(
    'update preserves original raw revision even after another read',
    () async {
      response = {'course': courseRow(), 'categories': <dynamic>[]};
      final original = await repo.getCourse(courseId);
      response = {
        'course': {
          ...courseRow(),
          'updated_at': '2026-10-20T01:00:00.654321+00:00',
        },
        'categories': <dynamic>[],
      };
      await repo.getCourse(courseId);
      response = {
        'course_id': courseId,
        'updated_at': '2026-10-20T02:00:00.654321+00:00',
      };
      await repo.updateCourse(original.copyWith(title: 'Changed'));
      expect(requests.last.body['expected_updated_at'], revision);
      expect((requests.last.body['payload'] as Map)['slug'], 'exact-price');
      expect(
        (requests.last.body['payload'] as Map)['short_description'],
        'Overview',
      );
    },
  );
  test(
    'publication is explicit and carries revision and idempotency header',
    () async {
      await repo.createCourse(course());
      await repo.publishCourse(courseId);
      expect(requests.last.path, '/functions/v1/admin-publish-course');
      expect(requests.last.body, {
        'course_id': courseId,
        'expected_updated_at': revision,
        'action': 'publish',
      });
      expect(requests.last.key, matches(RegExp(r'^[0-9a-f-]{36}$')));
      await repo.unpublishCourse(courseId);
      expect(requests.last.body['action'], 'unpublish');
    },
  );
  test(
    'curriculum reads map image and publication, writes use atomic reorders',
    () async {
      response = {
        'updated_at': revision,
        'sections': [
          {
            'id': 'section',
            'course_id': courseId,
            'title': 'Section',
            'position': 3,
            'is_published': true,
            'lessons': [
              {
                'id': 'lesson',
                'section_id': 'section',
                'course_id': courseId,
                'title': 'Image',
                'description': 'Metadata',
                'lesson_type': 'image',
                'position': 7,
                'is_preview': false,
                'is_published': true,
                'duration_seconds': null,
              },
            ],
          },
        ],
      };
      final section = (await repo.getCurriculum(courseId)).single;
      expect(section.lessons.single.lessonType.name, 'image');
      expect(section.lessons.single.sortOrder, 7);
      expect(section.isPublished, true);
      response = {'course_id': courseId, 'updated_at': revision};
      await repo.upsertLesson(section.lessons.single.copyWith(title: 'Edited'));
      expect((requests.last.body['payload'] as Map)['section_id'], 'section');
      expect((requests.last.body['payload'] as Map)['position'], 7);
      await repo.reorderSections(courseId, ['section']);
      expect(requests.last.body['action'], 'reorder_sections');
      await repo.reorderLessons(courseId, 'section', ['lesson']);
      expect(requests.last.body['action'], 'reorder_lessons');
      expect((requests.last.body['payload'] as Map)['ids'], ['lesson']);
      await repo.deleteLesson('lesson');
      expect(requests.last.body['action'], 'delete_lesson');
      await repo.deleteSection('section');
      expect(requests.last.body['action'], 'delete_section');
    },
  );
  test('duplicates cannot race while a write is in flight', () async {
    hold = Completer<void>();
    final saving = repo.createCourse(course());
    await expectLater(
      repo.createCourse(course()),
      throwsA(isA<AdminDataException>()),
    );
    hold!.complete();
    await saving;
    expect(requests.length, 1);
  });
  test('ambiguous retry preserves request UUID', () async {
    status = 503;
    response = {
      'error': {'code': 'UNAVAILABLE'},
    };
    await expectLater(
      repo.createCourse(course()),
      throwsA(isA<AdminDataException>()),
    );
    final requestId = requests.single.body['request_id'];
    status = 200;
    response = {'course_id': courseId, 'updated_at': revision};
    await repo.createCourse(course());
    expect(requests.last.body['request_id'], requestId);
  });
  for (final entry in {
    'UNPUBLISH_FIRST': 'Unpublish',
    'CONTENT_IN_USE': 'must be retained',
    'COURSE_NOT_READY': 'not ready',
    'COURSE_CONFLICT': 'changed while',
  }.entries) {
    test('safe conflict message for ${entry.key}', () async {
      await repo.createCourse(course());
      status = 409;
      response = {
        'error': {'code': entry.key, 'message': 'private database diagnostic'},
      };
      await expectLater(
        repo.publishCourse(courseId),
        throwsA(
          isA<AdminDataException>().having(
            (e) => e.message,
            'safe actionable error',
            contains(entry.value),
          ),
        ),
      );
    });
  }
  test(
    'decimal parsing is exact and rejects negative/non-finite/overprecision',
    () {
      expect(
        adminCoursePriceMinor('92233720368547758.07'),
        '9223372036854775807',
      );
      expect(adminCoursePriceMinor('92233720368547758.08'), null);
      expect(
        adminCoursePriceText('9223372036854775807'),
        '92233720368547758.07',
      );
      expect(
        course().copyWith(priceMinor: '9223372036854775807').priceText,
        '92233720368547758.07',
      );
      expect(course().copyWith(priceMinor: '300000').priceText, '3000');
      expect(adminCoursePriceMinor('19.99'), '1999');
      expect(adminCoursePriceMinor('0.01'), '1');
      expect(adminCoursePriceMinor('2.5'), '250');
      expect(adminCoursePriceText('1999'), '19.99');
      for (final value in ['-1', 'NaN', 'Infinity', '1.001', '1e4']) {
        expect(adminCoursePriceMinor(value), null);
      }
    },
  );
  test(
    'section publication metadata is sent without direct table writes',
    () async {
      await repo.createCourse(course());
      await repo.upsertSection(
        const AdminCurriculumSection(
          id: 'section',
          courseId: courseId,
          title: 'Renamed',
          sortOrder: 2,
          isPublished: true,
          lessons: [],
        ),
      );
      expect(requests.last.body['action'], 'upsert_section');
      expect((requests.last.body['payload'] as Map)['is_published'], true);
    },
  );
}
