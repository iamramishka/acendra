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
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});
