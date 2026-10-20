import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/providers/logout_provider.dart';
import 'package:acendra/features/profile/data/profile_repository.dart';
import 'package:acendra/features/profile/presentation/providers/profile_provider.dart';
import 'package:acendra/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo extends ProfileRepository {
  _Repo() : super.forTesting();

  @override
  Future<String?> fetchAvatarUrl() async => null;
}

void main() {
  testWidgets('legacy edit route renders the merged My Profile screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          displayNameProvider.overrideWithValue('Jane Doe'),
          currentEmailProvider.overrideWithValue('jane@example.com'),
          logoutProvider.overrideWith(LogoutNotifier.new),
          authStreamProvider.overrideWith((ref) => const Stream.empty()),
          profileRepositoryProvider.overrideWithValue(_Repo()),
        ],
        child: const MaterialApp(home: ProfileEditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });
}
