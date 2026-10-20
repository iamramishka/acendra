import 'package:web/web.dart' as web;

const _key = 'acendra_language';

/// Returns the saved language code ('en' | 'si') or null.
/// localStorage may be unavailable (private mode), so failures are swallowed.
String? loadStoredLanguage() {
  try {
    return web.window.localStorage.getItem(_key);
  } catch (_) {
    return null;
  }
}

void saveStoredLanguage(String value) {
  try {
    web.window.localStorage.setItem(_key, value);
  } catch (_) {}
}
