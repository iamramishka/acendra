import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/learning/data/repositories/learning_progress_repository.dart';
import 'package:acendra/features/learning/data/repositories/supabase_learning_repository.dart';
import 'package:acendra/features/learning/domain/course_progress_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Curriculum plus saved progress for the course overview. Read-only: no
/// lesson content is fetched until a lesson is opened.
final courseOverviewProvider = FutureProvider.autoDispose
    .family<CourseProgressSummary, String>((ref, courseId) async {
      // Never reuse one account's progress for another.
      ref.watch(currentSessionProvider.select((s) => s?.user.id));
      final sections = await ref
          .read(learningRepositoryProvider)
          .getCurriculumWithLessons(courseId);
      final saved = await ref
          .read(learningProgressRepositoryProvider)
          .read(courseId);
      return CourseProgressSummary.from(sections, {
        for (final entry in saved) entry.lessonId: entry,
      });
    });
