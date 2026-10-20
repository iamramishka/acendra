import 'dart:typed_data';
import 'package:acendra/core/widgets/cards/course_thumbnail.dart';
import 'package:acendra/features/admin/data/repositories/admin_artwork_repository.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminArtworkProvider = FutureProvider.autoDispose
    .family<Uint8List?, String>((ref, courseId) {
      final session = ref.watch(currentSessionProvider);
      if (session == null) return null;
      return ref.watch(adminArtworkRepositoryProvider).read(courseId);
    });

/// Draft bytes are fetched with the current session, never via a bare image URL.
class AdminCourseThumbnail extends ConsumerWidget {
  const AdminCourseThumbnail({
    super.key,
    required this.courseId,
    required this.title,
    required this.isPublished,
    this.imageUrl,
  });
  final String courseId;
  final String title;
  final bool isPublished;
  final String? imageUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isPublished) {
      return CourseThumbnail(
        courseId: courseId,
        title: title,
        imageUrl: imageUrl,
      );
    }
    final fallback = CourseThumbnail(title: title);
    if (ref.watch(currentSessionProvider) == null) return fallback;
    final artwork = ref.watch(adminArtworkProvider(courseId));
    final bytes = artwork.isLoading || artwork.hasError ? null : artwork.value;
    if (bytes == null) return fallback;
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      semanticLabel: '$title draft course cover',
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
