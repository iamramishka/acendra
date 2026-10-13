# CSA-148 bounded local PDF watermark generator

Status: IN_REVIEW. This implementation does not operate a hosted service or
queue, register derivatives, or approve deployment. Invoke `generate` only
inside a trusted backend worker using backend-resolved display name, canonical
opaque UUID license ID, and SHA256 of the immutable validated source asset.
Never accept these values as client assertions. Generate into private storage
with separate actor/asset/policy identities; current entitlement checks still
apply on every delivery request. A failed generation must never return source
bytes. No personal email, phone or NIC appears in the watermark.

The mark is real merged page content on every page. Original selectable text,
media/crop boxes and rotation are retained for supported untagged documents.
The watermark follows original page rotation. This deters redistribution; it
cannot prevent screenshots, copying, or deliberate watermark removal. Disclose
personalized watermarking to students before delivery.

Reject encrypted/unparseable documents, integrity mismatch, embedded files,
actions, JavaScript, forms/signatures, tagged structures, non-default UserUnit,
unsupported geometry, controls, and font glyphs missing from the configured font. These explicit
limitations prevent silent loss of accessibility structures or font glyphs.
Tagged accessibility preservation and pedagogical visual QA of
actual course documents require a separately approved extension. Rejecting
existing interactive links is intentional until a safe URI policy is approved.

Selected worker runtime: existing trusted Python backend tooling on non-root
Linux. `generate_isolated(source, kwargs)` supervises each job with 60-second
wall/CPU timeout, 512MiB address-space ceiling, 50MiB file ceiling, no core
dumps, descriptor/process limits, and private temporary output cleanup. It
refuses Windows, non-Linux POSIX and root execution before document parsing.
Input/output ceilings are 50MiB and page ceiling is 500; all remain positive
and can be lowered. A network-denied/container filesystem sandbox remains a
deployment requirement; process limits do not restrict filesystem authority.
Linux enforcement must be verified in that deployment; Windows synthetic tests
verify direct generation and fail-closed supervisor platform behavior only.
Derivatives expire after 30 days under the root-owned cleanup/registration
policy; temporary supervisor output is deleted immediately after job return.
Trusted queue orchestration, artifact registration, sandbox deployment and
CSA139 private-storage integration remain release gates.

Dependency justification: pypdf (BSD-3-Clause) merges existing page content
without rasterization; reportlab (BSD) creates the textual overlay. Versions
are pinned to the bundled runtime used in this verification. No network,
external service, paid dependency, or Flutter package is introduced. Packaging,
license/security maintenance review and bounded worker runtime approval remain
integration responsibilities.

Run tests: `python -m unittest discover -s tool/pdf_watermark -v`.
Fixtures are generated in memory using synthetic identities; no binary PDFs
or real student information are committed.

Unicode locale support uses a server-configured absolute TTF/TTC font path
and ReportLab shaping through pinned uharfbuzz 0.53.3 (MIT). HarfBuzz supplies
contextual Sinhala/Tamil glyph positioning that cmap coverage alone cannot
provide. Every name glyph must exist in the font cmap; missing glyphs and
missing shaping runtime fail closed. Windows Nirmala TTC was used only for
local synthetic verification and is not redistributed. Linux deployment must
supply a licensed font covering Latin/Sinhala/Tamil and set the trusted path;
no request parameter or queue client may select the font. Shaped watermark
Unicode extraction can differ from the source Unicode sequence because of
ligatures; the opaque license ID and original selectable lesson text persist.

Official implementation references:
https://hg.reportlab.com/hg-public/reportlab/annotate/7635eaecb27d/src/reportlab/pdfbase/ttfonts.py
https://uharfbuzz.readthedocs.io/reference.html
For locale tests set CSA148_TEST_FONT to the trusted locale font. Install
requirements into the isolated worker environment first; tests skip only the
locale fixture when no configured font exists. Production must fail closed.
