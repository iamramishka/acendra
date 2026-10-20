import 'dart:convert';
import 'dart:io';
import 'package:acendra/features/admin/data/repositories/admin_artwork_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const course = '26700000-0000-0000-0000-000000000001';
  late HttpServer server;
  late SupabaseClient client;
  var requests = 0;
  var swap = false;
  var json = false;
  Future<void> signIn(String actor) async {
    final claims = base64Url
        .encode(
          utf8.encode(
            jsonEncode({
              'sub': actor,
              'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
            }),
          ),
        )
        .replaceAll('=', '');
    await client.auth.recoverSession(
      jsonEncode({
        'access_token': 'x.$claims.x',
        'token_type': 'bearer',
        'refresh_token': 'synthetic',
        'user': {
          'id': actor,
          'aud': 'authenticated',
          'app_metadata': {},
          'user_metadata': {},
          'created_at': '2026-10-19T00:00:00Z',
        },
      }),
    );
  }

  setUp(() async {
    requests = 0;
    swap = false;
    json = false;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'public-test');
    server.listen((request) async {
      requests++;
      expect(request.method, 'GET');
      expect(request.uri.queryParameters, {'course_id': course});
      expect(request.headers.value('authorization'), startsWith('Bearer x.'));
      expect(request.headers.value('accept'), 'application/octet-stream');
      if (swap) await signIn('26700000-0000-0000-0000-000000000004');
      request.response.headers.contentType = json
          ? ContentType.json
          : ContentType.binary;
      request.response.add(json ? utf8.encode('{}') : [137, 80, 78, 71]);
      await request.response.close();
    });
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });
  test(
    'draft fetch sends bearer header and reads SDK binary response',
    () async {
      await signIn('26700000-0000-0000-0000-000000000003');
      expect(await SupabaseAdminArtworkRepository(client).read(course), [
        137,
        80,
        78,
        71,
      ]);
      expect(requests, 1);
    },
  );
  test('signed out cannot request draft artwork', () async {
    await expectLater(
      SupabaseAdminArtworkRepository(client).read(course),
      throwsFormatException,
    );
    expect(requests, 0);
  });
  test('changed account discards pending bytes', () async {
    await signIn('26700000-0000-0000-0000-000000000003');
    swap = true;
    await expectLater(
      SupabaseAdminArtworkRepository(client).read(course),
      throwsFormatException,
    );
  });
  test('malformed binary response cannot become an image', () async {
    await signIn('26700000-0000-0000-0000-000000000003');
    json = true;
    await expectLater(
      SupabaseAdminArtworkRepository(client).read(course),
      throwsFormatException,
    );
  });
}
