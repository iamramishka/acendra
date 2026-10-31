import 'dart:math' as math;

import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/lesson_item.dart';
import 'package:acendra/features/video_player/presentation/widgets/authorized_video_widget.dart';
import 'package:flutter/material.dart';

/// Lists real PDF lessons from this module. Opening one still goes through the
/// existing lesson route and protected PDF authorization, never a raw file URL.
class VideoLessonPanel extends StatefulWidget {
  const VideoLessonPanel({
    super.key,
    required this.lessonId,
    required this.title,
    required this.sectionId,
    required this.sections,
    required this.onResource,
    this.initialVideoSeconds,
    this.onVideoSeconds,
  });
  final String lessonId, title, sectionId;
  final List<CurriculumSection> sections;
  final ValueChanged<String> onResource;
  final int? initialVideoSeconds;
  final ValueChanged<int>? onVideoSeconds;
  @override
  State<VideoLessonPanel> createState() => _VideoLessonPanelState();
}

class _VideoLessonPanelState extends State<VideoLessonPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this)..addListener(_tabChanged);
  }

  void _tabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabs.removeListener(_tabChanged);
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resources = <LessonItem>[
      for (final section in widget.sections)
        if (section.id == widget.sectionId)
          for (final lesson in section.lessons)
            if (lesson.lessonType == 'pdf') lesson,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxPlayerWidth = math.min(
          math.max(0.0, constraints.maxWidth - 2 * AppSpacing.md),
          (constraints.maxHeight * .65).clamp(180.0, 480.0) * 16 / 10,
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxPlayerWidth),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: AuthorizedVideoWidget(
                      key: ValueKey(widget.lessonId),
                      lessonId: widget.lessonId,
                      title: widget.title,
                      initialVideoSeconds: widget.initialVideoSeconds,
                      onVideoSeconds: widget.onVideoSeconds,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Resources'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (_tabs.index == 0) ...[
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Learn at your own pace. Mark this lesson complete when you are ready to continue.',
                ),
              ] else if (resources.isEmpty)
                const Text('No PDF resources are available in this module.')
              else ...[
                const Text('PDF lessons in this module'),
                for (final resource in resources)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: Text(resource.title),
                      subtitle: const Text('Open in protected reader'),
                      onTap: () => widget.onResource(resource.id),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
