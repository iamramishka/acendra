import 'dart:convert';
import 'dart:typed_data';
import 'package:acendra/features/admin/data/repositories/admin_artwork_repository.dart';
import 'package:acendra/features/admin/presentation/widgets/courses/admin_course_thumbnail.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Artwork implements AdminArtworkRepository {
  int requests = 0;
  @override
  Future<Uint8List> read(String courseId) async {
    requests++;
    return base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aV1sAAAAASUVORK5CYII=',
    );
  }
}

void main() {
  testWidgets(
    'draft card fetches authenticated bytes and removes them at logout',
    (tester) async {
      final repository = Artwork();
      final session = Session(
        accessToken: 'synthetic',
        tokenType: 'bearer',
        user: const User(
          id: 'actor',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-10-19T00:00:00Z',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          currentSessionProvider.overrideWithValue(session),
          adminArtworkRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 64,
                height: 48,
                child: AdminCourseThumbnail(
                  courseId: 'course',
                  title: 'Draft',
                  isPublished: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.requests, 1);
      expect(find.byType(Image), findsOneWidget);
      expect(
        tester.widget<Image>(find.byType(Image)).image,
        isA<MemoryImage>(),
      );
      container.updateOverrides([
        currentSessionProvider.overrideWithValue(null),
        adminArtworkRepositoryProvider.overrideWithValue(repository),
      ]);
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
