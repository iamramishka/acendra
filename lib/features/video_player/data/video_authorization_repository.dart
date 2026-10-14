import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VideoAuthorizationException implements Exception {
  const VideoAuthorizationException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Keep bearer URLs transient; never put them in progress, logs or route extras.
class AuthorizedVideo {
  const AuthorizedVideo({required this.url, required this.expiresAt});
  final Uri url;
  final DateTime expiresAt;
}

typedef VideoInvoke =
    Future<FunctionResponse> Function(Map<String, dynamic> body);

class VideoAuthorizationRepository {
  VideoAuthorizationRepository(this.invoke, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final VideoInvoke invoke;
  final DateTime Function() clock;
  Future<AuthorizedVideo> authorize(String lessonId) async {
    if (!RegExp(
      r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(lessonId)) {
      throw const VideoAuthorizationException(
        'This video lesson is unavailable.',
      );
    }
    try {
      final response = await invoke({'lesson_id': lessonId});
      if (response.status != 200) {
        throw const VideoAuthorizationException(
          'Video access is temporarily unavailable.',
        );
      }
      final envelope = response.data;
      final data = envelope is Map ? envelope['data'] : null;
      final raw = data is Map ? data['playback_url'] : null;
      final expiry = data is Map ? data['expires_at'] : null;
      final url = raw is String && raw.length <= 16384
          ? Uri.tryParse(raw)
          : null;
      final now = clock().millisecondsSinceEpoch ~/ 1000;
      if (data is! Map ||
          data['lesson_id'] != lessonId.toLowerCase() ||
          expiry is! int ||
          expiry <= now ||
          expiry > now + 300 ||
          url == null ||
          url.scheme != 'https' ||
          url.host != 'stream.mux.com' ||
          url.userInfo.isNotEmpty ||
          url.hasPort ||
          url.hasFragment ||
          !RegExp(r'^/[A-Za-z0-9]{1,255}\.m3u8$').hasMatch(url.path) ||
          url.queryParametersAll.length != 1 ||
          url.queryParametersAll['token']?.length != 1 ||
          !RegExp(
            r'^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$',
          ).hasMatch(url.queryParameters['token'] ?? '')) {
        throw const VideoAuthorizationException(
          'Video authorization could not be verified.',
        );
      }
      return AuthorizedVideo(
        url: url,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
          expiry * 1000,
          isUtc: true,
        ),
      );
    } on VideoAuthorizationException {
      rethrow;
    } on FunctionException catch (error) {
      throw VideoAuthorizationException(
        error.status == 401
            ? 'Please sign in again to watch this lesson.'
            : error.status == 403
            ? 'You do not currently have access to this video.'
            : 'Video access is temporarily unavailable.',
      );
    } catch (_) {
      throw const VideoAuthorizationException(
        'Video access is temporarily unavailable.',
      );
    }
  }
}

final videoAuthorizationRepositoryProvider =
    Provider<VideoAuthorizationRepository>((ref) {
      final client = Supabase.instance.client;
      return VideoAuthorizationRepository(
        (body) => client.functions.invoke('authorize-video', body: body),
      );
    });
