import 'package:acendra/features/video_player/data/video_authorization_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const lesson = '11111111-1111-4111-8111-111111111111';
final now = DateTime.utc(2026, 10, 15);
Map<String, dynamic> response({
  String? url,
  int? expiry,
  String id = lesson,
}) => {
  'data': {
    'lesson_id': id,
    'expires_at': expiry ?? now.millisecondsSinceEpoch ~/ 1000 + 300,
    'playback_url':
        url ??
        'https://stream.mux.com/PrivatePlayback123.m3u8?token=header.payload.signature',
  },
};
void main() {
  test(
    'authorization submits lesson identity only and accepts exact private Mux delivery',
    () async {
      final repo = VideoAuthorizationRepository((body) async {
        expect(body, {'lesson_id': lesson});
        return FunctionResponse(status: 200, data: response());
      }, clock: () => now);
      final video = await repo.authorize(lesson);
      expect(video.url.host, 'stream.mux.com');
      expect(video.expiresAt, now.add(const Duration(seconds: 300)));
    },
  );
  for (final url in [
    'http://stream.mux.com/id.m3u8?token=a.b.c',
    'https://evil.test/id.m3u8?token=a.b.c',
    'https://stream.mux.com.evil.test/id.m3u8?token=a.b.c',
    'https://user@stream.mux.com/id.m3u8?token=a.b.c',
    'https://stream.mux.com:444/id.m3u8?token=a.b.c',
    'https://stream.mux.com/id.m3u8',
    'https://stream.mux.com/id.m3u8?token=a.b.c&token=d.e.f',
    'https://stream.mux.com/id.m3u8?token=a.b.c&public=true',
    'https://stream.mux.com/id.m3u8?token=a.b.c#fragment',
    'https://stream.mux.com/id.mp4?token=a.b.c',
  ]) {
    test('unsafe/malformed delivery denied: $url', () async {
      final repo = VideoAuthorizationRepository(
        (body) async => FunctionResponse(status: 200, data: response(url: url)),
        clock: () => now,
      );
      await expectLater(
        repo.authorize(lesson),
        throwsA(isA<VideoAuthorizationException>()),
      );
    });
  }
  for (final seconds in [-1, 0, 301]) {
    test('expired or excessive authorization $seconds denied', () async {
      final repo = VideoAuthorizationRepository(
        (body) async => FunctionResponse(
          status: 200,
          data: response(expiry: now.millisecondsSinceEpoch ~/ 1000 + seconds),
        ),
        clock: () => now,
      );
      await expectLater(
        repo.authorize(lesson),
        throwsA(isA<VideoAuthorizationException>()),
      );
    });
  }
  test('wrong lesson is denied', () async {
    final repo = VideoAuthorizationRepository(
      (body) async =>
          FunctionResponse(status: 200, data: response(id: 'other-lesson')),
      clock: () => now,
    );
    await expectLater(
      repo.authorize(lesson),
      throwsA(isA<VideoAuthorizationException>()),
    );
  });
  for (final status in [401, 403, 503]) {
    test(
      'SDK $status denial never leaks bearer URL or grants fallback',
      () async {
        final repo = VideoAuthorizationRepository(
          (body) async => throw FunctionException(
            status: status,
            details: 'https://stream.mux.com/private.m3u8?token=SECRET',
          ),
        );
        await expectLater(
          repo.authorize(lesson),
          throwsA(
            isA<VideoAuthorizationException>().having(
              (e) => e.message,
              'safe message',
              isNot(contains('SECRET')),
            ),
          ),
        );
      },
    );
  }
}
