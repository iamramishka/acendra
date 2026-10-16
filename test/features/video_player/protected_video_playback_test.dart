import 'dart:async';

import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/video_player/data/video_authorization_repository.dart';
import 'package:acendra/features/video_player/domain/entities/video_progress.dart';
import 'package:acendra/features/video_player/presentation/widgets/authorized_video_widget.dart';
import 'package:acendra/features/video_player/presentation/widgets/video_error_state.dart';
import 'package:acendra/features/video_player/presentation/widgets/video_loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Stable UUIDs used across tests — never real student or lesson IDs.
const _lesson = '22222222-2222-4222-8222-222222222222';
final _now = DateTime.utc(2026, 10, 15);

Session _session(String id) => Session(
  accessToken: 'synthetic-token-$id',
  tokenType: 'bearer',
  user: User(
    id: id,
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-10-15T00:00:00Z',
  ),
);

/// Builds a FunctionResponse that passes all security checks in
/// VideoAuthorizationRepository when clocked at [_now].
FunctionResponse _validAuthResponse({
  int expiryOffsetSeconds = 120,
}) => FunctionResponse(
  status: 200,
  data: {
    'data': {
      'lesson_id': _lesson,
      'expires_at': _now.millisecondsSinceEpoch ~/ 1000 + expiryOffsetSeconds,
      'playback_url':
          'https://stream.mux.com/PrivatePlayback123.m3u8?token=header.payload.signature',
    },
  },
);

/// Minimal widget tree using provider overrides — mirrors the pattern in
/// authorized_video_widget_test.dart.
Widget _app({
  required VideoInvoke invoke,
  bool signedOut = false,
  String? lessonId,
  int? initialVideoSeconds,
  ValueChanged<int>? onVideoSeconds,
}) => ProviderScope(
  overrides: [
    currentSessionProvider.overrideWith(
      (ref) => signedOut ? null : _session('student-a'),
    ),
    videoAuthorizationRepositoryProvider.overrideWithValue(
      VideoAuthorizationRepository(invoke, clock: () => _now),
    ),
  ],
  child: MaterialApp(
    home: Scaffold(
      body: AuthorizedVideoWidget(
        lessonId: lessonId ?? _lesson,
        title: 'Protected Lesson',
        initialVideoSeconds: initialVideoSeconds,
        onVideoSeconds: onVideoSeconds,
      ),
    ),
  ),
);

