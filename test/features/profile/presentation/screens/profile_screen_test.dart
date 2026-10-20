import 'dart:typed_data';

import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/providers/logout_provider.dart';
import 'package:acendra/features/profile/data/profile_repository.dart';
import 'package:acendra/features/profile/domain/avatar_file.dart';
import 'package:acendra/features/profile/domain/profile_failure.dart';
import 'package:acendra/features/profile/presentation/providers/profile_provider.dart';
import 'package:acendra/features/profile/presentation/screens/profile_screen.dart';
import 'package:acendra/features/settings/presentation/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo extends ProfileRepository {
  _FakeRepo({this.failName = false, this.failUpload = false})
    : super.forTesting();

  final bool failName;
  final bool failUpload;
  final names = <String>[];
  final uploads = <AvatarFile>[];

  @override
  Future<void> updateDisplayName({required String displayName}) async {
    if (failName) throw const ProfileUpdateFailed('Server error');
    names.add(displayName);
  }

  @override
  Future<void> uploadAvatar(AvatarFile file) async {
    if (failUpload) throw const ProfileUpdateFailed('Upload failed');
    uploads.add(file);
  }

  @override
  Future<String?> fetchAvatarUrl() async => null;
}

Widget _wrap({
  String? displayName,
  String? email,
  _FakeRepo? repo,
  Future<AvatarFile?> Function()? picker,
}) => ProviderScope(
  overrides: [
    displayNameProvider.overrideWithValue(displayName),
    currentEmailProvider.overrideWithValue(email),
    logoutProvider.overrideWith(LogoutNotifier.new),
    authStreamProvider.overrideWith((ref) => const Stream.empty()),
    profileRepositoryProvider.overrideWithValue(repo ?? _FakeRepo()),
    if (picker != null) avatarPickerProvider.overrideWithValue(picker),
  ],
  child: const MaterialApp(home: ProfileScreen()),
);

Finder get _save => find.widgetWithText(ElevatedButton, 'Save Changes');

bool _saveEnabled(WidgetTester t) => t.widget<ElevatedButton>(_save).enabled;

void main() {
  setUp(() {});

  testWidgets('shows My Profile title, initials avatar, name and email', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(displayName: 'Jane Doe', email: 'jane@example.com'),
    );
    await tester.pumpAndSettle();
    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('JD'), findsOneWidget);
    expect(find.text('Jane Doe'), findsWidgets);
    expect(find.text('jane@example.com'), findsWidgets);
  });

  testWidgets('single initial and email fallback', (tester) async {
    await tester.pumpWidget(_wrap(displayName: 'Jane', email: 'j@example.com'));
    await tester.pumpAndSettle();
    expect(find.text('J'), findsOneWidget);
    await tester.pumpWidget(_wrap(email: 'alice@example.com'));
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('email is read-only with lock and note', (tester) async {
    await tester.pumpWidget(_wrap(displayName: 'Jane', email: 'j@example.com'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.text("Email can't be changed here."), findsOneWidget);
    final emailField = find.descendant(
      of: find.byKey(const ValueKey('profile-email-j@example.com')),
      matching: find.byType(TextField),
    );
    expect(emailField, findsOneWidget);
    expect(tester.widget<TextField>(emailField).readOnly, isTrue);
  });

  testWidgets('Save Changes is disabled until name changes and is valid', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(displayName: 'Jane', email: 'j@example.com'));
    await tester.pumpAndSettle();
    expect(_saveEnabled(tester), isFalse);

    await tester.enterText(find.byKey(const Key('profile-name-field')), 'Jan');
    await tester.pump();
    expect(_saveEnabled(tester), isTrue);

    await tester.enterText(find.byKey(const Key('profile-name-field')), '   ');
    await tester.pump();
    expect(_saveEnabled(tester), isFalse);

    await tester.enterText(find.byKey(const Key('profile-name-field')), 'Jane');
    await tester.pump();
    expect(_saveEnabled(tester), isFalse);
  });

  testWidgets('saving trims name, calls repository, confirms, disables', (
    tester,
  ) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(
      _wrap(displayName: 'Jane', email: 'j@example.com', repo: repo),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('profile-name-field')),
      '  Janet  ',
    );
    await tester.pump();
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(repo.names, ['Janet']);
    expect(find.text('Profile updated'), findsOneWidget);
    expect(_saveEnabled(tester), isFalse);
  });

  testWidgets('shows error snackbar when save fails and stays enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        displayName: 'Jane',
        email: 'j@example.com',
        repo: _FakeRepo(failName: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('profile-name-field')), 'Jan');
    await tester.pump();
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.text('Server error'), findsOneWidget);
    expect(_saveEnabled(tester), isTrue);
  });

  testWidgets('language offers English and Sinhala only and persists', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        displayNameProvider.overrideWithValue('Jane'),
        currentEmailProvider.overrideWithValue('j@example.com'),
        logoutProvider.overrideWith(LogoutNotifier.new),
        authStreamProvider.overrideWith((ref) => const Stream.empty()),
        profileRepositoryProvider.overrideWithValue(_FakeRepo()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Preferred Language'), findsOneWidget);
    expect(_saveEnabled(tester), isFalse);

    await tester.ensureVisible(find.byKey(const Key('profile-language-field')));
    await tester.tap(find.byKey(const Key('profile-language-field')));
    await tester.pumpAndSettle();
    expect(find.text('Tamil'), findsNothing);
    expect(find.text('English'), findsWidgets);
    await tester.tap(find.text('සිංහල').last);
    await tester.pumpAndSettle();
    expect(_saveEnabled(tester), isTrue);

    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(container.read(preferredLanguageProvider), AppLanguage.sinhala);
    expect(_saveEnabled(tester), isFalse);
  });

  testWidgets('Order History and Settings rows and Sign out are present', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(email: 'test@example.com'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Sign out'), 200);
    expect(find.text('Order History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('Change Photo uploads the picked image', (tester) async {
    final repo = _FakeRepo();
    final file = AvatarFile(name: 'me.png', bytes: Uint8List.fromList([1, 2]));
    await tester.pumpWidget(
      _wrap(
        displayName: 'Jane',
        email: 'j@example.com',
        repo: repo,
        picker: () async => file,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change Photo'));
    await tester.pumpAndSettle();
    expect(repo.uploads, [file]);
    expect(find.text('Photo updated'), findsOneWidget);
  });

  testWidgets('Change Photo does nothing when picker is cancelled', (
    tester,
  ) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(
      _wrap(
        displayName: 'Jane',
        email: 'j@example.com',
        repo: repo,
        picker: () async => null,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change Photo'));
    await tester.pumpAndSettle();
    expect(repo.uploads, isEmpty);
    expect(find.text('Photo updated'), findsNothing);
  });

  testWidgets('Change Photo shows picker validation message', (tester) async {
    await tester.pumpWidget(
      _wrap(
        displayName: 'Jane',
        email: 'j@example.com',
        picker: () async => throw const FormatException('Image too big'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change Photo'));
    await tester.pumpAndSettle();
    expect(find.text('Image too big'), findsOneWidget);
  });

  testWidgets('Change Photo shows upload failure', (tester) async {
    final file = AvatarFile(name: 'me.jpg', bytes: Uint8List.fromList([1]));
    await tester.pumpWidget(
      _wrap(
        displayName: 'Jane',
        email: 'j@example.com',
        repo: _FakeRepo(failUpload: true),
        picker: () async => file,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change Photo'));
    await tester.pumpAndSettle();
    expect(find.text('Upload failed'), findsOneWidget);
  });
}
