import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:flutter/material.dart';

/// Sidebar curriculum navigation widget for the learning workspace.
///
/// Displays a scrollable list of [CurriculumSection]s, each expandable to show
/// its [LessonItem]s. The section containing [currentLessonId] is expanded by
/// default and the matching lesson tile is highlighted.
class CurriculumNav extends StatelessWidget {
  const CurriculumNav({
    super.key,
    required this.sections,
    required this.onLessonTap,
    this.currentLessonId,
  });

  final List<CurriculumSection> sections;
  final String? currentLessonId;
  final void Function(String lessonId) onLessonTap;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          'No curriculum available yet.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return ListView.builder(
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        final isExpanded = section.lessons.any((l) => l.id == currentLessonId);
        return _SectionTile(
          section: section,
          initiallyExpanded: isExpanded,
          currentLessonId: currentLessonId,
          onLessonTap: onLessonTap,
        );
      },
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.section,
    required this.initiallyExpanded,
    required this.onLessonTap,
    this.currentLessonId,
  });

  final CurriculumSection section;
  final bool initiallyExpanded;
  final String? currentLessonId;
  final void Function(String lessonId) onLessonTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      tilePadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      title: Text(
        '${section.position}. ${section.title}',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      children: section.lessons
          .map(
            (lesson) => _LessonTile(
              lesson: lesson,
              isSelected: lesson.id == currentLessonId,
              onTap: () => onLessonTap(lesson.id),
            ),
          )
          .toList(),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.isSelected,
    required this.onTap,
  });

  final LessonItem lesson;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Semantics(
      label:
          '${lesson.title}, ${lesson.typeLabel}${isSelected ? ', currently selected' : ''}',
      selected: isSelected,
      child: ListTile(
        dense: true,
        selected: isSelected,
        selectedTileColor: cs.primaryContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 0,
        ),
        leading: Icon(
          _typeIcon(lesson.lessonType),
          size: 18,
          color: isSelected ? cs.onPrimaryContainer : null,
        ),
        title: Text(
          lesson.title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected ? cs.onPrimaryContainer : null,
          ),
        ),
        trailing: _buildTrailing(context, cs),
        onTap: onTap,
      ),
    );
  }

  Widget? _buildTrailing(BuildContext context, ColorScheme cs) {
    final durationWidget = lesson.durationSeconds != null
        ? Text(
            _formatDuration(lesson.durationSeconds!),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
          )
        : null;

    final previewChip = lesson.isPreview
        ? Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              'Preview',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        : null;

    if (previewChip != null && durationWidget != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          previewChip,
          const SizedBox(width: AppSpacing.xs),
          durationWidget,
        ],
      );
    }
    return previewChip ?? durationWidget;
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  IconData _typeIcon(String type) => switch (type) {
    'video' => Icons.play_circle_outline,
    'pdf' => Icons.picture_as_pdf_outlined,
    'text' => Icons.article_outlined,
    'image' => Icons.image_outlined,
    _ => Icons.info_outline,
  };
}
