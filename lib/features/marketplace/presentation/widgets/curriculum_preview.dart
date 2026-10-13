import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:flutter/material.dart';

class CurriculumPreview extends StatelessWidget {
  const CurriculumPreview({super.key, required this.sections});

  final List<CurriculumSection> sections;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No curriculum available yet.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((s) => _SectionTile(section: s)).toList(),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.section});
  final CurriculumSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      title: Text(section.title, style: theme.textTheme.titleSmall),
      subtitle: Text(
        '${section.lessons.length} lesson${section.lessons.length == 1 ? '' : 's'}',
        style: theme.textTheme.bodySmall,
      ),
      children: section.lessons.map((l) => _LessonTile(lesson: l)).toList(),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson});
  final LessonItem lesson;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(_typeIcon(lesson.lessonType), size: 18),
      title: Text(lesson.title),
      trailing: lesson.isPreview
          ? Chip(
              label: const Text('Preview'),
              padding: EdgeInsets.zero,
              labelStyle: Theme.of(context).textTheme.labelSmall,
            )
          : null,
    );
  }

  IconData _typeIcon(String type) => switch (type) {
    'video' => Icons.play_circle_outline,
    'pdf' => Icons.picture_as_pdf_outlined,
    'text' => Icons.article_outlined,
    _ => Icons.info_outline,
  };
}
