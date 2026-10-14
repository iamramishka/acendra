import 'dart:js_interop';
import 'dart:async';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'protected_pdf_repository.dart';

PdfTransport createPdfTransport() => _BrowserTransport();

class _BrowserTransport implements PdfTransport {
  web.AbortController? controller;
  bool cancelled = false;
  @override
  Future<PdfTransportResponse> get(Uri url, String bearer) async {
    if (cancelled) {
      throw const ProtectedPdfFailure('PDF request cancelled.');
    }
    controller = web.AbortController();
    final deadline = Timer(const Duration(seconds: 30), cancel);
    try {
      final headers = web.Headers()..set('Authorization', 'Bearer $bearer');
      final response = await web
          .fetch(
            url.toString().toJS,
            web.RequestInit(
              method: 'GET',
              headers: headers,
              credentials: 'omit',
              cache: 'no-store',
              redirect: 'error',
              signal: controller!.signal,
            ),
          )
          .toDart;
      final declared = int.tryParse(
        response.headers.get('content-length') ?? '',
      );
      final contentType = (response.headers.get('content-type') ?? '')
          .split(';')
          .first
          .trim()
          .toLowerCase();
      final limit = contentType == 'application/json' ? 8192 : 50 * 1024 * 1024;
      if (declared != null && declared > limit) {
        cancel();
        throw const ProtectedPdfFailure('PDF exceeds the supported size.');
      }
      final body = response.body;
      if (body == null) {
        throw const ProtectedPdfFailure('PDF delivery failed.');
      }
      final reader = body.getReader() as web.ReadableStreamDefaultReader;
      final collected = BytesBuilder(copy: false);
      try {
        while (true) {
          final chunk = await reader.read().toDart;
          if (chunk.done) {
            break;
          }
          final bytes = (chunk.value as JSUint8Array).toDart;
          if (collected.length + bytes.length > limit) {
            cancel();
            throw const ProtectedPdfFailure('PDF exceeds the supported size.');
          }
          collected.add(bytes);
        }
      } finally {
        reader.releaseLock();
      }
      return PdfTransportResponse(
        response.status,
        (response.headers.get('content-type') ?? '')
            .split(';')
            .first
            .trim()
            .toLowerCase(),
        collected.takeBytes(),
      );
    } finally {
      deadline.cancel();
    }
  }

  @override
  void cancel() {
    cancelled = true;
    controller?.abort();
    controller = null;
  }
}
