import 'package:acendra/features/pdf_reader/domain/entities/pdf_bookmark.dart';
import 'package:flutter/material.dart';

/// Side panel that displays the user's PDF bookmarks.
///
/// Accepts:
/// - [bookmarks]    – list of saved bookmarks
/// - [currentPage]  – used to highlight the active page's bookmark
/// - [onGoToPage]   – called when the user taps "Go" on a bookmark
/// - [onClose]      – called when the user dismisses the panel
class PdfBookmarksPanel extends StatelessWidget {
  const PdfBookmarksPanel({
    super.key,
    required this.bookmarks,
    required this.currentPage,
    required this.onGoToPage,
    required this.onClose,
  });

  final List<PdfBookmark> bookmarks;
  final int currentPage;
  final ValueChanged<int> onGoToPage;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: 'Bookmarks panel',
      child: Material(
        elevation: 4,
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        child: SizedBox(
          width: 240,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Bookmarks', style: textTheme.titleSmall),
                    ),
                    Semantics(
                      label: 'Close bookmarks panel',
                      button: true,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                        onPressed: onClose,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: bookmarks.isEmpty
                    ? Center(
                        child: Text(
                          'No bookmarks yet',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: bookmarks.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          final bookmark = bookmarks[index];
                          final isActive = bookmark.page == currentPage;
                          return _BookmarkTile(
                            bookmark: bookmark,
                            isActive: isActive,
                            onGoToPage: onGoToPage,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({
    required this.bookmark,
    required this.isActive,
    required this.onGoToPage,
  });

  final PdfBookmark bookmark;
  final bool isActive;
  final ValueChanged<int> onGoToPage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      dense: true,
      selected: isActive,
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
      leading: Icon(
        Icons.bookmark,
        size: 18,
        color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        bookmark.label ?? 'Page ${bookmark.page}',
        style: textTheme.bodySmall?.copyWith(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        'Page ${bookmark.page}',
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Semantics(
        label: 'Go to page ${bookmark.page}',
        button: true,
        child: TextButton(
          onPressed: () => onGoToPage(bookmark.page),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(40, 32),
          ),
          child: const Text('Go'),
        ),
      ),
    );
  }
}
