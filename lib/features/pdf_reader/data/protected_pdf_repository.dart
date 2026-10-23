import 'dart:convert';
import 'dart:typed_data';

class ProtectedPdfFailure implements Exception {
  const ProtectedPdfFailure(this.message);
  final String message;
}

class PdfTransportResponse {
  const PdfTransportResponse(this.status, this.contentType, this.bytes);
  final int status;
  final String contentType;
  final Uint8List bytes;
}

abstract class PdfTransport {
  Future<PdfTransportResponse> get(Uri url, String bearer);
  void cancel();
}

class ProtectedPdfData {
  const ProtectedPdfData(this.bytes, {required this.watermarkApplied});
  final Uint8List bytes;
  final bool watermarkApplied;
}

class ProtectedPdfRepository {
  const ProtectedPdfRepository(this.endpoint, this.transport);
  final Uri endpoint;
  final PdfTransport transport;
  static final uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  Future<Uint8List?> load(String lessonId, String bearer) async {
    return (await loadDocument(lessonId, bearer))?.bytes;
  }

  Future<ProtectedPdfData?> loadDocument(String lessonId, String bearer) async {
    if (!uuid.hasMatch(lessonId) || bearer.isEmpty) {
      throw const ProtectedPdfFailure('Sign in to access this PDF.');
    }
    final lesson = lessonId.toLowerCase();
    final descriptor = await transport.get(
      endpoint.replace(queryParameters: {'lesson_id': lesson}),
      bearer,
    );
    _checkStatus(descriptor.status, preparing: true);
    if (descriptor.contentType != 'application/json' ||
        descriptor.bytes.length > 8192) {
      throw const ProtectedPdfFailure('PDF access could not be verified.');
    }
    dynamic data;
    try {
      data = (jsonDecode(utf8.decode(descriptor.bytes)) as Map)['data'];
    } catch (_) {
      throw const ProtectedPdfFailure('PDF access could not be verified.');
    }
    if (data is! Map ||
        data['lesson_id'] != lesson ||
        data['mode'] != 'proxied_stream') {
      throw const ProtectedPdfFailure('PDF access could not be verified.');
    }
    if (descriptor.status == 202 &&
        data['state'] == 'preparing' &&
        data['resource_id'] == null) {
      return null;
    }
    if (descriptor.status != 200 ||
        data['state'] != 'ready' ||
        data['resource_id'] is! String ||
        !uuid.hasMatch(data['resource_id'] as String)) {
      throw const ProtectedPdfFailure('PDF access could not be verified.');
    }
    final response = await transport.get(
      endpoint.replace(
        queryParameters: {
          'lesson_id': lesson,
          'resource_id': data['resource_id'] as String,
        },
      ),
      bearer,
    );
    _checkStatus(response.status);
    final bytes = response.bytes;
    if (response.contentType != 'application/pdf' ||
        bytes.length < 5 ||
        bytes.length > 50 * 1024 * 1024 ||
        ascii.decode(bytes.sublist(0, 5), allowInvalid: true) != '%PDF-') {
      throw const ProtectedPdfFailure('PDF delivery could not be verified.');
    }
    return ProtectedPdfData(
      bytes,
      watermarkApplied: data['watermark_applied'] == true,
    );
  }

  static void _checkStatus(int status, {bool preparing = false}) {
    if (status == 200 || (preparing && status == 202)) {
      return;
    }
    throw ProtectedPdfFailure(switch (status) {
      401 => 'Sign in again to access this PDF.',
      403 || 404 => 'You do not have access to this PDF.',
      503 => 'Protected PDF delivery is currently unavailable.',
      _ => 'PDF delivery could not be confirmed. Please retry.',
    });
  }
}
