import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogoutNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signOut(),
    );
  }
}

final logoutProvider = AsyncNotifierProvider<LogoutNotifier, void>(
  LogoutNotifier.new,
);
