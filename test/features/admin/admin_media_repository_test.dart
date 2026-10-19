import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:acendra/features/admin/data/repositories/admin_media_repository.dart';
import 'package:acendra/features/admin/domain/media_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const course = '26700000-0000-0000-0000-000000000001';
  const asset = '26700000-0000-0000-0000-000000000002';
  late HttpServer server;
  late SupabaseClient client;
  late List<String> calls;
  late Map<String, dynamic> reservation;
  Map<String, dynamic>? prepareBody;
  var inspectionFails = false;
  var swapSession = false;
  Future<void> signIn(String id) async {
    final claims = base64Url
        .encode(
          utf8.encode(
            jsonEncode({
              'sub': id,
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
          'id': id,
          'app_metadata': {},
          'user_metadata': {},
          'aud': 'authenticated',
          'created_at': '2026-10-19T00:00:00Z',
        },
      }),
    );
  }

  setUp(() async {
    calls = [];
    prepareBody = null;
    inspectionFails = false;
    swapSession = false;
    reservation = {
      'asset_id': asset,
      'upload': {
        'mode': 'supabase_signed_upload',
        'bucket': 'course-media',
        'path': '$course/thumbnails/$asset.png',
        'token': 'private-token',
      },
    };
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'public-test');
    await signIn('26700000-0000-0000-0000-000000000003');
    server.listen((request) async {
      calls.add(request.uri.path);
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path.endsWith('admin-create-media-upload')) {
        prepareBody =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        request.response.statusCode = 201;
        if (swapSession) await signIn('26700000-0000-0000-0000-000000000004');
        request.response.write(jsonEncode({'data': reservation}));
      } else if (request.uri.path.contains('/storage/')) {
        expect(request.method, 'PUT');
        expect(request.uri.queryParameters['token'], 'private-token');
        expect(request.headers.value('x-upsert'), isNot('true'));
        await request.drain<void>();
        request.response.write(jsonEncode({'Key': 'synthetic'}));
      } else {
        await request.drain<void>();
        request.response.statusCode = inspectionFails ? 422 : 200;
        request.response.write(
          jsonEncode({
            'data': {
              'asset_id': asset,
              'status': inspectionFails ? 'pending' : 'validated',
            },
          }),
        );
      }
      await request.response.close();
    });
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });
  Future<void> upload() => SupabaseAdminMediaRepository(client).upload(
    courseId: course,
    file: MediaFile(
      name: 'my artwork.png',
      bytes: Uint8List.fromList([1, 2, 3]),
    ),
  );

  test(
    'real signed upload completes only after inspected finalization',
    () async {
      await upload();
      expect(calls.length, 3);
      expect(prepareBody!['asset_type'], 'public_thumbnail');
      expect(prepareBody!['file_name'], 'media.png');
      expect(prepareBody!['lesson_id'], isNull);
      expect(prepareBody!['request_id'], matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(calls.last, endsWith('admin-finalize-media-upload'));
    },
  );
  test('foreign path is rejected before any Storage write', () async {
    (reservation['upload'] as Map)['path'] = 'foreign/private.png';
    await expectLater(upload(), throwsFormatException);
    expect(calls.length, 1);
  });
  test('inspection failure cannot report success', () async {
    inspectionFails = true;
    await expectLater(upload(), throwsFormatException);
    expect(calls.length, 3);
  });
  test(
    'identity change between prepare and upload prevents Storage write',
    () async {
      swapSession = true;
      await expectLater(upload(), throwsFormatException);
      expect(calls.length, 1);
    },
  );
  test('unsupported and oversized files fail before network', () async {
    expect(mediaFileError('cover.svg', 10, pdf: false), isNotNull);
    expect(mediaFileError('cover.png', 5242881, pdf: false), isNotNull);
    expect(mediaFileError('lesson.pdf', 52428800, pdf: true), isNull);
    await expectLater(
      SupabaseAdminMediaRepository(client).upload(
        courseId: course,
        file: MediaFile(name: 'cover.svg', bytes: Uint8List(2)),
      ),
      throwsFormatException,
    );
    expect(calls, isEmpty);
  });
}
