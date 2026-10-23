import 'package:acendra/features/pdf_reader/domain/entities/pdf_outline_entry.dart';
import 'package:flutter/material.dart';

/// Index of the chapter containing [page]: the last entry whose page is at or
/// before it, or -1 when none applies.
int currentChapterIndex(List<PdfOutlineEntry> entries, int page) {
  var result = -1;
  for (var i = 0; i < entries.length; i++) {
    if (entries[i].page <= page &&
        (result < 0 || entries[i].page >= entries[result].page)) {
      result = i;
    }
  }
  return result;
}

/// Opens the document Contents sheet; tapping an entry jumps to its page.
Future<void> showPdfContentsSheet(
  BuildContext context, {
  required List<PdfOutlineEntry> entries,
  required int currentPage,
  required ValueChanged<int> onGoToPage,
  List<int> bookmarks = const [],
  bool outlineUnavailable = false,
  ValueChanged<Route<dynamic>>? onRouteCreated,
}) {
  final navigator = Navigator.of(context);
  final route = ModalBottomSheetRoute<void>(
    isScrollControlled: true,
    showDragHandle: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    capturedThemes: InheritedTheme.capture(
      from: context,
      to: navigator.context,
    ),
    builder: (ctx) => PdfContentsSheet(
      entries: entries,
      currentPage: currentPage,
      bookmarks: bookmarks,
      outlineUnavailable: outlineUnavailable,
      onGoToPage: (page) {
        Navigator.of(ctx).pop();
        onGoToPage(page);
      },
    ),
  );
  // Capture before push/build so identity changes can remove this exact route,
  // even when the reader disappears before the sheet's first frame.
  onRouteCreated?.call(route);
  return navigator.push<void>(route);
}

class PdfContentsSheet extends StatelessWidget {
  const PdfContentsSheet({
    super.key,
    required this.entries,
    required this.currentPage,
    required this.onGoToPage,
    this.bookmarks = const [],
    this.outlineUnavailable = false,
  });

  final List<PdfOutlineEntry> entries;
  final int currentPage;
  final ValueChanged<int> onGoToPage;
  final List<int> bookmarks;
  final bool outlineUnavailable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = currentChapterIndex(entries, currentPage);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Contents', style: theme.textTheme.titleMedium),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(48),
                      visualDensity: VisualDensity.standard,
                    ),
                    tooltip: 'Close contents',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        outlineUnavailable
                            ? 'Contents could not be loaded. Reopen the guide to retry.'
                            : 'This document has no table of contents.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ...List.generate(entries.length, (i) {
                      final e = entries[i];
                      return ListTile(
                        selected: i == current,
                        leading: ExcludeSemantics(
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: i == current
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primaryContainer,
                            foregroundColor: i == current
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onPrimaryContainer,
                            child: Text(
                              '$i',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: i == current
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                        contentPadding: EdgeInsets.only(
                          left: 16.0 + 16 * e.level.clamp(0, 8),
                          right: 16,
                        ),
                        title: Text(e.title),
                        trailing: Text('p. ${e.page}'),
                        onTap: () => onGoToPage(e.page),
                      );
                    }),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text('Bookmarks', style: theme.textTheme.titleSmall),
                  ),
                  if (bookmarks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Bookmark a page to find it here.'),
                    ),
                  for (final page in bookmarks)
                    ListTile(
                      leading: const Icon(Icons.bookmark),
                      title: Text('Page $page'),
                      selected: page == currentPage,
                      onTap: () => onGoToPage(page),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
