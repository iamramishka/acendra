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
unsupported geometry, and names outside printable ASCII. These explicit
limitations prevent silent loss of accessibility structures or font glyphs.
Unicode fonts, tagged accessibility preservation, and pedagogical visual QA of
actual course documents require a separately approved extension. Rejecting
existing interactive links is intentional until a safe URI policy is approved.

Positive configurable input/page/output/object limits fail closed. PDF parsing
and decompression can allocate before these logical limits are reached; run in
an OS-isolated process with enforced memory, CPU and wall-clock limits before
production. These deployment limits, trusted queue orchestration, artifact
registration and CSA139 private-storage integration remain release gates.

Dependency justification: pypdf (BSD-3-Clause) merges existing page content
without rasterization; reportlab (BSD) creates the textual overlay. Versions
are pinned to the bundled runtime used in this verification. No network,
external service, paid dependency, or Flutter package is introduced. Packaging,
license/security maintenance review and bounded worker runtime approval remain
integration responsibilities.

Run tests: `python -m unittest discover -s tool/pdf_watermark -v`.
Fixtures are generated in memory using synthetic identities; no binary PDFs
or real student information are committed.
