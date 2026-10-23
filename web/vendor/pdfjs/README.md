# PDF.js runtime for the existing pdfx renderer

Mozilla pdfjs-dist 6.4.299, official npm distribution:
https://registry.npmjs.org/pdfjs-dist/-/pdfjs-dist-6.4.299.tgz

Registry tarball integrity (SHA-512, verified before extraction):
`AVl138zALtfaAPvADulE0PZThbYzCBS79nL4pOSL/6Sm/4AH5A21BD9VHt97OlCuzJuCpmeZtAtkinisF4Vb1g==`

Unmodified build/pdf.min.mjs and build/pdf.worker.min.mjs (named `.js` here
for the deployed server's JavaScript MIME mapping), cmaps,
standard_fonts, wasm and LICENSE are copied here. Apache-2.0; retain LICENSE
and bundled font notices. Source: https://github.com/mozilla/pdf.js .
Update renderer and worker together from one verified distribution.

This supplies the runtime already required by pdfx. Same-origin packaging
keeps the existing CSP and avoids sending protected documents to a third-party
renderer/CDN. No new service or package/lockfile dependency is introduced.
