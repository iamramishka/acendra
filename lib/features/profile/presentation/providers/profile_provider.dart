import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/profile/data/profile_repository.dart';
import 'package:acendra/features/profile/data/avatar_picker.dart';
import 'package:acendra/features/profile/domain/avatar_file.dart';
import 'package:acendra/features/profile/domain/profile_failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exposes the current user's display name derived from the auth stream.
final displayNameProvider = Provider<String?>((ref) {
  final session = ref.watch(currentSessionProvider);
  return session?.user.userMetadata?['full_name'] as String?;
});

/// Exposes the current user's email derived from the auth stream.
final currentEmailProvider = Provider<String?>((ref) {
  final session = ref.watch(currentSessionProvider);
  return session?.user.email;
});

/// Notifier for updating the user's display name (CSA-071).
class ProfileEditNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateDisplayName({required String displayName}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(profileRepositoryProvider)
          .updateDisplayName(displayName: displayName),
    );
  }
}

final profileEditProvider = AsyncNotifierProvider<ProfileEditNotifier, void>(
  ProfileEditNotifier.new,
);

/// Signed URL of the user's avatar (null when none or unavailable).
final avatarUrlProvider = FutureProvider<String?>((ref) async {
  ref.watch(currentSessionProvider);
  return ref.read(profileRepositoryProvider).fetchAvatarUrl();
});

/// Picker seam so tests can avoid the browser file chooser.
final avatarPickerProvider = Provider<Future<AvatarFile?> Function()>(
  (ref) => pickAvatarFile,
);

/// Picks and uploads a new avatar image (COM-021).
class AvatarUploadNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Returns true when a new photo was uploaded; false if cancelled/failed.
  Future<bool> changePhoto() async {
    final actor = ref.read(currentSessionProvider)?.user.id;
    state = const AsyncLoading();
    var uploaded = false;
    final result = await AsyncValue.guard(() async {
      final AvatarFile? file;
      try {
        file = await ref.read(avatarPickerProvider)();
      } on FormatException catch (e) {
        throw ProfileUpdateFailed(e.message);
      } on UnsupportedError {
        throw const ProfileUpdateFailed('Photo upload needs a web browser.');
      }
      if (file == null) return;
      if (!ref.mounted) return;
      if (actor != ref.read(currentSessionProvider)?.user.id) {
        throw const ProfileUpdateFailed(
          'Your account changed. Choose the photo again.',
        );
      }
      await ref.read(profileRepositoryProvider).uploadAvatar(file);
      if (!ref.mounted || actor != ref.read(currentSessionProvider)?.user.id)
        return;
      uploaded = true;
    });
    if (!ref.mounted) return false;
    state = result;
    if (uploaded) ref.invalidate(avatarUrlProvider);
    return uploaded;
  }
}

final avatarUploadProvider = AsyncNotifierProvider<AvatarUploadNotifier, void>(
  AvatarUploadNotifier.new,
);

/// Convenience: returns the current error if the edit failed.
ProfileFailure? profileEditError(AsyncValue<void> state) {
  return state.error is ProfileFailure ? state.error as ProfileFailure : null;
}
