import 'package:acendra/core/widgets/cards/course_thumbnail.dart';
import 'package:acendra/features/dashboard/domain/entities/student_home.dart';
import 'package:acendra/features/my_courses/domain/entities/course_progress.dart';
import 'package:acendra/features/my_courses/domain/entities/enrolled_course.dart';
import 'package:flutter/material.dart';

class StudentResumeCard extends StatelessWidget {
  const StudentResumeCard({
    super.key,
    required this.lesson,
    required this.progress,
    required this.onResume,
  });
  final HomeLesson lesson;
  final CourseProgress progress;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff0b1e4f), Color(0xff123a9c), Color(0xff1e6bff)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CONTINUE LEARNING',
              style: text.labelLarge?.copyWith(
                color: const Color(0xff9ce6ff),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              lesson.course.title,
              style: text.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lesson.lesson.title,
              style: text.bodyLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              '${progress.percent}% complete',
              style: text.titleSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.fraction,
              semanticsLabel: '${lesson.course.title} progress',
              semanticsValue: '${progress.percent}%',
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xff58d2f4),
              backgroundColor: Colors.white24,
            ),
            const SizedBox(height: 8),
            Text(
              '${progress.completedLessons} of ${progress.totalLessons} lessons completed',
              style: text.bodyMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onResume,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xff0b1e4f),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Resume Learning'),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentOwnedCourseCard extends StatelessWidget {
  const StudentOwnedCourseCard({
    super.key,
    required this.course,
    this.progress,
    required this.onOpen,
  });
  final EnrolledCourse course;
  final CourseProgress? progress;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = progress;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1.7,
            child: CourseThumbnail(
              courseId: course.courseId,
              title: course.title,
              imageUrl: course.thumbnailUrl,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title, style: text.titleMedium),
                if (course.shortDescription.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    course.shortDescription,
                    style: text.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                if (p == null)
                  const Text('Progress unavailable')
                else ...[
                  Text('${p.percent}%', style: text.titleSmall),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: p.fraction,
                    semanticsLabel: '${course.title} progress',
                    semanticsValue: '${p.percent}%',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${p.completedLessons} of ${p.totalLessons} lessons completed',
                    style: text.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onOpen,
                  child: Text(
                    p == null
                        ? 'Open Course'
                        : p.isCompleted
                        ? 'Review Course'
                        : p.isStarted
                        ? 'Continue'
                        : 'Get Started',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StudentRecentLesson extends StatelessWidget {
  const StudentRecentLesson({
    super.key,
    required this.lesson,
    required this.onOpen,
  });
  final HomeLesson lesson;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final pdf = lesson.lesson.lessonType == 'pdf';
    final page = lesson.pdfPage;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          pdf
              ? Icons.picture_as_pdf_outlined
              : lesson.lesson.lessonType == 'video'
              ? Icons.play_circle_outline
              : Icons.article_outlined,
        ),
        title: Text(lesson.lesson.title),
        subtitle: Text(
          '${lesson.course.title}\n'
          '${pdf ? 'PDF' : 'Lesson ${lesson.number} · ${lesson.lesson.typeLabel}'}'
          '${pdf && page != null && page > 0 ? ' · page $page' : ''}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onOpen,
      ),
    );
  }
}
