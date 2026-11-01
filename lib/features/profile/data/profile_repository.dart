import 'package:acendra/features/profile/domain/avatar_file.dart';
import 'package:acendra/features/profile/domain/profile_failure.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  const ProfileRepository(SupabaseClient client) : _client = client;

  @visibleForTesting
  const ProfileRepository.forTesting() : _client = null;

  final SupabaseClient? _client;

  Future<void> updateDisplayName({required String displayName}) async {
    try {
      await _client!.auth.updateUser(
        UserAttributes(data: {'full_name': displayName}),
      );
    } on AuthException catch (e) {
      throw ProfileUpdateFailed(e.message);
    } catch (_) {
      throw const ProfileNetworkError();
    }
  }

  /// Short-lived signed URL for the caller's avatar, or null if none is set.
  Future<String?> fetchAvatarUrl() async {
    try {
      final uid = _client!.auth.currentUser?.id;
      if (uid == null) return null;
      final row = await _client
          .from('profiles')
          .select('avatar_path')
          .eq('id', uid)
          .maybeSingle();
      final path = row?['avatar_path'] as String?;
      if (path == null || path.isEmpty) return null;
      return await _client.storage
          .from(_avatarBucket)
          .createSignedUrl(path, 3600);
    } catch (_) {
      return null;
    }
  }

  /// Locale and email notification preference from the profiles table.
  Future<({String? locale, bool emailNotificationsEnabled})>
  fetchPreferences() async {
    try {
      final uid = _client!.auth.currentUser?.id;
      if (uid == null) return (locale: null, emailNotificationsEnabled: true);
      final row = await _client
          .from('profiles')
          .select('locale, email_notifications_enabled')
          .eq('id', uid)
          .maybeSingle();
      if (row == null) return (locale: null, emailNotificationsEnabled: true);
      return (
        locale: row['locale'] as String?,
        emailNotificationsEnabled:
            (row['email_notifications_enabled'] as bool?) ?? true,
      );
    } catch (_) {
      return (locale: null, emailNotificationsEnabled: true);
    }
  }

  /// Updates the caller's locale (D-4: 'en' or 'si').
  Future<void> updateLocale(String? locale) async {
    try {
      final uid = _client!.auth.currentUser?.id;
      if (uid == null) throw const ProfileUpdateFailed('Please sign in again.');
      await _client.from('profiles').update({'locale': locale}).eq('id', uid);
    } on ProfileFailure {
      rethrow;
    } catch (_) {
      throw const ProfileNetworkError();
    }
  }

  /// Updates the caller's email notification preference (D-8).
  Future<void> updateEmailNotifications({required bool enabled}) async {
    try {
      final uid = _client!.auth.currentUser?.id;
      if (uid == null) throw const ProfileUpdateFailed('Please sign in again.');
      await _client
          .from('profiles')
          .update({'email_notifications_enabled': enabled})
          .eq('id', uid);
    } on ProfileFailure {
      rethrow;
    } catch (_) {
      throw const ProfileNetworkError();
    }
  }

  /// Uploads [file] to the caller's private folder and records its path.
  Future<void> uploadAvatar(AvatarFile file) async {
    final error = avatarFileError(file.name, file.bytes.length);
    final type = file.contentType;
    if (error != null || type == null) {
      throw ProfileUpdateFailed(error ?? 'Choose a JPG, PNG or WebP image.');
    }
    try {
      final uid = _client!.auth.currentUser?.id;
      if (uid == null) throw const ProfileUpdateFailed('Please sign in again.');
      final path = '$uid/avatar';
      await _client.storage
          .from(_avatarBucket)
          .uploadBinary(
            path,
            file.bytes,
            fileOptions: FileOptions(contentType: type, upsert: true),
          );
      await _client
          .from('profiles')
          .update({'avatar_path': path})
          .eq('id', uid);
    } on ProfileFailure {
      rethrow;
    } on StorageException catch (e) {
      throw ProfileUpdateFailed(e.message);
    } catch (_) {
      throw const ProfileNetworkError();
    }
  }
}

const _avatarBucket = 'avatars';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});
