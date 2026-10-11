import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/profile/data/profile_repository.dart';
import 'package:acendra/features/profile/domain/profile_failure.dart';
import 'package:acendra/features/profile/presentation/providers/profile_provider.dart';
import 'package:acendra/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository({this.shouldFail = false}) : super.forTesting();

  final bool shouldFail;

  @override
  Future<void> updateDisplayName({required String displayName}) async {
    if (shouldFail) throw const ProfileUpdateFailed('Server error');
  }
}

Widget _wrap({bool shouldFail = false, String? currentName}) => ProviderScope(
      overrides: [
        profileRepositoryProvider
            .overrideWithValue(_FakeProfileRepository(shouldFail: shouldFail)),
        displayNameProvider.overrideWithValue(currentName),
        authStreamProvider.overrideWith((ref) => const Stream.empty()),
      ],
      child: const MaterialApp(home: ProfileEditScreen()),
    );

void main() {
  testWidgets('renders edit profile screen with display name field',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
  });

  testWidgets('pre-fills current display name', (tester) async {
    await tester.pumpWidget(_wrap(currentName: 'Jane Doe'));
    await tester.pumpAndSettle();
    expect(find.text('Jane Doe'), findsOneWidget);
  });

  testWidgets('shows validation error when name is empty', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(find.text('Display name cannot be empty'), findsOneWidget);
  });

  testWidgets('shows success snackbar on successful update', (tester) async {
    // Wrap in a two-route navigator so that pop() has a target and the
    // ScaffoldMessenger of the home scaffold can display the snackbar.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(
              _FakeProfileRepository()),
          displayNameProvider.overrideWithValue(null),
          authStreamProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.of(ctx).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProfileEditScreen(),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'New Name');
    await tester.tap(find.text('Save changes'));
    await tester.pump(); // start async
    await tester.pump(const Duration(milliseconds: 100)); // finish notifier
    await tester.pump(); // snackbar shown, screen popping

    expect(find.text('Profile updated'), findsOneWidget);
  });

  testWidgets('shows error snackbar when update fails', (tester) async {
    await tester.pumpWidget(_wrap(shouldFail: true));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'New Name');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Server error'), findsOneWidget);
  });
}
