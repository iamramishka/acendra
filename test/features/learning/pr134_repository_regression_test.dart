import 'dart:convert';
import 'dart:io';

import 'package:acendra/features/learning/data/repositories/supabase_learning_repository.dart';
import 'package:acendra/features/my_courses/data/repositories/supabase_my_courses_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late List<Uri> requests;

  setUp(() async {
    requests = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'test-key');
    server.listen((request) async {
      requests.add(request.uri);
      request.response.headers.contentType = ContentType.json;
      final selection = request.uri.queryParameters['select'] ?? '';
      if (selection.contains('content_text') ||
          selection.contains('content_image_url') ||
          selection.contains('thumbnail_url') ||
          selection == '*') {
        request.response.statusCode = 400;
        request.response.write(
          jsonEncode({
            'message': 'Unknown or ungranted column',
            'code': '42703',
          }),
        );
      } else if (request.uri.path.endsWith('/lessons')) {
        request.response.write(
          jsonEncode({
            'id': 'lesson',
            'title': 'Lesson',
            'lesson_type': 'text',
            'position': 0,
            'section_id': 'section',
          }),
        );
      } else if (request.uri.path.endsWith('/enrollments')) {
        request.response.write(
          jsonEncode([
            {
              'id': 'enrollment',
              'course_id': 'course',
              'status': 'active',
              'created_at': '2026-10-13T00:00:00Z',
              'courses': {
                'id': 'course',
                'title': 'Course',
                'short_description': 'Description',
              },
            },
          ]),
        );
      } else {
        request.response.write('[]');
      }
      await request.response.close();
    });
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  test('curriculum loads using metadata columns only', () async {
    expect(
      await SupabaseLearningRepository(
        client,
      ).getCurriculumWithLessons('course'),
      isEmpty,
    );
    expect(requests.single.queryParameters['course_id'], 'eq.course');
  });
  test(
    'lesson metadata does not pretend to contain protected content',
    () async {
      final lesson = await SupabaseLearningRepository(
        client,
      ).getLessonContent('lesson');
      expect(lesson.id, 'lesson');
      expect(lesson.contentText, isNull);
      expect(lesson.contentImageUrl, isNull);
    },
  );
  test('own courses load without an invented thumbnail URL column', () async {
    final courses = await SupabaseMyCoursesRepository(client).listEnrolled();
    expect(courses.single.title, 'Course');
    expect(courses.single.thumbnailUrl, isNull);
  });
}
