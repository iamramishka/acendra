import 'dart:convert';
import 'pdf_preferences.dart'
    if (dart.library.js_interop) 'pdf_preferences_web.dart'
    as preferences;

/// Only page numbers are stored, scoped to the signed-in student and lesson.
/// Legacy lesson-only keys are deliberately not imported across accounts.
class PdfReadingStore {
  PdfReadingStore({
    required String userId,
    required String lessonId,
    String? Function(String)? read,
    void Function(String, String)? write,
  }) : _key =
           'acendra_pdf_v2_${Uri.encodeComponent(userId)}_${Uri.encodeComponent(lessonId)}',
       _read = read ?? preferences.readPdfPreference,
       _write = write ?? preferences.writePdfPreference;

  final String _key;
  final String? Function(String) _read;
  final void Function(String, String) _write;

  String? _get(String suffix) {
    try {
      return _read('$_key$suffix');
    } catch (_) {
      return null;
    }
  }

  void _set(String suffix, String value) {
    try {
      _write('$_key$suffix', value);
    } catch (_) {
      // Private browsing/quota failures must not prevent reading.
    }
  }

  int loadPage(int totalPages) {
    final page = int.tryParse(_get('_page') ?? '');
    return page != null && page >= 1 && page <= totalPages ? page : 1;
  }

  void savePage(int page) {
    if (page >= 1 && page <= 500) _set('_page', '$page');
  }

  List<int> loadBookmarks(int totalPages) {
    try {
      final raw = _get('_bookmarks');
      if (raw == null || raw.length > 2048) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List || decoded.length > 100) return [];
      return decoded
          .whereType<int>()
          .where((p) => p >= 1 && p <= totalPages)
          .toSet()
          .toList()
        ..sort();
    } catch (_) {
      return [];
    }
  }

  void saveBookmarks(List<int> pages) {
    _set(
      '_bookmarks',
      jsonEncode(
        pages.where((p) => p >= 1 && p <= 500).toSet().take(100).toList()
          ..sort(),
      ),
    );
  }
}
