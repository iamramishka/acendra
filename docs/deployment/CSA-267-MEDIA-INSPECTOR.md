# CSA-267 course artwork and media inspection

Owner CODEX; issue #193; branch `fix/csa-267-course-media`; base `dev`.
Status: IN_REVIEW. This is reviewable implementation and deployment preparation,
not a claim of live activation or owner acceptance of the proposed resource policy.

## Implemented path

For an existing authorized course, the editor selects JPG/PNG, reserves an immutable
private Storage object, uploads through its non-upsert signed token, and finalizes.
A lesson PDF control uses the same path for an existing PDF lesson. New course/
lesson creation remains subject to the existing separate authoring implementation.
The displayed success requires the backend's validated result, never upload success
alone. Session changes interrupt subsequent client steps.

Finalization downloads actual stored bytes, verifies size/type/digest, and invokes
the authenticated inspection service. Existing trusted SQL rechecks current account,
session, content role/course assignment, super-admin MFA, and lesson identity at commit.
No payment, enrollment, publication, or paid-content delivery authority is added.

A new private association is selected in the same transaction as thumbnail validation
and its immutable audit. Attachment failure rolls everything back. An older reservation
cannot supersede a newer selected reservation, and replaying an already validated old
asset cannot restore it. Only new validations under `csa267-media-v1` attach; existing
private metadata and opaque `thumbnail_path` values are not retroactively blessed.

`GET /functions/v1/course-artwork?course_id=<UUID>` proxies only the current validated
thumbnail for a published course. A verified Bearer session may preview an assigned
draft through the same endpoint. The public catalog/dashboard/enrolled-course cards
use this course identity URL; neither private Storage paths nor signing tokens enter
catalog records. The resolver checks asset/audit/policy/private bucket, the handler
bounds bytes and verifies SHA256, and a second resolve rejects changes during Storage
IO. No-store and nosniff headers apply. Already downloaded or client-cached image
bytes cannot be recalled; revocation applies to subsequent server requests.

## Proposed versioned policy

Admin draft cards fetch through the authenticated Functions SDK with
`Accept: application/octet-stream`. Only verified Bearer requests can negotiate
that binary response; public cover requests retain their validated image MIME.
The SDK path avoids unauthenticated browser image requests and its image-to-text
decoding behavior. Draft UI bytes are discarded on logout or account reload;
already delivered client bytes remain subject to the disclosure above.

The existing approved hard caps remain PDF 50 MiB and thumbnail JPG/PNG 5 MiB.
This PR proposes lesson-image 5 MiB, 16 million image pixels, one image frame,
PNG text chunk 64 KiB/aggregate 256 KiB; PDF 1,000 pages, 20,000 indirect objects,
200,000 traversal nodes, depth 64 and 128 MiB decoded streams. Encrypted PDFs,
scripts/actions/forms/attachments and malformed/trailing image data are rejected.
Pillow verify is followed by full pixel decoding; header signatures alone never
produce readiness. PDF traversal includes unreferenced/compressed objects.

Each parser executes in a Linux child with 512 MiB address-space, 8 CPU seconds,
10 wall seconds, no writable file output, 32 file descriptors, and no inherited
service credentials. A failed/crashed/killed parser cannot return a successful
verdict. The HTTP process serializes requests. The scanner requires an explicit
clean ClamAV INSTREAM result and signatures no older than 72 hours; unavailable,
infected, stale, malformed, oversized, timeout and error results fail closed.
Scanner work has a separate bounded deadline; Edge HTTP waiting is capped at 25s.

Pillow 12.3.0 is a new isolated service dependency for actual image decoding
(Pillow license, permissive MIT-CMU). Existing pypdf 6.20.1 is reused for PDF
inspection. Neither changes Flutter dependencies. Keep parsers, scanner, signatures
and container base patched; dependency pins are not a permanent security guarantee.
See [Pillow parsing](https://pillow.readthedocs.io/en/stable/reference/Image.html)
and [ClamAV protocol](https://docs.clamav.net/manual/Usage/ClamdProtocol.html).

## Deployment contract and release gates

1. Review/accept the versioned policy and new migration; replay the whole migration
   chain and database/Storage tests on disposable Supabase first.
   Apply both `20261019000200_csa267_course_artwork.sql` and the additive
   `20261019000300_csa267_artwork_trigger_guard.sql` before releasing updated
   functions or accepting media uploads. The second migration preserves unrelated
   validation-audit producers that have no upload reservation. Coordinate the
   migration window with those producers; do not run with only the first applied.
2. Build `tool/media_inspector/Dockerfile` with the directory as build context.
   Run on Linux as its unprivileged user, read-only filesystem, capped CPU/memory/
   processes, private temporary filesystem and internal network. Suggested parser
   service container limits: 768 MiB RAM, one CPU, 32 processes, 8 MiB tmpfs.
   Bound request size to 50 MiB, queued connections, header/body time and total time
   at the TLS reverse proxy; do not expose plain HTTP on a public interface.
3. Use a private current ClamAV daemon with the supplied `clamd.conf`; do not
   expose its unauthenticated socket publicly. Provision and regularly refresh the
   real full signature database. Match scanner resource limits and container capacity.
   In particular `AlertExceedsMax yes` is required: scan-limit truncation must never
   be represented as clean. Verify the daemon actually loaded this configuration.
4. Set service-only `MEDIA_INSPECTOR_KEY` (random >=32 characters),
   `CLAMD_HOST` and optional `CLAMD_PORT`. Never pass these to Flutter.
5. Deploy inspection behind a private authenticated HTTPS URL. In both upload
   functions set `ACENDRA_MEDIA_INSPECTOR_URL`, matching
   `ACENDRA_MEDIA_INSPECTOR_KEY`, `ACENDRA_MEDIA_POLICY=csa267-media-v1`,
   existing Supabase service/public configuration and exact
   `ACENDRA_ADMIN_ALLOWED_ORIGINS`. Missing/invalid config remains unavailable;
   there is no clean-scan fallback or scanner bypass.
6. Deploy `course-artwork` with gateway JWT verification disabled as declared
   in config. The handler owns verification for draft previews; public published
   covers intentionally require no session. Preserve private Storage buckets and
   absence of browser read/list/overwrite policies.
7. Verify real signed-token transport, real current full-database scanning
   (clean, EICAR, encrypted, parser bomb and scan-limit rejection), authenticated
   roles/MFA/assignment revocation, actual catalog rendering, and replacement/
   unpublication in staging before activation. No service was provisioned, no
   hosted migration or secret was applied, and no production deployment was made
   by this task.

The tests emulate scanner protocol at its genuine network seam; they do not certify
a deployed scanner or full signature coverage. The Linux CI check executes real
limited parser children. Actual managed Storage and deployment acceptance remain
separate evidence. Mux video and protected lesson-image viewing remain in their
existing workflows; this public endpoint never serves either.

Rollback: disable upload inspector configuration and remove the artwork function
deployment. Keep private objects/audit/association history; do not erase validated
financial or content history. The client falls back to the existing accessible cover
when artwork is unavailable.
