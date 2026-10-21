# CSA-271 — COM-020 protected PDF reader

Owner: CODEX. Status: IN_REVIEW. Priority: P1.
Issue: https://github.com/iamramishka/acendra/issues/205
Branch: feat/csa-271-pdf-reader. Base: dev e4ab889.
Worktree: C:/Users/ramis/.codex/worktrees/csa271-pdf-reader/acendra.
Approval authority: project owner and required maintainer review.

The owner requested implementation, prototype comparison, browser verification,
a PR and integration into dev on 2026-10-21. Follow-up to merged #104 and the
existing contents component; no production release or hosted activation implied.

Writable scope: lib/features/pdf_reader/** and associated tests;
supabase/functions/pdf-content/** and its tests; tool/pdf_watermark/** and
bounded worker/delivery tests; this record; narrow COM-020/D-3 reconciliation
in compare.md. Necessary extensions are recorded on issue #205: same-origin
PDF.js bootstrap/vendor assets, serialized migration 20261021000100, the PDF
entitlement SQL test and worker policy metadata/allowlist. No package/lockfile,
router, global theme, hosted secrets, billing, protections or workflow changes.

Open #201/#202/#204 and worktrees inspected before editing. #202 repeats the
contents component already on dev; this follow-up owns active reader wiring and
backward-compatible additions. The owner authorizes the narrow COM-020 update;
preserve other comparison rows and catalog work in #204. No active PDF owner
overlap identified; previous PDF issue #95 is closed and #104 merged.

Acceptance and verification:
- Preserve backend authorization on every request and derivative-only delivery.
- Preserve approved display-name/opaque-license watermark in actual PDF bytes;
  retain safe internal outlines and reject active/external actions.
- Disclose watermark only after the trusted descriptor confirms ready derivatives.
- Connect contents/bookmarks to the active learning reader; verify page/zoom,
  fit width and user-scoped reading-position restoration including page 1.
- Compare the recorded prototype layout; exact visual parity requires access to
  the reference and a working browser. Local browser control is disabled.
- Run real-byte Python regressions, Node proxy/worker tests, Dart repository,
  state/widget checks, automated Chrome attempt, analyzer/format and web build.

Operational gates from CSA-010 and CSA-140/141/148 remain: confined non-root Linux
worker, trusted licensed locale font, queue/retention, representative renderer
and accessibility acceptance. No raw original/signed-URL fallback. No production
activation without separately verified deployment and release approval.

Merge gate: required CI and review. Existing GitHub Actions account payment/
spending-limit failures are not permission to bypass protections.

## Implementation and compatibility

- Active path remains Learning workspace → ProtectedPdfLesson → authenticated
  descriptor/resource bytes → PdfLessonReader. No original/URL fallback.
- Server descriptor adds `watermark_applied`; disclosure needs strict boolean
  true plus successfully delivered derivative bytes. Older descriptors remain
  readable without disclosure. Existing repository `load()` callers keep their
  byte API; `loadDocument()` adds the trusted display evidence.
- The later owner D-3 answer in compare.md selects Acendra Product + name + ID.
  V2 uses the approved opaque licence ID, not an Auth UUID/email. The worker
  burns a translucent diagonal identity and footer into every page, preserving
  original text, boxes and safe local outline destinations. External/scripted/
  chained actions remain rejected. Unknown policies fail closed.
- Policy UUID 14000000-0000-4000-8000-000000000002 reserves new objects. The
  resolver change is otherwise identical to the existing service-only function.
  A ready v1 resource cannot satisfy v2. Old immutable metadata/objects are not
  rewritten. A supported v1 fixture produces byte-identical output to dev.
- Worker policy comes from its trusted immutable target path, ignoring extra
  policy fields. Supervisor metadata permits only the added policy identifier;
  process bounds remain unchanged.
- Contents/bookmarks, page navigation, 100–300% zoom and actual fit width now
  belong to the active reader. Saved pages/bookmarks are scoped to student and
  lesson, bounded and tolerant of unavailable storage. Saving page 1 replaces
  older progress. The obsolete lesson-only store and global false flag were
  removed. An owned open contents route is removed when its reader disappears,
  including when identity changes before the sheet's first frame.
- Same-origin PDF.js 6.4.299 supplies the runtime previously missing from web.
  Official npm tarball SHA-512 verified; 201 distribution assets have SHA-256
  regression coverage and retained notices. JavaScript filenames use `.js` for
  deployment MIME compatibility. No CSP relaxation or external PDF service.

## Fresh verification evidence

- `flutter test --no-pub --concurrency 1 test/features/pdf_reader --reporter expanded`:
  **128 passed**. Includes chapter/bookmark jumps, zoom/reset matrix, reopening
  position/page 1, student/lesson separation, open-sheet disposal, dark theme,
  and 320/390/768/1440 px at 1×/2× text. Native rasterization is a test boundary;
  these results do not establish browser rendering.
- Pinned `.dart_tool/pdf-worker-venv/Scripts/python.exe -m unittest discover -s tool/pdf_watermark -p test_watermark.py`:
  **15 passed, one non-root Linux-only skip**. CI's existing worker check now
  exercises v1 and v2 through the real Linux supervisor. Locale font packaging
  and deployed filesystem/network confinement remain operational gates.
- `node --test supabase/functions/pdf-content/*.test.mjs supabase/functions/_shared/pdf/*.test.mjs tool/pdf_worker.test.mjs tool/pdf_worker_runtime.test.mjs tool/pdf_assets.test.mjs`:
  **111 passed**. `node --test tool/csa152_pdf_requests.test.mjs`: **34 passed**.
  The older preparing-descriptor expectation was updated to assert the new
  explicit false evidence; authorization/private-field assertions remain.
- PostgreSQL 17 on loopback 55471: **43 ordered migrations applied** to an empty
  disposable database. Both CSA-139 private-storage and CSA-140 entitlement /
  v1-v2 lifecycle SQL suites passed. Synthetic Auth/Storage bootstrap initially
  lacked foldername and real grants/RLS; only the disposable shim was corrected.
  This is not hosted Supabase/Storage acceptance. The database server was stopped.
- Four-page synthetic v2 PDF fixture generated with the production function,
  rendered with bundled Poppler and all pages visually inspected. Marks fit
  the page, original text remains readable/selectable, local chapters survive.
- Scoped analyzer passed with a process-local `DART_DATA_HOME` after the default
  Windows performance-socket cleanup caused SDK shutdown errors. No SDK/global
  configuration changed. Full final analyzer/build outcomes recorded below.
- Changed Dart files are formatted. Full formatting reports **nine pre-existing
  unrelated files** on dev (finance/payment summary, auth/reset forms, dashboard
  hero, continue-learning card, profile provider, settings, learning test).
  They overlap other integration work and were not silently reformatted.

## Browser/prototype result and release gates

Two automated Chrome attempts compiled but stalled before the suite loaded;
**zero browser assertions or browser screenshots passed**. The second attempt
ran serially with task-local Dart state. Stopped only the owned test trees.
An earlier concurrent VM attempt exhausted Windows resources; the fresh serial
128-test run passed. The added browser test uses actual bundled PDF.js and
the generated derivative, with synthetic Auth transport only, and is discovered
through the existing Linux `tool:test` job without workflow changes.

CUA inventory reports local browser use disabled in Work settings. The original
reference https://claude.ai/artifact/NDAfFDE3QHzxMNTRXqf4RJ is inaccessible from
the available reader. Comparison used the recorded COM-020 layout and D-3 owner
answer; exact pixel parity and actual reader accessibility remain unverified.

Before adopting the new policy in an approved environment, stop old workers,
install this policy-aware worker, apply the v2 migration and complete approved
font/queue/isolation/retention/renderer/accessibility acceptance. Only then opt
into worker/delivery activation. Hosted delivery remains disabled by default.

PR #202 repeats an older contents component already present on dev. Future
integration must retain CSA-271's active wiring, compatible optional parameters
and owned modal cleanup. Other comparison tasks (including catalog #204) are
preserved. Dev merge remains contingent on actual CI and required review.
