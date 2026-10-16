import 'dart:convert';
import 'dart:io';

import 'package:acendra/features/admin/data/repositories/admin_directory_client.dart';
import 'package:acendra/features/admin/data/repositories/admin_course_repository.dart';
import 'package:acendra/features/admin/data/repositories/admin_student_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late Map<String, dynamic> payload;
  late List<Map<String, dynamic>> requests;
  var status = 200;
  setUp(() async {
    status = 200;
    payload = {'items': [], 'next_after_id': null};
    requests = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'synthetic-key');
    server.listen((request) async {
      expect(request.uri.path, '/functions/v1/admin-directory');
      requests.add(
        jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>,
      );
      request.response.headers.contentType = ContentType.json;
      request.response.statusCode = status;
      request.response.write(jsonEncode({'data': payload}));
      await request.response.close();
    });
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });
  test('empty directories remain empty without seeded records', () async {
    expect(await SupabaseAdminCourseRepository(client).listCourses(), isEmpty);
    expect(
      await SupabaseAdminStudentRepository(client).listStudents(),
      isEmpty,
    );
    expect(requests.map((r) => r['resource']), ['courses', 'students']);
  });
  test(
    'student data uses server records and unavailable payment totals',
    () async {
      payload['items'] = [
        {
          'id': 'student',
          'email': 'actual@synthetic.test',
          'display_name': 'Actual',
          'enrolled_course_count': 3,
          'total_paid_minor': null,
          'currency_code': 'LKR',
          'created_at': '2026-10-17T00:00:00Z',
          'is_active': true,
        },
      ];
      final records = await SupabaseAdminStudentRepository(
        client,
      ).listStudents(searchQuery: ' Actual ');
      expect(records.single.email, 'actual@synthetic.test');
      expect(records.single.enrolledCourseCount, 3);
      expect(records.single.totalAmountPaid, isNull);
      expect(requests.single['search'], 'Actual');
    },
  );
  test('authorization failures never become mock success', () async {
    status = 403;
    await expectLater(
      SupabaseAdminStudentRepository(client).listStudents(),
      throwsA(isA<AdminDataException>()),
    );
    await expectLater(
      SupabaseAdminCourseRepository(client).publishCourse('course'),
      throwsA(isA<AdminDataException>()),
    );
    expect(requests.length, 1);
  });
  test('sandbox course is mapped from stored directory metadata', () async {
    payload['items'] = [
      {
        'id': 'sandbox',
        'title': 'Sandbox',
        'description': 'Stored description',
        'thumbnail_url': null,
        'price_minor': '15000',
        'currency_code': 'LKR',
        'status': 'draft',
        'enrollment_count': 2,
        'section_count': 1,
        'lesson_count': 4,
        'created_at': '2026-10-17T00:00:00Z',
        'updated_at': '2026-10-17T00:00:00Z',
      },
    ];
    final course = (await SupabaseAdminCourseRepository(
      client,
    ).listCourses()).single;
    expect(course.id, 'sandbox');
    expect(course.price, 150);
    expect(course.isPublished, false);
    expect(course.lessonCount, 4);
  });
}
