import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AdminArtworkRepository {
  Future<Uint8List> read(String courseId);
}

class SupabaseAdminArtworkRepository implements AdminArtworkRepository {
  SupabaseAdminArtworkRepository(this.client);
  final SupabaseClient client;

  @override
  Future<Uint8List> read(String courseId) async {
    final session = client.auth.currentSession;
    final token = session?.accessToken;
    final actor = session?.user.id;
    if (token == null ||
        actor == null ||
        !RegExp(
          r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$',
        ).hasMatch(courseId)) {
      throw const FormatException('Artwork unavailable.');
    }
    final response = await client.functions.invoke(
      'course-artwork',
      method: HttpMethod.get,
      queryParameters: {'course_id': courseId},
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/octet-stream',
      },
      abortSignal: Future<void>.delayed(const Duration(seconds: 20)),
    );
    final bytes = response.data;
    if (client.auth.currentSession?.accessToken != token ||
        client.auth.currentUser?.id != actor ||
        response.status != 200 ||
        bytes is! Uint8List ||
        bytes.isEmpty ||
        bytes.length > 5242880) {
      throw const FormatException('Artwork unavailable.');
    }
    return bytes;
  }
}

final adminArtworkRepositoryProvider = Provider<AdminArtworkRepository>(
  (ref) => SupabaseAdminArtworkRepository(Supabase.instance.client),
);
