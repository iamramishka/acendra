import 'package:web/web.dart' as web;

const _key = 'acendra_theme_mode';

/// Returns the saved theme name ('light' | 'dark' | 'system') or null.
/// localStorage may be unavailable (private mode), so failures are swallowed.
String? loadStoredThemeMode() {
  try {
    return web.window.localStorage.getItem(_key);
  } catch (_) {
    return null;
  }
}

void saveStoredThemeMode(String value) {
  try {
    web.window.localStorage.setItem(_key, value);
  } catch (_) {}
}
