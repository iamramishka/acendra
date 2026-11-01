import 'dart:async';
import 'dart:typed_data';

import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/profile/data/profile_repository.dart';
import 'package:acendra/features/profile/domain/avatar_file.dart';
import 'package:acendra/features/profile/presentation/providers/profile_provider.dart';
import 'package:acendra/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _session = StateProvider<Session?>((ref) => null);
Session session(String id) => Session(
  accessToken: 'synthetic-token',
  tokenType: 'bearer',
  user: User(
    id: id,
    appMetadata: const {},
    userMetadata: {'full_name': id},
    aud: 'authenticated',
    createdAt: '2026-10-20T00:00:00Z',
  ),
);

class _Repository extends ProfileRepository {
  _Repository() : super.forTesting();
  int uploads = 0;
  Completer<void>? localeSave;
  @override
  Future<void> updateLocale(String? locale) async {
    await localeSave?.future;
  }

  @override
  Future<void> uploadAvatar(AvatarFile file) async {
    uploads++;
  }
}

void main() {
  testWidgets(
    'late language save cannot confirm an update for another account',
    (tester) async {
      final repository = _Repository()..localeSave = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          currentSessionProvider.overrideWith((ref) => ref.watch(_session)),
          profileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      container.read(_session.notifier).state = session('same-user');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('profile-language-field')),
      );
      await tester.tap(find.byKey(const Key('profile-language-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('සිංහල').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      container.read(_session.notifier).state = session('other-user');
      await tester.pumpAndSettle();
      repository.localeSave!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Profile updated'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('switching accounts discards unsaved profile fields', (
    tester,
  ) async {
    final repository = _Repository();
    final container = ProviderContainer(
      overrides: [
        currentSessionProvider.overrideWith((ref) => ref.watch(_session)),
        profileRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.read(_session.notifier).state = session('same-user');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Unsaved old name');
    await tester.pump();
    container.read(_session.notifier).state = session('other-user');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'other-user',
    );
    expect(find.text('Unsaved old name'), findsNothing);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Save Changes'),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
  for (final next in ['other-user', 'same-user', null]) {
    test('pending avatar selection respects account change to $next', () async {
      final picker = Completer<AvatarFile?>();
      final repository = _Repository();
      final container = ProviderContainer(
        overrides: [
          currentSessionProvider.overrideWith((ref) => ref.watch(_session)),
          profileRepositoryProvider.overrideWithValue(repository),
          avatarPickerProvider.overrideWithValue(() => picker.future),
        ],
      );
      addTearDown(container.dispose);
      container.read(_session.notifier).state = session('same-user');
      await container.read(avatarUploadProvider.future);
      final result = container
          .read(avatarUploadProvider.notifier)
          .changePhoto();
      container.read(_session.notifier).state = next == null
          ? null
          : session(next);
      picker.complete(
        AvatarFile(name: 'photo.png', bytes: Uint8List.fromList([1])),
      );
      expect(await result, next == 'same-user');
      expect(repository.uploads, next == 'same-user' ? 1 : 0);
    });
  }
  test(
    'disposing a pending avatar picker does not update disposed state',
    () async {
      final picker = Completer<AvatarFile?>();
      final repository = _Repository();
      final container = ProviderContainer(
        overrides: [
          currentSessionProvider.overrideWithValue(session('same-user')),
          profileRepositoryProvider.overrideWithValue(repository),
          avatarPickerProvider.overrideWithValue(() => picker.future),
        ],
      );
      await container.read(avatarUploadProvider.future);
      final result = container
          .read(avatarUploadProvider.notifier)
          .changePhoto();
      container.dispose();
      picker.complete(
        AvatarFile(name: 'photo.png', bytes: Uint8List.fromList([1])),
      );
      expect(await result, false);
      expect(repository.uploads, 0);
    },
  );
}
