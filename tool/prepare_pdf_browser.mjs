// Flutter's test server serves test/, not web/. Stage only public renderer
// files in an ignored directory, using the same runtime as the shipped app.
import { cpSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
const root = new URL('../', import.meta.url);
const target = new URL('test/.dart_tool/pdf_runtime/', root);
mkdirSync(target, { recursive: true });
cpSync(fileURLToPath(new URL('web/vendor', root)), fileURLToPath(new URL('vendor', target)), { recursive: true });
cpSync(fileURLToPath(new URL('web/pdfjs_runtime.js', root)), fileURLToPath(new URL('pdfjs_runtime.js', target)));
cpSync(fileURLToPath(new URL('web/pdfjs_compat.js', root)), fileURLToPath(new URL('pdfjs_compat.js', target)));
console.log('Public PDF renderer staged for Flutter browser tests');
