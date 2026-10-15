import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedLessonProgress {
  const SavedLessonProgress({
    required this.lessonId,
    required this.completed,
    this.pdfPage,
    this.pdfPosition,
    this.videoSeconds,
    this.lastOpenedAt,
  });

  final String lessonId;
  final bool completed;
  final int? pdfPage;
  final double? pdfPosition;
  final int? videoSeconds;
  final DateTime? lastOpenedAt;

  factory SavedLessonProgress.fromJson(Map<String, dynamic> row) =>
      SavedLessonProgress(
        lessonId: row['lesson_id'] as String,
        completed: row['is_completed'] as bool,
        pdfPage: row['pdf_page'] as int?,
        pdfPosition: (row['pdf_position'] as num?)?.toDouble(),
        videoSeconds: row['progress_seconds'] as int?,
        lastOpenedAt: DateTime.tryParse(row['last_opened_at'] as String? ?? ''),
      );
}

abstract class LearningProgressRepository {
  Future<List<SavedLessonProgress>> read(String courseId);
  Future<SavedLessonProgress> saveCompletion(
    String lessonId,
    bool completed,
    SavedLessonProgress? previous,
  );
  Future<SavedLessonProgress> saveVideoPosition(
    String lessonId,
    int videoSeconds,
    SavedLessonProgress? previous,
  );
}

class SupabaseLearningProgressRepository implements LearningProgressRepository {
  const SupabaseLearningProgressRepository(this.client);
  final SupabaseClient client;

  @override
  Future<List<SavedLessonProgress>> read(String courseId) async {
    final data = await client.rpc(
      'csa133_read_progress',
      params: {'p_course': courseId},
    );
    return (data as List<dynamic>)
        .map((row) => SavedLessonProgress.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SavedLessonProgress> saveVideoPosition(
    String lessonId,
    int videoSeconds,
    SavedLessonProgress? previous,
  ) async {
    final data = await client.rpc(
      'csa133_save_progress',
      params: {
        'p_lesson': lessonId,
        'p_completed': previous?.completed ?? false,
        'p_pdf_page': previous?.pdfPage,
        'p_pdf_position': previous?.pdfPosition,
        'p_video_seconds': videoSeconds,
      },
    );
    return SavedLessonProgress.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<SavedLessonProgress> saveCompletion(
    String lessonId,
    bool completed,
    SavedLessonProgress? previous,
  ) async {
    final data = await client.rpc(
      'csa133_save_progress',
      params: {
        'p_lesson': lessonId,
        'p_completed': completed,
        // The RPC replaces the snapshot; preserve existing resume positions.
        'p_pdf_page': previous?.pdfPage,
        'p_pdf_position': previous?.pdfPosition,
        'p_video_seconds': previous?.videoSeconds,
      },
    );
    return SavedLessonProgress.fromJson(data as Map<String, dynamic>);
  }
}

final learningProgressRepositoryProvider = Provider<LearningProgressRepository>(
  (ref) => SupabaseLearningProgressRepository(Supabase.instance.client),
);
