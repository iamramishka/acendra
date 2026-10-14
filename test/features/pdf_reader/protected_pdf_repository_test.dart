import 'dart:convert';
import 'dart:typed_data';
import 'package:acendra/features/pdf_reader/data/protected_pdf_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const lesson = '11111111-1111-4111-8111-111111111111';
const resource = '22222222-2222-4222-8222-222222222222';

class _Transport implements PdfTransport {
  _Transport(this.responses);
  final List<PdfTransportResponse> responses;
  final urls = <Uri>[];
  final tokens = <String>[];
  @override
  Future<PdfTransportResponse> get(Uri url, String bearer) async {
    urls.add(url);
    tokens.add(bearer);
    return responses.removeAt(0);
  }

  @override
  void cancel() {}
}

PdfTransportResponse descriptor({
  String state = 'ready',
  String id = lesson,
  String? resourceId = resource,
  int status = 200,
}) => PdfTransportResponse(
  status,
  'application/json',
  Uint8List.fromList(
    utf8.encode(
      jsonEncode({
        'data': {
          'lesson_id': id,
          'mode': 'proxied_stream',
          'state': state,
          'resource_id': resourceId,
        },
      }),
    ),
  ),
);
ProtectedPdfRepository _repo(_Transport transport) => ProtectedPdfRepository(
  Uri.parse('https://backend.example.test/functions/v1/pdf-content'),
  transport,
);
void main() {
  test('only authenticated bound derivative bytes reach renderer', () async {
    final bytes = Uint8List.fromList(ascii.encode('%PDF-synthetic'));
    final transport = _Transport([
      descriptor(),
      PdfTransportResponse(200, 'application/pdf', bytes),
    ]);
    expect(await _repo(transport).load(lesson, 'current-token'), bytes);
    expect(transport.urls.first.queryParameters, {'lesson_id': lesson});
    expect(transport.urls.last.queryParameters, {
      'lesson_id': lesson,
      'resource_id': resource,
    });
    expect(transport.tokens, ['current-token', 'current-token']);
  });
  test('preparing never fetches an original or resource', () async {
    final transport = _Transport([
      descriptor(state: 'preparing', resourceId: null, status: 202),
    ]);
    expect(await _repo(transport).load(lesson, 'token'), isNull);
    expect(transport.urls.length, 1);
  });
  test('mismatched lesson rejects descriptor before byte delivery', () async {
    final transport = _Transport([descriptor(id: resource)]);
    await expectLater(
      _repo(transport).load(lesson, 'token'),
      throwsA(isA<ProtectedPdfFailure>()),
    );
    expect(transport.urls.length, 1);
  });
  for (final status in [401, 403, 404, 503, 302]) {
    test('status $status never falls back to original bytes', () async {
      final transport = _Transport([
        PdfTransportResponse(status, 'application/json', Uint8List(0)),
      ]);
      await expectLater(
        _repo(transport).load(lesson, 'token'),
        throwsA(isA<ProtectedPdfFailure>()),
      );
      expect(transport.urls.length, 1);
    });
  }
  test('successful HTML masquerading as PDF is refused', () async {
    final transport = _Transport([
      descriptor(),
      PdfTransportResponse(
        200,
        'application/pdf',
        Uint8List.fromList(ascii.encode('<html>private')),
      ),
    ]);
    await expectLater(
      _repo(transport).load(lesson, 'token'),
      throwsA(isA<ProtectedPdfFailure>()),
    );
  });
}
