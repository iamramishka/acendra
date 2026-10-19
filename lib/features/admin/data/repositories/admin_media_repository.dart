import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/media_file.dart';

abstract interface class AdminMediaRepository {
  Future<void> upload({
    required String courseId,
    String? lessonId,
    required MediaFile file,
  });
}

class SupabaseAdminMediaRepository implements AdminMediaRepository {
  SupabaseAdminMediaRepository(this.client);
  final SupabaseClient client;
  static final _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );
  String _requestId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return [
      hex.substring(0, 8),
      hex.substring(8, 12),
      hex.substring(12, 16),
      hex.substring(16, 20),
      hex.substring(20),
    ].join('-');
  }

  @override
  Future<void> upload({
    required String courseId,
    String? lessonId,
    required MediaFile file,
  }) async {
    final pdf = lessonId != null;
    final validation = mediaFileError(file.name, file.bytes.length, pdf: pdf);
    if (validation != null) throw FormatException(validation);
    if (!_uuidPattern.hasMatch(courseId) ||
        (lessonId != null && !_uuidPattern.hasMatch(lessonId))) {
      throw const FormatException(
        'Save the course and lesson before uploading.',
      );
    }
    final session = client.auth.currentSession;
    final token = session?.accessToken;
    final user = session?.user.id;
    void current() {
      if (user == null ||
          token == null ||
          client.auth.currentSession?.accessToken != token ||
          client.auth.currentUser?.id != user) {
        throw const FormatException('Your session changed. Sign in and retry.');
      }
    }

    current();
    final requestId = _requestId();
    try {
      final prepared = await client.functions.invoke(
        'admin-create-media-upload',
        body: {
          'request_id': requestId,
          'course_id': courseId,
          'lesson_id': lessonId,
          'asset_type': pdf ? 'course_pdf' : 'public_thumbnail',
          'file_name': 'media.${file.extension}',
          'content_type': file.mime,
          'size_bytes': file.bytes.length,
        },
      );
      current();
      final data = prepared.data is Map ? prepared.data['data'] : null;
      final asset = data is Map ? data['asset_id'] : null;
      final upload = data is Map ? data['upload'] : null;
      final extension = file.mime == 'image/jpeg' ? 'jpg' : file.extension;
      final expected = pdf
          ? 'originals/$asset/v1.pdf'
          : '$courseId/thumbnails/$asset.$extension';
      if (prepared.status != 201 ||
          asset is! String ||
          !_uuidPattern.hasMatch(asset) ||
          upload is! Map ||
          upload['mode'] != 'supabase_signed_upload' ||
          upload['bucket'] != (pdf ? 'course-pdfs' : 'course-media') ||
          upload['path'] != expected ||
          upload['token'] is! String ||
          (upload['token'] as String).isEmpty) {
        throw const FormatException('Upload could not be prepared. Retry.');
      }
      await client.storage
          .from(upload['bucket'] as String)
          .uploadBinaryToSignedUrl(
            expected,
            upload['token'] as String,
            file.bytes,
            FileOptions(contentType: file.mime, upsert: false),
          );
      current();
      final finished = await client.functions.invoke(
        'admin-finalize-media-upload',
        body: {'request_id': requestId, 'asset_id': asset},
      );
      current();
      final result = finished.data is Map ? finished.data['data'] : null;
      if (finished.status != 200 ||
          result is! Map ||
          result['asset_id'] != asset ||
          result['status'] != 'validated') {
        throw const FormatException('Inspection did not complete. Retry.');
      }
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
        'Upload or inspection failed. Check your connection and retry.',
      );
    }
  }
}

final adminMediaRepositoryProvider = Provider<AdminMediaRepository>(
  (ref) => SupabaseAdminMediaRepository(Supabase.instance.client),
);
