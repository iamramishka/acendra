import 'dart:convert';
import 'dart:io';

import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  final queries = <Map<String, String>>[];

  setUp(() async {
    queries.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'synthetic-key');
    server.listen((request) async {
      queries.add(request.uri.queryParameters);
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(<Object>[]));
      await request.response.close();
    });
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  test(
    'catalog listing asks the backend to exclude the sandbox fixture',
    () async {
      await SupabaseCourseRepository(client).listPublished();

      expect(queries, hasLength(1));
      expect(queries.single['status'], 'eq.published');
      expect(queries.single['title'], 'not.ilike.SANDBOX TEST%');
    },
  );
}
