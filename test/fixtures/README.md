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
