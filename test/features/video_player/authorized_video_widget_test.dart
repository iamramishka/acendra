import 'dart:async';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/video_player/data/video_authorization_repository.dart';
import 'package:acendra/features/video_player/presentation/widgets/authorized_video_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const lesson = '11111111-1111-4111-8111-111111111111';
Session session(String id) => Session(
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
void main() {
  testWidgets(
    'gated authorize-video failure shows safe retry without public fallback',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSessionProvider.overrideWithValue(session('student-a')),
            videoAuthorizationRepositoryProvider.overrideWithValue(
              VideoAuthorizationRepository((body) async {
                calls++;
                expect(body, {'lesson_id': lesson});
                throw const FunctionException(
                  status: 503,
                  details: 'private signed token',
                );
              }),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AuthorizedVideoWidget(
                lessonId: lesson,
                title: 'Sample Video',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.textContaining('temporarily unavailable'), findsOneWidget);
      expect(find.textContaining('private signed token'), findsNothing);
      await tester.tap(find.text('Request video access'));
      await tester.pumpAndSettle();
      expect(calls, 2);
    },
  );
  for (final signedOut in [false, true]) {
    testWidgets(
      'identity change discards late authorization signedOut=$signedOut',
      (tester) async {
        final identity = StateProvider<Session?>((ref) => session('student-a'));
        final pending = Completer<FunctionResponse>();
        var calls = 0;
        final container = ProviderContainer(
          overrides: [
            currentSessionProvider.overrideWith((ref) => ref.watch(identity)),
            videoAuthorizationRepositoryProvider.overrideWithValue(
              VideoAuthorizationRepository((body) {
                calls++;
                if (calls == 1) return pending.future;
                return Future.value(
                  const FunctionResponse(status: 503, data: {}),
                );
              }),
            ),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: AuthorizedVideoWidget(lessonId: lesson, title: 'Sample'),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(calls, 1);
        container.read(identity.notifier).state = signedOut
            ? null
            : session('student-b');
        await tester.pump();
        await tester.pump();
        pending.completeError(
          const VideoAuthorizationException('OLD ACCOUNT DIAGNOSTIC'),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('OLD ACCOUNT'), findsNothing);
        expect(tester.takeException(), isNull);
        expect(calls, signedOut ? 1 : 2);
      },
    );
  }
}
