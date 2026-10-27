@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/video_player/data/video_authorization_repository.dart';
import 'package:acendra/features/video_player/presentation/widgets/authorized_video_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

// Widget lifecycle checks isolate the platform-view channel, following Flutter's
// HtmlElementView test pattern. Actual media uses the real DOM in the HLS suite.
class _Views implements ui_web.PlatformViewRegistry {
  final elements = <int, Object>{};
  @override
  Object getViewById(int id) => elements[id]!;
  @override
  bool registerViewFactory(
    String viewType,
    Function factory, {
    bool isVisible = true,
  }) => true;
}

@JS('acendraMuxVideo')
external set _runtime(JSObject value);
const _lesson = '22222222-2222-4222-8222-222222222222';
Session _session(String id) => Session(
  accessToken: 'synthetic-$id',
  tokenType: 'bearer',
  user: User(
    id: id,
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-10-27T00:00:00Z',
  ),
);
FunctionResponse _response() => FunctionResponse(
  status: 200,
  data: {
    'data': {
      'lesson_id': _lesson,
      'expires_at': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 120,
      'playback_url':
          'https://stream.mux.com/Synthetic123.m3u8?token=header.payload.signature',
    },
  },
);

void main() {
  Future<void> settle(WidgetTester tester) async {
    // Platform views and native JS promises need real browser event-loop turns;
    // advancing Flutter's fake clock cannot flush them.
    for (var turn = 0; turn < 5; turn++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
    }
    await tester.pump();
  }

  int mounts = 0, destroys = 0;
  JSFunction? emit;
  setUp(() {
    final views = _Views();
    ui_web.debugOverridePlatformViewRegistry(views);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views, (call) async {
          if (call.method == 'create') {
            final args = call.arguments as Map;
            final params = args['params'] as Map?;
            views.elements[args['id'] as int] = web.document.createElement(
              params?['tagName'] as String? ?? 'div',
            );
          } else if (call.method == 'dispose') {
            views.elements.remove(call.arguments);
          }
          return null;
        });
    mounts = destroys = 0;
    emit = null;
    _runtime =
        {
              'mount': ((JSObject host, JSObject lease, JSFunction callback) {
                mounts++;
                emit = callback;
                return {
                      'ready': JSPromise<JSAny?>(
                        (JSFunction resolve, JSFunction reject) {
                          resolve.callAsFunction(null, null);
                        }.toJS,
                      ),
                      'destroy': (() {
                        destroys++;
                      }).toJS,
                    }.jsify()
                    as JSObject;
              }).toJS,
            }.jsify()
            as JSObject;
  });
  tearDown(() => ui_web.debugOverridePlatformViewRegistry(null));
  Future<(ProviderContainer, StateProvider<Session?>)> mount(
    WidgetTester tester,
    VideoInvoke invoke,
  ) async {
    final identity = StateProvider<Session?>((_) => _session('A'));
    final container = ProviderContainer(
      overrides: [
        currentSessionProvider.overrideWith((ref) => ref.watch(identity)),
        videoAuthorizationRepositoryProvider.overrideWithValue(
          VideoAuthorizationRepository(invoke),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 640,
              height: 400,
              child: AuthorizedVideoWidget(
                lessonId: _lesson,
                title: 'Synthetic',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return (container, identity);
  }

  testWidgets(
    'sign-out disposes the web surface and prevents further authorization',
    (tester) async {
      var requests = 0;
      final (container, identity) = await mount(tester, (body) async {
        requests++;
        expect(body, {'lesson_id': _lesson});
        return _response();
      });
      await settle(tester);
      expect(mounts, 1);
      container.read(identity.notifier).state = null;
      await settle(tester);
      expect(destroys, 1);
      expect(requests, 1);
      expect(find.textContaining('Please sign in'), findsOneWidget);
    },
  );
  testWidgets(
    'late authorization from a previous account never mounts a player',
    (tester) async {
      final pending = Completer<FunctionResponse>();
      var requests = 0;
      final (container, identity) = await mount(tester, (_) {
        requests++;
        return requests == 1 ? pending.future : Future.value(_response());
      });
      container.read(identity.notifier).state = _session('B');
      await settle(tester);
      expect(mounts, 1);
      pending.complete(_response());
      await settle(tester);
      expect(mounts, 1);
      expect(requests, 2);
    },
  );
  testWidgets(
    'expiry removes the player and Retry obtains fresh authorization',
    (tester) async {
      var requests = 0;
      await mount(tester, (_) async {
        requests++;
        return _response();
      });
      await settle(tester);
      emit!.callAsFunction(null, {'kind': 'expired'}.jsify());
      await settle(tester);
      expect(destroys, 1);
      expect(find.textContaining('authorization expired'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await settle(tester);
      expect(requests, 2);
      expect(mounts, 2);
    },
  );
}
