@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

@JS('com018Fixture')
external JSPromise<JSObject> _fixture(JSBoolean captions);
@JS('com018Stage')
external JSString? get _stage;

void main() {
  setUpAll(() async {
    final loaded = Completer<void>();
    final script = web.HTMLScriptElement()
      ..type = 'module'
      ..src = '/.dart_tool/video_runtime/fixture_runner.js';
    script.addEventListener('load', ((web.Event _) => loaded.complete()).toJS);
    script.addEventListener(
      'error',
      ((web.Event _) => loaded.completeError(
        StateError(
          'Run node tool/prepare_video_browser.mjs before browser checks',
        ),
      )).toJS,
    );
    web.document.head!.append(script);
    await loaded.future.timeout(const Duration(seconds: 20));
  });
  for (final captions in [false, true]) {
    test(
      'real synthetic HLS: playback, seek, speed and captions=$captions',
      () async {
        final result = await _fixture(captions.toJS).toDart.timeout(
          const Duration(seconds: 40),
          onTimeout: () =>
              throw StateError('Video fixture stalled at ${_stage?.toDart}'),
        );
        final data = result.dartify() as Map;
        expect(data['duration'], greaterThanOrEqualTo(11));
        expect(data['position'], greaterThan(3.2));
        expect(data['rate'], 1.5);
        expect(data['paused'], isTrue);
        expect(data['captionTracks'], captions ? greaterThan(0) : 0);
        if (captions) expect(data['cue'], contains('SYNTHETIC'));
        expect(data['captionsDisabled'], isTrue);
        expect(data['trackingDisabled'], isTrue);
        expect(data['cookiesDisabled'], isTrue);
        expect(data['fullscreenAvailable'], isTrue);
        expect(data['controlTargetWidth'], greaterThanOrEqualTo(44));
        expect(data['controlTargetHeight'], greaterThanOrEqualTo(44));
      },
    );
  }
}
