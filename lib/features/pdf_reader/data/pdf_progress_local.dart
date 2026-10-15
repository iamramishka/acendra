import 'package:web/web.dart' as web;

/// Persists and restores a student's last-read PDF page in browser localStorage.
///
/// Keys are scoped per [lessonId] so different lessons have independent progress.
/// All storage calls are wrapped in try/catch — localStorage may be unavailable
/// (private/incognito mode, storage quota exceeded, etc.) and must never throw.
class PdfProgressLocal {
  const PdfProgressLocal._();

  static const _prefix = 'acendra_pdf_page_';

  /// Returns the saved page for [lessonId], or null if nothing is saved or the
  /// stored value is not a valid page number (>= 1).
  static int? loadPage(String lessonId) {
    try {
      final raw = web.window.localStorage.getItem('$_prefix$lessonId');
      if (raw == null) return null;
      final page = int.tryParse(raw);
      return (page != null && page >= 1) ? page : null;
    } catch (_) {
      return null;
    }
  }

  /// Saves [page] for [lessonId]. Page 1 is not persisted because it is the
  /// default — restoring it would be a no-op.
  static void savePage(String lessonId, int page) {
    if (page <= 1) return;
    try {
      web.window.localStorage.setItem('$_prefix$lessonId', '$page');
    } catch (_) {
      // Storage may be unavailable (private mode, quota, etc.) — fail silently.
    }
  }
}
