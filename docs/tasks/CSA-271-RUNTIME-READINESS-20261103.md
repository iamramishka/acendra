# COM-020 / CSA-271 runtime readiness, 2026-11-03

Owner: CODEX, continuing the existing assignment in [issue #205](https://github.com/iamramishka/acendra/issues/205).
Status: IN_REVIEW; activation is not approved or performed.
Branch: `fix/csa-271-runtime-readiness`.
Worktree: `C:/Users/ramis/.codex/worktrees/csa271-runtime-readiness/acendra`.
Reviewed base: `e55e9ed` (origin/dev at inspection).

## Scope and coordination

The owner requested runtime readiness, artifact/live comparison and repair, with
explicit approval before activation. On this date the owner clarified that the
frontend uses **Vercel only**. The historical EC2 host is therefore not a selected
worker target. Two SSH attempts to that historical address timed out; neither
changed it. No further EC2 discovery or installation is part of this continuation.

Issue #205, its historical ownership and merged PR #206, open issues/PRs and the
worktree inventory were inspected. This is a continuation, not a competing claim
on the original implementation. Writable scope for this evidence stage is this
record and a cross-reference in `docs/tasks/CSA-271-PDF-READER.md`. Other active
worktrees, shared task/design/configuration files and production state are excluded.
No source defect requiring a speculative reader rewrite was established.

Dependencies: approved CSA-010 delivery policy; CSA-139 private storage;
CSA-140/141 proxy and authorization; CSA-148 trusted worker; merged CSA-271 v2
policy and reader. Approval authority: project owner/designated maintainer.
Verification criteria: inspect live non-personal configuration, compare the
reference reader and deployed renderer assets, rerun relevant regressions, and
identify every remaining runtime/activation gate without claiming it passed.

## Fresh hosted evidence

Read-only Supabase management requests used the existing local configuration.
Only function source and configuration/privilege metadata were inspected; no
student profiles, entitlements, queue jobs or protected document bytes were read.
No credentials or downloaded function bundle are committed.

| Boundary | Observed result | Implication |
| --- | --- | --- |
| Vercel renderer | `pdfjs_runtime.js`, `pdfjs_compat.js`, `vendor/pdfjs/pdf.min.js`, `vendor/pdfjs/pdf.worker.min.js` each returned HTTP 200 JavaScript and matched the corresponding reviewed file's SHA-256 | Browser renderer assets are current; a missing PDF.js bundle is not the present blocker |
| Hosted `pdf-content` | Downloaded ESZIP is 15,664 bytes, SHA-256 `9d634e5a600152746ff4ad475874fb547990d655827f07eb85f160f7632c67a3`; source explicitly uses `enabled: false`; contains neither `watermark_applied` nor `deliveryEnabled` | Hosted proxy is older than merged source and delivery remains disabled |
| `course-pdfs` | Private; 52,428,800-byte limit; only `application/pdf` | Bucket configuration matches the approved baseline; this alone does not prove object-level access denial |
| Resolver | Hosted function selects v2 policy `14000000-0000-4000-8000-000000000002`; anon/authenticated cannot execute; service role can | No v2 policy migration needs to be guessed or replayed blindly |
| Queue RPCs | Claim and completion functions deny anon/authenticated execution and allow service role | Browser callers cannot directly operate these RPCs |
| Derivative table | RLS enabled on `app_private.pdf_derivatives` | RLS flag confirmed; full hosted cross-user/Storage/revocation behavior still needs an authorized acceptance run |
| Anonymous proxy requests | Synthetic lesson UUID, GET and HEAD with public apikey and Vercel Origin returned HTTP 403 JSON `ACCESS_DENIED`, no PDF bytes | Fresh denial smoke test only; disabled delivery cannot establish all active authorization paths |
| Worker/locale font | No current worker target identified; owner uses Vercel for frontend | Non-root Linux supervision, filesystem/network confinement, licensed deployed font and durable scheduling are unverified |
| Retention | PDF function-name inventory contains resolver/claim/completion and storage guards, no PDF-named purge function | No purge implementation/schedule was established; external cleanup could exist, so absence is not proven |

The static Vercel renderer and the trusted Python watermark worker are different
components. The current worker launches Python from Node and explicitly refuses
root and non-Linux execution. A static frontend deployment does not install that
backend. Vercel also offers function runtimes; adapting this worker to one would
require a separately reviewed deployment design and evidence for its confinement,
scheduling, process/resource limits and private storage access. No claim is made
that Vercel categorically cannot support PDF processing.

## Artifact comparison

Fresh in-app browser inspection opened the supplied
[Acedra Mobile Prototype](https://claude.ai/artifact/NDAfFDE3QHzxMNTRXqf4RJ),
used its sample Sign In and opened Recently Accessed / Responsive Layouts Guide.
The PDF view has Back/title, Contents, Bookmark, an inset white page on a gray
canvas, personal diagonal watermark, disclosure and grouped page/zoom/fit controls.
The reference is a simulated document, not evidence of secure byte delivery.

The live [Vercel app](https://acendra.vercel.app) loaded at `/#/login` and its
accessibility tree exposed the real sign-in controls. No enrolled student browser
session was available in this fresh browser context. Thus a live protected PDF
was not opened or visually compared. Existing CSA-271 reader screenshots and
earlier synthetic browser results remain historical evidence, not fresh hosted
acceptance. The merged production reader and bundled renderer already implement
the reference control structure; enabling a client overlay would not repair the
missing trusted runtime or old hosted proxy.

## Verification (initial evidence stage)

- `node --test tool/pdf_worker.test.mjs tool/pdf_worker_runtime.test.mjs tool/pdfjs_assets.test.mjs tool/pdfjs_compat.test.mjs tool/csa152_pdf_requests.test.mjs supabase/functions/_shared/pdf/*.test.mjs supabase/functions/pdf-content/*.test.mjs`: **147 passed**, zero failed/skipped, exit 0.
- Existing pinned worker Python environment, `CSA148_TEST_FONT=C:/Windows/Fonts/Nirmala.ttc`, `-m unittest discover -s tool/pdf_watermark -p test_watermark.py -v`: **16 run, 15 passed, one Linux-only test skipped**, exit 0. Includes actual v2 page-content marks, immutable output, internal outlines, geometry, Unicode shaping and unsafe input rejection. Windows Nirmala is local verification only; no deployment redistribution/license approval is implied.
- `flutter pub get --offline`: passed. No dependency/lockfile change.
- `flutter test --no-pub --concurrency 1 test/features/pdf_reader --reporter compact`: exit 1 after 111 reported successes. The Dart VM printed `zone.cc:96: error: Out of memory` while compiling `PipelineOwner.flushSemantics`; later suites did not complete. Windows reported about 1 GiB free virtual memory during follow-up. This is an incomplete run, not a full pass or evidence of a reader assertion defect.
- Focused `flutter test --no-pub --concurrency 1 test/features/pdf_reader/pdf_lesson_reader_test.dart --reporter expanded`: started loading but terminated with process exit `-1073741819` (Windows access violation), before reporting assertions. No fresh Flutter pass is claimed. Chronos on-demand inspection found no Codex process-health fault; this does not negate the observed system memory pressure or certify the failed Flutter execution. No other task/application was stopped and no persistent monitor was created.
- `git diff --check`: passed. Final tracked scope is this evidence record plus the original reader task's follow-up link; no production code, dependency, policy or configuration changes.

An exact source-only handoff archive was prepared locally at
`build/com020-readiness/pdf-runtime-reviewed-source.zip`, containing 12 reviewed
worker/proxy files and a per-file SHA-256 manifest for full source revision
`e55e9ed` (full revision in the manifest). Archive SHA-256:
`158f8e0e91407559cb80bae083db16e1cf079e101d9afb90f1c8e5ce584d56e0`.
Reopening the archive verified every entry against that manifest. No credentials,
environment files, font, student data or generated derivative is included. It is
source preparation, not a runnable deployment or runtime-readiness certificate.

## Concrete deployment proposal awaiting target selection

Keep the existing Vercel frontend and Supabase authorization/private Storage.
Deploy the existing trusted worker only after selecting approved compute; do not
purchase a service, broaden access or change architecture by assumption.

1. Select the worker host/platform, operator and budget. For the unchanged worker,
   demonstrate supported non-root Linux execution. A Vercel-native adaptation is
   an alternative design requiring explicit review, not an automatic substitution.
2. Package the reviewed Node runtime, `tool/pdf_worker.mjs`,
   `tool/pdf_worker_runtime.mjs`, Python worker files and pinned requirements.
   Record immutable source/dependency/font digests and licensing. Keep v1 policy
   compatibility and v2 opaque-license identity; stop any old worker before v2 work.
3. Confine parsing/transformation separately from the credentialed queue adapter:
   no network, no service key/inherited secrets and only necessary read-only
   runtime/font files plus private bounded temporary output. Verify that boundary
   on the target; process resource limits alone do not establish confinement.
4. Install a licensed Latin/Sinhala/Tamil font and exercise actual shaped names.
   Verify 50 MiB input/output, 500-page, 512 MiB address-space and 60-second
   CPU/wall ceilings, timeout cleanup, bounded concurrency and private logs.
5. Configure trusted queue claim/completion, private immutable upload, restart and
   lease recovery; implement and verify the approved 30-day derivative/object and
   metadata purge together. No browser-callable worker endpoint or original fallback.
6. Deploy matching reviewed `pdf-content` plus its dependencies, keeping
   `PDF_DELIVERY_ENABLED` absent or false. Verify source/configuration after deploy.
   This deployment is a proposed action, not already authorized or executed.
7. Exercise representative authorized fixtures in an approved test environment:
   A/B identity, unsafe/large/rotated/dense content, failed jobs, immutable retries,
   direct Storage/sign/public URL denial, descriptor/GET/HEAD/range, expired session,
   cross-user/wrong-course, revocation and surviving independent entitlement.
   Record actual generated bytes, resource use and accessible alternatives.
8. Present the exact runtime release, proxy revision, environment and evidence
   for explicit activation approval. Only then set `PDF_DELIVERY_ENABLED=true`
   and verify the actual enrolled-student reader and returned marked bytes.
   Rollback disables delivery and stops claims; it must not expose originals.

No activation approval is requested yet because there is no concrete selected
worker deployment to approve. No production function/configuration, storage,
queue, entitlement, database, scheduler, hosting subscription or release setting
was modified. Delivered-PDF inspection remains dependent on these gates.

## Owner clarification and Vercel-only proposal

The owner subsequently confirmed: **no Linux host is available**. Do not ask for
EC2 access again or treat a separate server as an existing dependency. This section
proposes a managed runtime adaptation; it does not approve that architecture or
enable any hosted service.

### Candidate: Vercel Sandbox, controlled by a Vercel Function

Read-only Vercel API inspection found the existing `acendra` project and an owning
team with billing plan `hobby`. No token, team ID, account identity, environment
value or project configuration was printed or saved in this report. Sandbox
feature availability, remaining usage and account suitability for production have
not been verified by launching a sandbox.

Current official documentation describes isolated Linux microVMs, a non-root
execution user in the legacy images and configurable egress denial. These are
promising capabilities, not execution evidence for this application's Python
supervisor. Current defaults also include persistent filesystem snapshots and
sudo-capable users. A secure implementation must override and verify those
defaults; simply running Python in a default sandbox is insufficient.

Proposed flow:

1. A private authenticated wakeup invokes a bounded Vercel controller Function.
   It claims existing Supabase queue work using the reviewed RPC/lease contract.
   The browser cannot select job identity, font, private path or watermark text.
2. The controller uses the existing digest/size validation and immutable
   registration seam. It alone holds Supabase credentials. A pinned
   `@vercel/sandbox` adapter replaces local Python spawning; this is a new scoped
   dependency requiring coordinated ownership, not a Flutter dependency.
3. Create one fresh sandbox per job with `persistent: false`,
   `networkPolicy: 'deny-all'`, no exposed ports, no persistent drives and no
   student-bearing snapshots. Use a reviewed immutable runtime image with the
   pinned Python libraries and a licensed locale font already installed. Any
   build snapshot/image contains code and fonts only, never documents or identity.
4. Upload only the validated source bytes and trusted identity through the
   authenticated SDK control channel. Do not send the service key, Vercel token,
   signed Storage URL or complete inherited environment into the microVM. PDFs
   do not travel through a browser-visible API body or download URL.
5. Run the existing supervisor as a dedicated non-root user with no sudo access,
   no privilege escalation and a restricted read-only runtime/font filesystem
   plus private temporary output. Test non-root identity, network/DNS denial,
   secret absence, process limits and filesystem boundaries on the actual
   selected image. Platform microVM isolation does not by itself prove these
   application-level restrictions.
6. Preserve the existing 60-second transformation limit, 512 MiB parser ceiling,
   50 MiB byte ceilings and 500-page limit. Start with global concurrency one and
   at most one job per wakeup. Bound the whole controller/sandbox lifecycle below
   the 180-second queue lease, including transfer/startup; select an exact
   deadline after measuring startup and SDK overhead on representative fixtures.
   Do not complete an expired lease or weaken size limits to fit a trial.
7. Read back bounded output through the SDK, verify it, upload immutable private
   bytes and complete the matching lease through the existing worker seam.
   Always terminate the job sandbox; verify that shutdown does not snapshot
   source or identity. Failed jobs never return originals.
8. Use an authenticated durable wakeup/recovery mechanism in the existing
   Supabase backend, subject to verification of available extensions and reviewed
   migration ownership. Vercel Hobby Cron runs at most daily and is not an
   adequate reader-generation polling mechanism. The exact Supabase wakeup,
   retry, deduplication, admission control and secret storage contract must be
   reviewed before this candidate is implementation-ready. Implement coordinated
   30-day private object/metadata cleanup separately from generation; document
   and test the allowed purge delay rather than inventing it.

### Cost and approval boundary

Official Sandbox pricing currently lists Hobby monthly allowances of 5 active
CPU-hours, 420 GB-hours memory, 5,000 creations and 20 GB transfer; creation pauses
when applicable included quotas are exhausted. These are provider limits, not a
verified remaining account balance or a throughput promise. Function and Supabase
usage also apply. No free-service upgrade, recurring charge or hosted prototype
has been started. Production suitability and usage controls must be checked before
relying on this plan.

The next proposed authorized scope is a **local, synthetic-only prototype and
tests** of this adapter and its contracts, plus a reviewed wakeup/cleanup design.
Do not create cloud sandboxes or send real course/student content during this
stage. Before any hosted trial, obtain approval for the target project, exact
bounded run count/usage and configuration changes. Production PDF activation
remains a later, separate decision after the operational gates pass.

This candidate avoids managing a separate Linux server. It is not yet proven to
satisfy CSA-010, so the existing disabled-delivery state is retained.

Official references inspected on 2026-11-03:

- [Sandbox overview](https://vercel.com/docs/sandbox)
- [SDK configuration, persistence, image, file and command operations](https://vercel.com/docs/sandbox/sdk-reference)
- [Sandbox firewall and deny-all behavior](https://vercel.com/docs/sandbox/concepts/firewall)
- [Runtime users and sudo behavior](https://vercel.com/docs/sandbox/concepts/runtimes)
- [Sandbox pricing and quotas](https://vercel.com/docs/sandbox/pricing)
- [Vercel Cron Hobby scheduling limits](https://vercel.com/docs/cron-jobs/usage-and-pricing)

## Approved prototype continuation

The owner's subsequent **continue** authorizes the proposed Vercel Sandbox
adaptation and local synthetic prototype/tests. CODEX continues on the same
isolated branch. Scope extends to new `infra/pdf-sandbox/**`, focused
`tool/pdf_sandbox*.test.mjs`, the existing Node worker runtime's narrow adapter
injection seam and its regressions, plus this record. The SDK gets its own
private package/lockfile; root dependencies, Flutter files, shared migrations,
production configuration and other task worktrees remain excluded.

Open PRs were rechecked: #259/#257/#256/#255/#252/#249/#202/#201 do not own this
new adapter/image scope. The existing #205 owner remains CODEX. Tests must prove
default-off operation, bounded/credential-free isolated generation, immutable
registration, generic errors, cleanup on every exit and authenticated control
before queue access. No hosted Sandbox creation, production document transfer,
new scheduler, secret grant or PDF activation is authorized by this local stage.

### Implemented prototype and final local evidence

Implemented the private controller/generator under `infra/pdf-sandbox/`, with a
separate pinned SDK package/lockfile. Root Node/Flutter dependencies, app UI,
database migrations and hosted configuration are unchanged. The native worker's
only production-source change is a trusted generator injection; absent that
injection it retains the original Python/font configuration requirements.

The generator validates trusted identity and immutable image configuration,
rejects unsafe returned image/persistence/network metadata before document upload,
uses a non-root image launcher, bounds output and deadlines, and requires confirmed
stop without snapshot before the existing queue seam may upload/complete output.
The private body-free handler checks its secret before queue work and suppresses
private errors/IDs. Importing the runtime cannot start jobs; enabled default
operation throws until a reviewed distributed admission adapter is supplied.
Region selection must also be explicit before live operation.

SDK inspection found automatic retry of sandbox creation after transient errors.
The new transport allows one actual creation attempt per job, rejects alternate
API destinations and redirects, and treats ambiguous creation as failure. Any
unreturned VM gets no source bytes and has the fixed 90-second lifetime.

The image recipe uses a digest-pinned official Python 3.13 base, Linux amd64 wheel
hashes for all five Python distributions, rootless bubblewrap/setpriv, a bounded
file protocol and a checksum-pinned GNU FreeSerif font with redistribution notices.
A fresh allowlisted context builder copies eight source files, never `.env`,
student data or repository-root build contents. Debian OS package versions are
recorded at build time; no bit-reproducible apt snapshot resolution is claimed.

Dependency verification initially found one Zod advisory represented by four
affected dependency-tree entries, not four independent vulnerabilities. The local
package override pins Zod 4.6.7; the exact SDK's create/stop behavior is verified
with a synthetic HTTP provider. Final `npm audit --omit=dev` reports zero
advisories. OSV querybatch also reports zero known advisories for the five pinned
Python distributions. These scans do not certify an unbuilt OS image.

Final checks:

| Command / evidence | Actual result |
| --- | --- |
| Selected Node authorization/proxy/worker/renderer/request suites, plus `tool/pdf_sandbox.test.mjs` | 172 passed, zero failed/skipped; exit 0 |
| `npm test` in `infra/pdf-sandbox` | 26 passed, zero failed/skipped; exit 0. Includes 24 of the preceding tests plus two additional actual-SDK transport/validation tests; distinct Node total is 174, not 198 |
| Task-local Windows Python 3.12.14 environment, reviewed worker requirements, `CSA148_TEST_FONT` set to verified FreeSerif, watermark unittest suite | 16 run: 15 passed, one actual Linux-supervisor test skipped on Windows; exit 0. Target image Python 3.13 has not been executed |
| `python -m unittest discover -s infra/pdf-sandbox -p test_sandbox_job.py -v` | Four passed; exit 0. These test protocol/environment validation and unconfined rejection, not successful native isolation |
| `pip download --require-hashes --only-binary=:all:` with Linux amd64/CPython 3.13 target and `requirements-linux.lock` | All five wheel versions/hashes verified; exit 0 |
| Direct generator, fixed synthetic source, two synthetic Latin/Sinhala/Tamil identities | Four actual pages: own opaque ID/brand on each, other ID absent, original text and two outlines preserved; all four rendered and visually inspected for clipping/missing glyphs. This is local direct generation, not hosted delivery or microVM evidence |
| Scoped npm audit and OSV PyPI batch | Zero known advisories returned; exit 0 |
| `git diff --check` | Passed |

Source review also corrected the image preflight to allow only bubblewrap's
fixed `PWD=/work`; upstream source confirms bubblewrap sets this variable even
after the environment is cleared. No capability/network/filesystem check was
weakened to obtain a test result.

No new Flutter run was attempted for the Node/image-only change; the earlier
memory/access-violation runs remain incomplete. Docker's daemon was unavailable
and no WSL distributions were listed, so the image has not been built or executed.
No cloud SDK call used real credentials in the tests.

The guarded `verify_hosted.mjs` is prepared but was **not run against Vercel**. It
requires separate two-job approval, explicit project/team/region authentication,
and the exact compiled-in synthetic source digest. It cannot substitute an
arbitrary real document or touch the Supabase queue/Storage. Its proposed budget
is two sequential one-vCPU/2 GiB sandboxes, 90 seconds maximum each, with no
creation retries, public ports or persistent document snapshots.

The image needs a Linux builder before this trial. A read-only GitHub billing API
request returned HTTP 404 with a missing `user` scope indication; included CI
capacity could not be established. No OAuth scope was expanded, CI workflow
dispatched, branch pushed or cloud build started to bypass that limitation.

Status remains **IN_REVIEW**. Local adapter verification is complete. Durable
global admission/budget enforcement, private wakeup/recovery, coordinated 30-day
object/metadata purge, actual image/confinement/font/resource acceptance, matching
disabled proxy deployment and final activation/live student acceptance remain
required. See [runtime README](../../infra/pdf-sandbox/README.md) for the exact
contracts and commands. The instance-local busy flag is explicitly not a global
concurrency control, and no permissive production substitute was installed.

## Approved included-quota hosted stage

The owner approved one Linux CI image build and up to two synthetic Vercel jobs
**within verified included quota**. This does not approve charges, plan upgrades,
permission expansion, production content transfer or PDF activation.

Fresh checks identified an existing owner token separate from the CLI's active
collaborator identity. Using that existing token, without changing authentication
configuration/scopes, verified the owner has GitHub Pro and current November
Actions usage of 266 Linux minutes, approximately USD 1.596 of gross usage, fully
discounted. Current GitHub documentation expresses Pro included compute as USD 18;
one standard Linux build bounded to 20 minutes fits the observed allowance with
reserve for the in-progress workflow. Live enumeration of all 80 owned repositories
found 47 unexpired artifacts totaling 1,068,314 bytes. Reserving at most 300 MiB for
one image archive stays below the 1 GB included artifact allowance. These are
point-in-time checks; refresh before starting the single build.

CODEX temporarily owns the new `.github/workflows/csa271-pdf-image-trial.yml` for
this explicit one-build approval, plus image verification support under
`infra/pdf-sandbox/**` and this evidence. Other existing workflows are unchanged.
Open PRs were rechecked; none owns this new workflow. It triggers only on this
task branch and the exact approved build commit message, uses pinned existing
checkout/artifact actions, a standard Ubuntu runner, `contents: read`, no secrets,
20-minute timeout, a 300 MiB artifact ceiling and one-day retention. No PR is opened
at this stage because that would automatically start unrelated baseline workflows.

Vercel remains Hobby, but fresh official VCR documentation lists image storage at
USD 0.10/GB without a verified included allowance. Accordingly, image publication
and the two dependent Sandbox jobs are held under the owner's no-extra-charge
condition. No assumption that Hobby Sandbox compute allowances cover separately
priced VCR storage is permitted. The independent Linux build can proceed within
the verified GitHub allowance; no paid registry substitute or architecture change
is silently selected.

Sources: [GitHub included usage](https://docs.github.com/en/billing/reference/product-usage-included),
[VCR pricing](https://vercel.com/docs/container-registry/limits-and-pricing).
