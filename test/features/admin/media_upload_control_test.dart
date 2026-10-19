import 'dart:async';
import 'dart:typed_data';
import 'package:acendra/features/admin/data/repositories/admin_media_repository.dart';
import 'package:acendra/features/admin/domain/media_file.dart';
import 'package:acendra/features/admin/presentation/widgets/media_upload_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class Uploads implements AdminMediaRepository {
  Completer<void>? pending;
  bool fail = false;
  int calls = 0;
  @override
  Future<void> upload({
    required String courseId,
    String? lessonId,
    required MediaFile file,
  }) async {
    calls++;
    if (fail) {
      throw const FormatException('Inspection did not complete. Retry.');
    }
    await pending?.future;
  }
}

void main() {
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
