# CSA-275 — PR204 CI repair

Owner: CODEX. Issue: #215. Status: IN_PROGRESS. Target: dev / PR #204.
Authority: project owner requested fixing the failed CI blocking integration.
Base: a78a3006c4af89f262d7d7963d9b1965bdb52228.
Branch: fix/csa-275-pr204-ci.
Worktree: C:/Users/ramis/.codex/worktrees/pr204-ci-fix/acendra.

Scope: formatting only in the nine baseline Dart files identified by the hosted
formatter; reproduced SQL test/fixture failures; bounded verification tooling
where necessary; this evidence record. No migration, production configuration,
financial state-machine or feature behavior changes are authorized here.

Coordination: open issues 160/193/199/200/203/205/207/208/211, open PR file scopes
and worktrees were inspected. PR202 overlaps baseline formatting; PR210 owns
reset-password behavior. This repair normalizes whitespace only in those files,
preserves the feature changes, and leaves all original worktrees untouched.
SQL assertion maintenance is owned exclusively by this repair. The task and
temporary scope were recorded in issue #215 before edits.

Dependencies: existing approved avatar/notification contracts, PR204 catalog,
disposable test infrastructure. Approval authority: project owner/reviewer.
Existing required CI and review gates remain; changing the PR head can invalidate
the previous approval. Publishing will use an additive fast-forward update to
PR204 from this isolated branch, with no history rewrite or deployment.

Acceptance: reproduce failures; preserve negative permission, isolation,
financial-integrity and audit checks; pass formatting, analysis, Flutter and
database checks; publish current-head CI results and limitations honestly.

## Evidence

- Hosted Flutter attempt 2 failed at formatting: nine baseline files required
  normalization. Supabase attempt 2 failed in six SQL suites after migration
  replay. Tooling tests passed (869 passing, nine skipped), as did all eight
  verified-role boundary tests.
- `flutter analyze --no-pub`: passed, no issues (110.4 seconds).
- Local Docker CLI is installed but the daemon is unavailable; launching Docker
  Desktop did not make its endpoint available. A dedicated native PostgreSQL 17
  cluster at loopback port 59571 is used for diagnosis. Native Auth/Storage shims
  do not replace full Supabase runtime verification on hosted CI.

## Reproductions and repairs

- Original CSA059 fails on its obsolete six-field profile count. The replacement
  asserts the exact seven approved field names, including the notification
  preference, and still excludes credentials/roles. GREEN: 34 assertions.
- Original CSA060 fails because the two seeded development accounts contribute
  profiles to its global count. Counts now select only its dedicated fixture IDs.
  Its obsolete blanket avatar-write denial now checks the approved own-folder
  contract: forged/foreign references fail, own avatar/preferences can change,
  and the foreign profile stays unchanged. Protected identity/timestamp/role,
  banned/deleted/anonymous-account and cross-user tests remain.
- Original CSA182 fails on the approved avatar update grant. Its explicit profile
  update allowlist now names avatar_path and email_notifications_enabled as well
  as display_name/locale. Other columns remain denied; approved grants and the
  validated avatar own-folder constraint are asserted. GREEN: 325 assertions.
- All three original failures were reproduced from immutable a78a300 SQL files
  against the seeded disposable database; all repaired versions passed.
- CSA096 financial integrity (55 assertions) and CSA174 audit integrity passed
  unchanged. The wrapper had listed NOTICE locations as failures; a regression
  now proves notices/warnings and unknown paths cannot enter error summaries.
  The new location filter admits only ERROR/FATAL locations from known suites,
  preserving private-message redaction. RED: missing export; GREEN: all ten
  local-wrapper tests pass.
- Native SQL sweep: 41 suites pass. The two pgTAP-dependent suites cannot run
  without the extension; CSA139 needs the full Storage runtime grants absent
  from the minimal native shim. No application policy/grant was changed to make
  a shim pass. Hosted Supabase remains the acceptance check for these suites.
- `dart format --output=none --set-exit-if-changed lib test`: 368 files, zero
  changes, passed. The nine Dart modifications are formatter output only.
- Financial concurrency: all 27 checks passed against independent native PG17
  sessions, including checkout idempotency, payment finalization, bank review,
  entitlement and publication interleavings. CSA060's no-role assertion now
  selects only its fixture identities as well; its final 29 assertions pass
  even with unrelated committed concurrency fixtures present.
- Initial aggregate Node run: 867 passed, 11 skipped, one CSP browser check
  timed out. Its isolated rerun passed both cases. The hosted aggregate run
  separately failed when Chrome returned an empty DOM dump (line 81), before
  policy assertions ran. The browser harness now waits for a loopback HTTP
  result callback; the 20-second deadline and all policy assertions remain.
  No production CSP changes or browser-check skips. Fresh local handshake run:
  both CSP cases passed, zero skips.

## Follow-up baseline test repair

First published repair: 2d77aa9. Both hosted jobs started; Flutter formatting and
analysis passed, then full Flutter tests exposed two ambiguous Add Section
finders. The empty-state shortcut and persistent footer intentionally both
expose that action. Tests now exercise the empty-state action and footer
separately and retain the form/save/list assertions. Production curriculum
behavior is unchanged; PR201/202 authoring work remains owned by its task.
This bounded test-only extension and CSP-harness scope were recorded in #215.

The user authorized sharing the common repair through the PR206 chat. PR206
and PR209 confirmed they defer SQL/tooling ownership to CSA275 and integrate
only the finalized nine-file formatting subset until the test fixes pass.
Their original source worktrees remain untouched.

Final aggregate local Node run after the callback repair: 868 passed, 11 expected
skips, no failures/cancellations. Hosted run 39832227621 passed tooling, real
Supabase migration/SQL/concurrency checks and database lint, then exposed the
same obsolete blanket avatar-write denial in tool/supabase_smoke.mjs. That API
probe now checks malformed/foreign-folder rejection, successful own avatar and
notification updates, foreign-row isolation, and protected created_at denial.
Only fixed stage names are added to sanitized smoke diagnostics; responses,
identities, tokens and SQL errors remain private. This is test-contract
maintenance, not a production grant or policy change.

Hosted Flutter run 39832227635 passed the complete unit/widget suite and reached
Chrome checks. The initial local full run retains its two historical ambiguous
finder failures; a focused final journey rerun verifies their repaired source.

Status: IN_REVIEW. The code repairs are published for current-head CI and fresh
required reviewer approval. Live final results and remaining blockers are tracked
in issue #215 and PR #204; no merge or production deployment is claimed.

Status remains IN_PROGRESS until current-head hosted verification is available.
