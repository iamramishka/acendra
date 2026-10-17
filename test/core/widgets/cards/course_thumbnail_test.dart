import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acendra/core/widgets/cards/course_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Client implements HttpClient {
  _Client(this.bytes);
  final List<int> bytes;
  @override
  bool autoUncompress = true;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _Request(bytes);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Request implements HttpClientRequest {
  _Request(this.bytes);
  final List<int> bytes;
  @override
  final HttpHeaders headers = _Headers();
  @override
  Future<HttpClientResponse> close() async => _Response(bytes);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.bytes);
  final List<int> bytes;
  @override
  int get statusCode => 200;
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Headers implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap({
  String? url,
  double width = 320,
  double height = 180,
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  theme: ThemeData(brightness: brightness),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        height: height,
        child: CourseThumbnail(title: 'Flutter Basics', imageUrl: url),
      ),
    ),
  ),
);

void main() {
  for (final url in <String?>[
    null,
    '',
    '   ',
    'course-id/thumbnails/file.png',
    'file:///secret.png',
    'not a URL',
  ]) {
    testWidgets('missing or non-deliverable URL uses cover: $url', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(url: url));
      expect(find.byType(Image), findsNothing);
      expect(find.text('FB'), findsOneWidget);
      expect(find.text('Cover image not provided'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Flutter Basics. Cover image not provided'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final brightness in Brightness.values) {
    for (final size in <Size>[
      const Size(56, 40),
      const Size(64, 48),
      const Size(288, 162),
      const Size(390, 219),
      const Size(768, 432),
    ]) {
      testWidgets('fallback fits $size in $brightness', (tester) async {
        await tester.pumpWidget(
          _wrap(width: size.width, height: size.height, brightness: brightness),
        );
        expect(find.text('FB'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('failed network image falls back without an exception', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(url: ' https://example.com/missing.png '));
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as NetworkImage).url,
      'https://example.com/missing.png',
    );
    expect(image.fit, BoxFit.cover);
    await tester.pumpAndSettle();
    expect(find.text('Cover image unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('successful network image replaces loading cover', (
    tester,
  ) async {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5gMQFwcdLl4wmwAAAAtJREFUCNdjYAACAAAFAAHiJgWbAAAAAElFTkSuQmCC',
    );
    final client = _Client(bytes);
    debugNetworkImageHttpClientProvider = () => client;
    addTearDown(() => debugNetworkImageHttpClientProvider = null);
    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(_wrap(url: 'https://example.com/cover.png'));
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Loading cover image'), findsNothing);
      expect(find.text('Cover image unavailable'), findsNothing);
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
      expect(tester.takeException(), isNull);
    }, createHttpClient: (_) => client);
    debugNetworkImageHttpClientProvider = null;
  });
}
