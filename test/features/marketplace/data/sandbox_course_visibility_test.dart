import 'dart:convert';
import 'dart:io';

import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late SupabaseCourseRepository repository;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'synthetic-key');
    repository = SupabaseCourseRepository(client);
    server.listen((request) async {
      final sandbox = request.uri.queryParameters['id'] == 'eq.sandbox';
      final excluded =
          sandbox &&
          request.uri.queryParameters['title'] == 'not.ilike.SANDBOX TEST%';
      request.response.headers.contentType = ContentType.json;
      request.response.statusCode = excluded ? 406 : 200;
      request.response.write(
        jsonEncode(
          excluded
              ? {'code': 'PGRST116', 'message': 'No matching course'}
              : {
                  'id': sandbox ? 'sandbox' : 'public',
                  'slug': sandbox ? 'sandbox' : 'public',
                  'title': sandbox
                      ? 'SANDBOX TEST ONLY - Checkout Verification'
                      : 'Public Course',
                  'price_minor': 10000,
                  'currency_code': 'LKR',
                  'published_at': '2026-10-17T00:00:00Z',
                },
        ),
      );
      await request.response.close();
    });
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  test(
    'known sandbox fixture is excluded from direct course detail requests',
    () async {
      await expectLater(
        repository.getCourseDetail('sandbox'),
        throwsA(isA<PostgrestException>()),
      );
    },
  );
  test('public course detail remains accessible', () async {
    expect((await repository.getCourseDetail('public')).title, 'Public Course');
  });
}
