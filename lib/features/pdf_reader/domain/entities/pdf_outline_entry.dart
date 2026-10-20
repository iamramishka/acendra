/// One entry of a PDF's outline (table of contents).
class PdfOutlineEntry {
  const PdfOutlineEntry({
    required this.title,
    required this.page,
    this.level = 0,
  });

  final String title;

  /// 1-based target page.
  final int page;

  /// Nesting depth, 0 for top-level chapters.
  final int level;
}
