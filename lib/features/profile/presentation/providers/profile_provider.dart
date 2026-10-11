import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/profile/data/profile_repository.dart';
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

final profileEditProvider =
    AsyncNotifierProvider<ProfileEditNotifier, void>(ProfileEditNotifier.new);

/// Convenience: returns the current error if the edit failed.
ProfileFailure? profileEditError(AsyncValue<void> state) {
  return state.error is ProfileFailure ? state.error as ProfileFailure : null;
}