void main() {
  // ---------------------------------------------------------------------------
  // 1. Authorization: entitlement and denial scenarios
  // ---------------------------------------------------------------------------
  group('Protected video — authorization denial', () {
    testWidgets(
      'student without entitlement (403) sees access-denied message',
      (tester) async {
        await tester.pumpWidget(
          _app(
            invoke: (body) async => throw const FunctionException(
              status: 403,
              details: 'no active enrollment',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('do not currently have access'),
          findsOneWidget,
        );
        // Loading state must be gone after settling.
        expect(find.byType(VideoLoadingState), findsNothing);
      },
    );

    testWidgets('unauthenticated request (401) shows sign-in prompt', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          invoke: (body) async => throw const FunctionException(
            status: 401,
            details: 'missing bearer token',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('sign in again'), findsOneWidget);
    });

    testWidgets(
      'VideoAuthorizationException propagates its message to the UI',
      (tester) async {
        const expiredMsg = 'Video authorization expired. Request access again.';
        await tester.pumpWidget(
          _app(
            invoke: (body) async =>
                throw const VideoAuthorizationException(expiredMsg),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Video authorization expired'),
          findsOneWidget,
        );
        expect(find.byType(VideoErrorState), findsOneWidget);
      },
    );

    testWidgets('error never leaks private signed URL tokens', (tester) async {
      const privateUrl =
          'https://stream.mux.com/TopSecret.m3u8?token=eyJhbGc.eyJzdWIi.PRIV_SIG';
      await tester.pumpWidget(
        _app(
          invoke: (body) async =>
              throw const FunctionException(status: 403, details: privateUrl),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('TopSecret'), findsNothing);
      expect(find.textContaining('eyJzdWIi'), findsNothing);
      expect(find.textContaining('PRIV_SIG'), findsNothing);
    });

    testWidgets(
      'signed-out user sees sign-in text; authorization is never called',
      (tester) async {
        var authCalls = 0;
        await tester.pumpWidget(
          _app(
            signedOut: true,
            invoke: (body) async {
              authCalls++;
              return _validAuthResponse();
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(
          authCalls,
          0,
          reason: 'authorization must not run without a session',
        );
        expect(find.textContaining('sign in'), findsOneWidget);
      },
    );

    testWidgets('authorization sends only lesson_id — no other fields', (
      tester,
    ) async {
      Map<String, dynamic>? capturedBody;
      await tester.pumpWidget(
        _app(
          invoke: (body) async {
            capturedBody = body;
            throw const FunctionException(status: 403, details: '');
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedBody, {'lesson_id': _lesson});
    });
  });

  // ---------------------------------------------------------------------------
  // 2. Loading and error states
  // ---------------------------------------------------------------------------
  group('Protected video — loading and error states', () {
    testWidgets('VideoLoadingState shown while authorization is pending', (
      tester,
    ) async {
      final pending = Completer<FunctionResponse>();
      await tester.pumpWidget(_app(invoke: (body) => pending.future));
      // Let the microtask _authorize() start.
      await tester.pump();
      await tester.pump();

      expect(find.byType(VideoLoadingState), findsOneWidget);

      // Complete to release resources and avoid timer leaks.
      pending.completeError(
        const VideoAuthorizationException('test cancelled'),
      );
      await tester.pumpAndSettle();
    });

    testWidgets(
      'service error (503) shows generic unavailable message and error widget',
      (tester) async {
        await tester.pumpWidget(
          _app(
            invoke: (body) async => throw const FunctionException(
              status: 503,
              details: 'backend down',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('temporarily unavailable'), findsOneWidget);
        expect(find.byType(VideoErrorState), findsOneWidget);
      },
    );

    testWidgets('Retry button triggers a second authorization call', (
      tester,
    ) async {
      var authCalls = 0;
      await tester.pumpWidget(
        _app(
          invoke: (body) async {
            authCalls++;
            throw const FunctionException(status: 503, details: '');
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(authCalls, 1);

      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(authCalls, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // 3. VideoAuthorizationRepository unit tests (entitlement and expiry checks)
  // ---------------------------------------------------------------------------
  group('Protected video — VideoAuthorizationRepository unit tests', () {
    test('valid response returns AuthorizedVideo with correct host', () async {
      final repo = VideoAuthorizationRepository(
        (body) async => _validAuthResponse(),
        clock: () => _now,
      );
      final video = await repo.authorize(_lesson);

      expect(video.url.host, 'stream.mux.com');
      expect(video.url.scheme, 'https');
      expect(video.expiresAt.isAfter(_now), isTrue);
    });

    test('request body contains only lesson_id', () async {
      Map<String, dynamic>? captured;
      final repo = VideoAuthorizationRepository((body) async {
        captured = body;
        return _validAuthResponse();
      }, clock: () => _now);
      await repo.authorize(_lesson);

      expect(captured, {'lesson_id': _lesson});
    });

    test('expired authorization (expiry in the past) is denied', () async {
      final repo = VideoAuthorizationRepository(
        (body) async => FunctionResponse(
          status: 200,
          data: {
            'data': {
              'lesson_id': _lesson,
              // Expired: expiry is in the past.
              'expires_at': _now.millisecondsSinceEpoch ~/ 1000 - 1,
              'playback_url':
                  'https://stream.mux.com/PrivatePlayback123.m3u8?token=header.payload.signature',
            },
          },
        ),
        clock: () => _now,
      );

      await expectLater(
        repo.authorize(_lesson),
        throwsA(isA<VideoAuthorizationException>()),
      );
    });

    test('mismatched lesson_id in response is denied', () async {
      final repo = VideoAuthorizationRepository(
        (body) async => FunctionResponse(
          status: 200,
          data: {
            'data': {
              'lesson_id': 'ffffffff-ffff-4fff-8fff-ffffffffffff',
              'expires_at': _now.millisecondsSinceEpoch ~/ 1000 + 120,
              'playback_url':
                  'https://stream.mux.com/PrivatePlayback123.m3u8?token=header.payload.signature',
            },
          },
        ),
        clock: () => _now,
      );

      await expectLater(
        repo.authorize(_lesson),
        throwsA(isA<VideoAuthorizationException>()),
      );
    });

    test('403 denial exception message does not leak credentials', () async {
      const sensitiveDetail =
          'https://stream.mux.com/Private.m3u8?token=SECRET_TOKEN';
      final repo = VideoAuthorizationRepository(
        (body) async =>
            throw FunctionException(status: 403, details: sensitiveDetail),
      );

      await expectLater(
        repo.authorize(_lesson),
        throwsA(
          isA<VideoAuthorizationException>().having(
            (e) => e.message,
            'safe message',
            isNot(contains('SECRET_TOKEN')),
          ),
        ),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 4. Progress entity: tracking and resume position
  // ---------------------------------------------------------------------------
  group('Protected video — progress tracking domain', () {
    test('progress is 0.0 when position is zero', () {
      const p = VideoProgress(
        status: VideoPlayerStatus.playing,
        position: Duration.zero,
        duration: Duration(seconds: 120),
      );
      expect(p.progress, 0.0);
    });

    test('progress is 0.5 at half-way position', () {
      const p = VideoProgress(
        status: VideoPlayerStatus.playing,
        position: Duration(seconds: 60),
        duration: Duration(seconds: 120),
      );
      expect(p.progress, closeTo(0.5, 0.001));
    });

    test('progress clamps to 1.0 when position exceeds duration', () {
      const p = VideoProgress(
        position: Duration(seconds: 130),
        duration: Duration(seconds: 120),
      );
      expect(p.progress, 1.0);
    });

    test('ended status with full position reports 1.0 progress', () {
      const p = VideoProgress(
        status: VideoPlayerStatus.ended,
        position: Duration(seconds: 120),
        duration: Duration(seconds: 120),
      );
      expect(p.progress, 1.0);
    });

    test('resume position is preserved in VideoProgress entity', () {
      const resumeSeconds = 45;
      const p = VideoProgress(
        status: VideoPlayerStatus.paused,
        position: Duration(seconds: resumeSeconds),
        duration: Duration(seconds: 300),
      );
      expect(p.position.inSeconds, resumeSeconds);
      expect(p.progress, closeTo(0.15, 0.001));
    });

    test('error status carries error message', () {
      const p = VideoProgress(
        status: VideoPlayerStatus.error,
        errorMessage: 'Video playback stopped.',
      );
      expect(p.status, VideoPlayerStatus.error);
      expect(p.errorMessage, 'Video playback stopped.');
    });
  });

  // ---------------------------------------------------------------------------
  // 5. Optional progress params accepted by the widget
  // ---------------------------------------------------------------------------
  group('Protected video — optional progress params', () {
    testWidgets(
      'widget accepts initialVideoSeconds without framework exception',
      (tester) async {
        await tester.pumpWidget(
          _app(
            initialVideoSeconds: 45,
            invoke: (body) async => throw const FunctionException(
              status: 403,
              details: 'no entitlement',
            ),
          ),
        );
        await tester.pumpAndSettle();
        // No framework-level exception should escape.
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'widget accepts onVideoSeconds callback without framework exception',
      (tester) async {
        final emitted = <int>[];
        await tester.pumpWidget(
          _app(
            onVideoSeconds: emitted.add,
            invoke: (body) async => throw const FunctionException(
              status: 403,
              details: 'no entitlement',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
