import 'package:acendra/features/pdf_reader/domain/entities/pdf_outline_entry.dart';
import 'package:flutter/material.dart';

/// Index of the chapter containing [page]: the last entry whose page is at or
/// before it, or -1 when none applies.
int currentChapterIndex(List<PdfOutlineEntry> entries, int page) {
  var result = -1;
  for (var i = 0; i < entries.length; i++) {
    if (entries[i].page <= page) result = i;
  }
  return result;
}

/// Opens the document Contents sheet; tapping an entry jumps to its page.
Future<void> showPdfContentsSheet(
  BuildContext context, {
  required List<PdfOutlineEntry> entries,
  required int currentPage,
  required ValueChanged<int> onGoToPage,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => PdfContentsSheet(
      entries: entries,
      currentPage: currentPage,
      onGoToPage: (page) {
        Navigator.of(ctx).pop();
        onGoToPage(page);
      },
    ),
  );
}

class PdfContentsSheet extends StatelessWidget {
  const PdfContentsSheet({
    super.key,
    required this.entries,
    required this.currentPage,
    required this.onGoToPage,
  });

  final List<PdfOutlineEntry> entries;
  final int currentPage;
  final ValueChanged<int> onGoToPage;

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
              child: Text('Contents', style: theme.textTheme.titleMedium),
            ),
            const Divider(height: 1),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'This document has no table of contents.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    return ListTile(
                      selected: i == current,
                      contentPadding: EdgeInsets.only(
                        left: 16.0 + 16 * e.level,
                        right: 16,
                      ),
                      title: Text(e.title),
                      trailing: Text('${e.page}'),
                      onTap: () => onGoToPage(e.page),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
