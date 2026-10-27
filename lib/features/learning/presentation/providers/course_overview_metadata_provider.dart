import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/my_courses/data/repositories/supabase_my_courses_repository.dart';
import 'package:acendra/features/my_courses/domain/entities/enrolled_course.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reuses the owned-course metadata read without fetching protected lessons.
/// Metadata and progress have independent failure boundaries.
final courseOverviewMetadataProvider = FutureProvider.autoDispose
    .family<EnrolledCourse?, String>((ref, courseId) async {
      if (ref.watch(currentSessionProvider) == null) return null;
      final courses = await ref
          .watch(myCoursesRepositoryProvider)
          .listEnrolled();
      if (!ref.mounted) return null;
      return courses.where((course) => course.courseId == courseId).firstOrNull;
    }, retry: (_, _) => null);
