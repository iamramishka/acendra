import 'package:web/web.dart' as web;

String? readPdfPreference(String key) => web.window.localStorage.getItem(key);
void writePdfPreference(String key, String value) =>
    web.window.localStorage.setItem(key, value);
