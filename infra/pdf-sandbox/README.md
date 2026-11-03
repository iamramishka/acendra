# CSA-271 Vercel Sandbox adapter

Status: local prototype, IN_REVIEW. This does not install an HTTP route,
scheduler or production service. `createSandboxWorker` is disabled by default and
refuses enabled operation without the pending distributed admission integration.
The approved next stage is local synthetic verification; production PDF delivery
remains disabled.

## Trust boundaries

- Supabase identity resolution, digest checks, immutable uploads and lease
  completion remain in the existing `runPdfJob` seam. Its new trusted generator
  injection does not change the native worker default.
- The controller authenticates a body-free POST before queue work. It returns
  generic state/errors, never names, private paths, resource IDs or documents.
  Its local busy flag is not distributed concurrency control.
- Each generated document gets a fresh sandbox: immutable image digest,
  `persistent: false`, `networkPolicy: 'deny-all'`, no exposed ports, drives or
  inherited controller credentials. Unsafe returned metadata fails before upload.
- The SDK transport rejects redirects/alternate API origins and permits only one
  actual VM-create attempt per job, including when the SDK retries internally.
  An ambiguously created VM receives no source bytes and has a 90-second lifetime.
- The image runs the reviewed Python supervisor through `setpriv`/bubblewrap:
  non-root, no new privileges/capabilities, separate network/PID namespaces,
  read-only runtime/font/input and private writable temporary/output directories.
  Missing kernel support fails closed. These boundaries still need actual Linux
  and Vercel verification; unit tests do not prove the microVM configuration.
- Transformation runs at the existing 60-second/512 MiB/50 MiB/500-page ceilings.
  The controller reads output in a bounded stream, cancels stalled reads, and
  accepts bytes only after confirmed sandbox stop without a snapshot.

## Dependencies and font

This private package pins `@vercel/sandbox` 3.9.1 separately from root tooling and
Flutter. The scoped Zod 4.6.7 override fixes the SDK's old transitive version
affected by [GHSA-mrhx-c7xc-m3w5](https://github.com/advisories/GHSA-mrhx-c7xc-m3w5).
An actual-SDK test verifies create/stop serialization with patched Zod using a
synthetic in-memory HTTP provider; it never launches a cloud VM.

The official Python 3.13 slim Bookworm base is pinned by OCI index digest.
`requirements-linux.lock` pins all five Python distributions and Linux amd64
wheel hashes. Debian package versions are captured in `os-packages.txt` during
image build; package mirrors are not snapshot-pinned, so this is not a claim of
bit-reproducible OS package resolution. Scan and record the final image digest
before using it.

`install_font.py` verifies the GNU FreeFont 20120503 archive and FreeSerif TTF
SHA-256, and preserves COPYING, README and CREDITS in the image. The font covers
the tested Latin/Sinhala/Tamil names, and is licensed under GPL-3.0-or-later with
the font embedding exception. See [GNU licensing](https://www.gnu.org/software/freefont/license.html).
No Windows font is redistributed. Real document and locale readability acceptance
remains required.

## Local checks

From this directory:

```text
npm ci --ignore-scripts --no-fund
npm test
npm audit --omit=dev
```

From repository root, with an isolated Python environment containing the reviewed
worker requirements:

```text
python -m unittest discover -s infra/pdf-sandbox -p test_sandbox_job.py -v
node --test tool/pdf_sandbox.test.mjs tool/pdf_worker.test.mjs tool/pdf_worker_runtime.test.mjs
node infra/pdf-sandbox/prepare_context.mjs
```

The last command prints a **fresh allowlisted build directory** and hashes all
eight included source files. Build only from that directory, never from the
repository root, which may contain `.env` or private verification files:

```text
docker build --platform linux/amd64 -t acendra-pdf-local <printed-context-directory>
```

This is a local build command, not approval to push an image or run paid compute.
Docker/WSL were unavailable during this Windows verification. The image has not
been built or executed. Vercel custom images require a ready linux/amd64 image in
VCR; publishing that image is a later authorized step.

## Remaining integration contract

The existing Supabase job claim prevents two workers taking the same row. It
does not impose a global limit of one active sandbox across multiple controller
instances. A reviewed durable admission lease and budget counter must wrap
`createAdmittedSandboxWorker({ env, admit })` before deployment. The current
default throws rather than substituting a process-local lock.

Design the private Supabase wakeup/recovery and 30-day object/metadata purge in a
separately coordinated migration. Required behavior:

1. A scheduler/transactional outbox issues only a private authenticated, body-free
   wakeup. Public students never call queue RPCs or choose worker metadata.
2. A durable lease serializes all controllers; counters bound daily starts and
   fail closed when quota cannot be checked. Releasing admission cannot precede
   successful sandbox termination or the full fixed lifetime after uncertain stop.
3. Missing wakeups and controller crashes recover through the existing job lease;
   duplicate wakeups do not create additional VMs. An expired financial/content
   authorization is still rechecked by the proxy before every delivery.
4. Generation has enough lifecycle time left in its 180-second job lease, including
   source download, sandbox startup/transfer, output, immutable recovery and final
   RPC. Verify worst-case latency; do not extend the lease silently.
5. Cleanup removes expired private objects and corresponding derivative metadata
   together under the immutable-storage contract. Review concurrency, retries and
   the permitted purge delay; an arbitrary cron must not delete leased work.

These are unimplemented integration gates, not successful operational checks.
Hosted trials must first prove rootless bubblewrap support, runtime permissions,
resource limits, secret absence, no snapshots, both users' actual marked bytes,
timeout cleanup and readable locale fonts. Deploy the matching Supabase proxy
disabled, then obtain separate activation approval after all acceptance evidence.

## Prepared hosted trial (not executed)

After approval and publication of a reviewed linux/amd64 image, generate the
known source using `python infra/pdf-sandbox/make_trial_fixture.py`. The trial
script accepts only that compiled-in SHA-256, never an arbitrary course file.
`verify_hosted.mjs` requires `PDF_SANDBOX_TRIAL_APPROVED=two-synthetic-jobs`, an
immutable `PDF_SANDBOX_IMAGE`, selected `PDF_SANDBOX_REGION` and existing Vercel
project/team authentication. It performs exactly two sequential generator calls
with synthetic Latin and Sinhala/Tamil identities, and saves local output/digests
for actual page/outline/identity inspection. It does not access Supabase.

Proposed trial ceiling: two VM-create attempts, each one vCPU/2 GiB and at most
90 seconds per VM. Internal SDK retries cannot create a third VM. No public
ports, persistent document snapshots, real documents or production activation.
Verify remaining included quota before running; do not upgrade plans. This code
has not been run against Vercel. A local Docker build could not run because its
daemon is unavailable. An included-quota Linux CI build or another approved
builder is needed first; the GitHub billing API inspection returned HTTP 404
and reported missing `user` scope, so CI capacity is currently unverified. Do not
silently broaden OAuth scopes or start a billable build to bypass that gap.
