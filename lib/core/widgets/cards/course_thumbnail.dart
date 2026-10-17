import 'package:flutter/material.dart';

/// A course cover that never treats private storage references as image URLs.
class CourseThumbnail extends StatelessWidget {
  const CourseThumbnail({super.key, required this.title, this.imageUrl});

  final String title;
  final String? imageUrl;

  String? get _url {
    final value = imageUrl?.trim();
    final uri = value == null ? null : Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return null;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    if (url == null) return _cover(context, 'Cover image not provided');
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      semanticLabel: '$title course cover',
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
          wasSynchronouslyLoaded || frame != null
          ? child
          : _cover(context, 'Loading cover image'),
      errorBuilder: (context, error, stackTrace) =>
          _cover(context, 'Cover image unavailable'),
    );
  }

  Widget _cover(BuildContext context, String status) {
    final colors = Theme.of(context).colorScheme;
    final words = title.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final initials = words
        .take(2)
        .map((w) => w.characters.first)
        .join()
        .toUpperCase();
    return Semantics(
      image: true,
      label: '$title. $status',
      child: Tooltip(
        message: status,
        excludeFromSemantics: true,
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.primaryContainer, colors.secondaryContainer],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 80;
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 4 : 16),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            initials.isEmpty ? 'C' : initials,
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  color: colors.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                  fontSize: compact ? 20 : 40,
                                ),
                          ),
                          if (!compact) ...[
                            const SizedBox(height: 8),
                            Text(
                              status,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: colors.onPrimaryContainer),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
