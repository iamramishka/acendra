import 'dart:async';
import 'dart:typed_data';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/features/admin/data/repositories/admin_media_repository.dart';
import 'package:acendra/features/admin/domain/media_file.dart';
import 'package:acendra/features/admin/presentation/widgets/media_upload_control.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Session _identity(String id, [String token = 'synthetic']) => Session(
  accessToken: token,
  tokenType: 'bearer',
  user: User(
    id: id,
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-11-01',
  ),
);
final _session = StateProvider<Session?>((_) => _identity('admin-a'));

class Uploads implements AdminMediaRepository {
  Completer<void>? pending;
  bool fail = false;
  int calls = 0;
  final courses = <String>[];
  @override
  Future<void> upload({
    required String courseId,
    String? lessonId,
    required MediaFile file,
  }) async {
    calls++;
    courses.add(courseId);
    if (fail) {
      throw const FormatException('Inspection did not complete. Retry.');
    }
    await pending?.future;
  }
}

void main() {
  testWidgets('signed-out control cannot open a file picker', (tester) async {
    var pickerCalls = 0;
    final uploads = Uploads();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSessionProvider.overrideWithValue(null),
          adminMediaRepositoryProvider.overrideWithValue(uploads),
          mediaPickerProvider.overrideWithValue((_) async {
            pickerCalls++;
            return MediaFile(name: 'cover.png', bytes: Uint8List(1));
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MediaUploadControl(courseId: 'course')),
        ),
      ),
    );
    expect(tester.widget<AppButton>(find.byType(AppButton)).onPressed, isNull);
    await tester.tap(find.text('Upload file'));
    await tester.pump();
    expect(pickerCalls, 0);
    expect(uploads.calls, 0);
  });

  for (final change in ['account', 'logout', 'token']) {
    for (final phase in ['picker', 'upload', 'preview', 'error']) {
      testWidgets(
        '$change clears and invalidates $phase from original session',
        (tester) async {
          final uploads = Uploads()..pending = Completer<void>();
          final picked = Completer<MediaFile?>();
          final container = ProviderContainer(
            overrides: [
              currentSessionProvider.overrideWith((ref) => ref.watch(_session)),
              adminMediaRepositoryProvider.overrideWithValue(uploads),
              mediaPickerProvider.overrideWithValue((_) => picked.future),
            ],
          );
          addTearDown(container.dispose);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(
                home: Scaffold(body: MediaUploadControl(courseId: 'course')),
              ),
            ),
          );
          await tester.tap(find.text('Upload file'));
          await tester.pump();
          final file = MediaFile(name: 'cover.png', bytes: Uint8List(1));
          if (phase != 'picker') {
            picked.complete(file);
            await tester.pump();
            expect(uploads.calls, 1);
          }
          if (phase == 'preview') {
            uploads.pending!.complete();
            await tester.pumpAndSettle();
            expect(
              find.text('Artwork uploaded and inspected.'),
              findsOneWidget,
            );
            expect(find.byType(Image), findsOneWidget);
          }
          container.read(_session.notifier).state = switch (change) {
            'logout' => null,
            'token' => _identity('admin-a', 'refreshed'),
            _ => _identity('admin-b'),
          };
          await tester.pump();
          if (phase == 'picker') picked.complete(file);
          if (phase == 'error') {
            uploads.pending!.completeError(
              const FormatException('Old session inspection failed.'),
            );
          } else if (phase != 'preview') {
            uploads.pending!.complete();
          }
          await tester.pumpAndSettle();
          expect(uploads.calls, phase == 'picker' ? 0 : 1);
          expect(find.byType(Image), findsNothing);
          expect(find.text('Artwork uploaded and inspected.'), findsNothing);
          expect(find.text('Old session inspection failed.'), findsNothing);
          expect(find.text('Uploading and inspecting…'), findsNothing);
          if (change != 'logout') {
            // The new session can explicitly select again after the old result
            // was discarded. Cancelling stale work must not disable future work.
            await tester.tap(find.text('Upload file'));
            await tester.pumpAndSettle();
            expect(
              find.text('Artwork uploaded and inspected.'),
              phase == 'error' ? findsNothing : findsOneWidget,
            );
            expect(uploads.calls, phase == 'picker' ? 1 : 2);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final pendingPicker in [true, false]) {
    testWidgets(
      'changing course discards pending ${pendingPicker ? 'selection' : 'upload'}',
      (tester) async {
        final uploads = Uploads()..pending = Completer<void>();
        final picked = Completer<MediaFile?>();
        var course = 'first-course';
        late StateSetter changeCourse;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentSessionProvider.overrideWithValue(_identity('admin-a')),
              adminMediaRepositoryProvider.overrideWithValue(uploads),
              mediaPickerProvider.overrideWithValue((_) => picked.future),
            ],
            child: MaterialApp(
              home: StatefulBuilder(
                builder: (context, setState) {
                  changeCourse = setState;
                  return Scaffold(body: MediaUploadControl(courseId: course));
                },
              ),
            ),
          ),
        );
        await tester.tap(find.text('Upload file'));
        await tester.pump();
        final file = MediaFile(name: 'cover.png', bytes: Uint8List(1));
        if (!pendingPicker) {
          picked.complete(file);
          await tester.pump();
          expect(uploads.courses, ['first-course']);
        }
        changeCourse(() => course = 'second-course');
        await tester.pump();
        if (pendingPicker) picked.complete(file);
        uploads.pending!.complete();
        await tester.pumpAndSettle();
        expect(uploads.courses, pendingPicker ? isEmpty : ['first-course']);
        expect(find.text('Artwork uploaded and inspected.'), findsNothing);
        expect(find.text('Upload file'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final width in [390.0, 768.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'upload progress and inspection status at $width $brightness',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final uploads = Uploads()..pending = Completer<void>();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                currentSessionProvider.overrideWithValue(_identity('admin-a')),
                adminMediaRepositoryProvider.overrideWithValue(uploads),
                mediaPickerProvider.overrideWithValue(
                  (_) async => MediaFile(
                    name: 'cover.png',
                    bytes: Uint8List.fromList([1]),
                  ),
                ),
              ],
              child: MaterialApp(
                theme: ThemeData(brightness: brightness),
                home: const Scaffold(
                  body: MediaUploadControl(courseId: 'course'),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Upload file'));
          await tester.pump();
          expect(find.text('Uploading and inspecting…'), findsOneWidget);
          expect(find.text('Artwork uploaded and inspected.'), findsNothing);
          uploads.pending!.complete();
          await tester.pumpAndSettle();
          expect(find.text('Artwork uploaded and inspected.'), findsOneWidget);
          expect(uploads.calls, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('inspection failure shows retry and preserves failure', (
    tester,
  ) async {
    final uploads = Uploads()..fail = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSessionProvider.overrideWithValue(_identity('admin-a')),
          adminMediaRepositoryProvider.overrideWithValue(uploads),
          mediaPickerProvider.overrideWithValue(
            (_) async => MediaFile(name: 'cover.png', bytes: Uint8List(1)),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MediaUploadControl(courseId: 'course')),
        ),
      ),
    );
    await tester.tap(find.text('Upload file'));
    await tester.pumpAndSettle();
    expect(find.text('Inspection did not complete. Retry.'), findsOneWidget);
    expect(find.text('Artwork uploaded and inspected.'), findsNothing);
    expect(find.text('Upload file'), findsOneWidget);
  });
}
