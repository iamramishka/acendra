import 'package:supabase_flutter/supabase_flutter.dart';

/// Safe messages only: backend diagnostics and private rows never reach the UI.
class AdminDataException implements Exception {
  const AdminDataException(this.message);
  final String message;
  @override
  String toString() => message;
}

String adminDataError(Object error, String fallback) =>
    error is AdminDataException ? error.message : fallback;

class AdminDirectoryClient {
  const AdminDirectoryClient(this.client);
  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> read(
    String resource, {
    String? id,
    String search = '',
  }) async {
    final rows = <Map<String, dynamic>>[];
    final seen = <String>{};
    String? cursor;
    do {
      final data = await invoke('admin-directory', {
        'resource': resource,
        'id': id,
        'search': search,
        'after_id': cursor,
        'limit': 50,
      });
      final page = data['items'];
      if (page is! List || page.length > 50) {
        throw const AdminDataException('Unable to load admin records. Retry.');
      }
      rows.addAll(page.map((row) => Map<String, dynamic>.from(row as Map)));
      final next = data['next_after_id'];
      if (next != null && (next is! String || !seen.add(next))) {
        throw const AdminDataException('Unable to load admin records. Retry.');
      }
      cursor = next as String?;
    } while (cursor != null);
    return rows;
  }

  Future<Map<String, dynamic>> invoke(
    String name,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await client.functions.invoke(
        name,
        body: body,
        headers: headers,
      );
      final payload = response.data;
      if (response.status != 200 ||
          payload is! Map ||
          payload['data'] is! Map) {
        throw const AdminDataException(
          'Admin service is unavailable. Retry or contact your administrator.',
        );
      }
      return Map<String, dynamic>.from(payload['data'] as Map);
    } on FunctionException catch (error) {
      if (error.status == 401) {
        throw const AdminDataException('Your session expired. Sign in again.');
      }
      if (error.status == 403) {
        throw const AdminDataException(
          'This action requires current admin permission and, where required, multi-factor authentication.',
        );
      }
      throw const AdminDataException(
        'Admin service is unavailable. Retry or contact your administrator.',
      );
    }
  }
}
