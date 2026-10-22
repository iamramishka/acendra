# Protected reader fixture

`csa271_watermarked.pdf` contains four synthetic pages, three chapter entries
and the server-burned `Acendra Product - Licensed to Demo Student` v2 mark with a synthetic opaque
license ID. No real student information or protected course material is used.

Regenerate with the pinned worker environment:
`python tool/pdf_watermark/make_reader_fixture.py test/fixtures/csa271_watermarked.pdf`.
The generator uses the production watermark function; do not replace the fixture
with an overlay, raw original or downloaded third-party PDF.

Browser test: `node tool/prepare_pdf_browser.mjs`, then
`flutter test --no-pub --platform chrome --timeout 60s test/browser/protected_pdf_reader.browser.dart`.
The stage command copies only public renderer assets into ignored
`test/.dart_tool/pdf_runtime/`. The normal application has no test-data route.

For interactive browser comparison, build the separate synthetic preview:

```powershell
flutter build web --target test/browser/protected_pdf_preview.dart --release --no-pub --no-web-resources-cdn --output build/pdf-preview
New-Item -ItemType Directory -Force build/pdf-preview/fixtures
Copy-Item test/fixtures/csa271_watermarked.pdf build/pdf-preview/fixtures/
python -m http.server 9271 --bind 127.0.0.1 --directory build/pdf-preview
```

Open `http://127.0.0.1:9271`. The preview uses the production reader, theme,
PDF.js, outline parser and browser reading store. Its clearly labelled student
switch tests local progress separation; Reopen and page reload test restoration.
The same synthetic PDF is used for both students. It neither authenticates to
Supabase nor verifies hosted entitlement/delivery, and it is never a production
application route. Theme and student controls belong to the test harness only.
