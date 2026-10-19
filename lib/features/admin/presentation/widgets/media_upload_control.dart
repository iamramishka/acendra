import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/features/admin/data/repositories/admin_media_repository.dart';
import 'package:acendra/features/admin/data/media_picker.dart'
    if (dart.library.js_interop) 'package:acendra/features/admin/data/media_picker_web.dart';
import 'courses/admin_course_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mediaPickerProvider = Provider<Future<MediaFile?> Function(bool)>(
  (ref) =>
      (pdf) => pickMediaFile(pdf: pdf),
);

class MediaUploadControl extends ConsumerStatefulWidget {
  const MediaUploadControl({super.key, required this.courseId, this.lessonId});
  final String courseId;
  final String? lessonId;
  @override
  ConsumerState<MediaUploadControl> createState() => _MediaUploadControlState();
}

class _MediaUploadControlState extends ConsumerState<MediaUploadControl> {
  bool _busy = false;
  String? _message;
  MediaFile? _artwork;
  int _operation = 0;

  @override
  void didUpdateWidget(covariant MediaUploadControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courseId != widget.courseId ||
        oldWidget.lessonId != widget.lessonId) {
      _operation++;
      _busy = false;
      _message = null;
      _artwork = null;
    }
  }

  Future<void> _upload() async {
    final operation = ++_operation;
    final courseId = widget.courseId;
    final lessonId = widget.lessonId;
    bool current() => mounted && operation == _operation;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final file = await ref.read(mediaPickerProvider)(lessonId != null);
      if (!current() || file == null) return;
      await ref
          .read(adminMediaRepositoryProvider)
          .upload(courseId: courseId, lessonId: lessonId, file: file);
      if (!current()) return;
      if (lessonId == null) ref.invalidate(adminArtworkProvider(courseId));
      setState(() {
        _artwork = lessonId == null ? file : null;
        _message = lessonId == null
            ? 'Artwork uploaded and inspected.'
            : 'PDF uploaded and inspected.';
      });
    } on FormatException catch (error) {
      if (current()) setState(() => _message = error.message);
    } catch (_) {
      if (current()) setState(() => _message = 'Upload failed. Retry.');
    } finally {
      if (current()) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        widget.lessonId == null ? 'Course artwork' : 'Lesson PDF',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 8),
      Text(
        widget.lessonId == null
            ? 'JPG or PNG, up to 5 MB. Published course artwork is public.'
            : 'PDF, up to 50 MB. Files are inspected before they become available.',
      ),
      const SizedBox(height: 8),
      if (_artwork != null) ...[
        SizedBox(
          height: 120,
          child: Image.memory(
            _artwork!.bytes,
            semanticLabel: 'Inspected course artwork',
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 8),
      ],
      AppButton(
        label: _busy ? 'Uploading and inspecting…' : 'Upload file',
        onPressed: _busy ? null : _upload,
        isLoading: _busy,
        variant: ButtonVariant.outlined,
      ),
      if (_busy)
        Semantics(
          liveRegion: true,
          child: const Text('Uploading and inspecting…'),
        ),
      if (_message != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Semantics(liveRegion: true, child: Text(_message!)),
        ),
    ],
  );
}
