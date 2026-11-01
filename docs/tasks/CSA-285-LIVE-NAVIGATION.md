# CSA-285 — Live navigation verification and Settings refresh repair

Date: 2026-10-31, Asia/Colombo. Owner: CODEX. Status: DONE.
Final acceptance documented: 2026-11-01; browser checks executed 2026-10-31.
Issue: [#243](https://github.com/iamramishka/acendra/issues/243).
Authority: owner requested checking and fixing “deployment confirmed; navigation
testing remains unverified.” Branch: `fix/csa-285-settings-refresh`.
Worktree: `C:/Users/ramis/.codex/worktrees/catalog-course-acceptance/acendra`.
Base: merged PR242 / dev `50246c46ff3bf939a3cb19ad99fda3af3f4e60f5`.

## Coordination and scope

Documentation reconciliation assignment (2026-11-01): owner explicitly requested
documenting the completed verification. Owner CODEX; branch
`docs/csa-285-live-acceptance`; same isolated worktree; base dev `65f31c1`.
Scope: this record and the current CSA-285 navigation paragraphs in compare.md
and CSA-COMPARE-STATUS-20261029.md only. Open PR201/202/246 and issue #243 were
checked; retain these newer dated status paragraphs when reconciling PR202's
historical comparison edits. Temporary documentation ownership covers these
paragraphs through review. Verify links, consistent evidence boundaries and
diff whitespace. Project owner/designated maintainer retains merge authority.
No application, test, deployment, shared TASKS.md or other worktree change.

Open issues/PRs, existing task evidence and affected source were checked before
edits. This reuses the isolated workspace after CSA-284 merged. Issue #243 records
the original verification assignment and bounded implementation scope extension.
Writable implementation: only Profile's Settings navigation callback, Settings'
Back behavior and a new Settings navigation regression suite. Temporarily own
the current navigation status paragraphs in compare.md and its evidence record.
No shared router, dependency, auth, payment, account, backend or deployment edit.

PR202 contains older versions of the two feature files and comparison records.
This follow-up changes current merged dev; preserve these newer navigation fixes
and dated evidence when reconciling that older CODEX integration branch. No
other worktree, pending patch or feature ownership is taken over.

## Deployment and actual browser observations

The authorized host is `https://3-25-99-105.sslip.io/`. Testing began while the
PR242 deployment was running; the preceding successful release was PR241 merge
`0d698a5`. During verification [deployment 41208646510](https://github.com/iamramishka/acendra/actions/runs/41208646510)
completed successfully for `50246c4`. The affected navigation implementation is
identical in both releases. This task did not approve or trigger that rollout.

Actual browser checks (not inferred from unit tests):

| Check | Observed result |
| --- | --- |
| Login → recovery; browser Back/Forward | PASS: correct login/recovery screens restored. No reset email submitted. |
| Login → registration | PASS: registration form rendered. No account created. |
| Existing session → Explore | PASS: saved session restored; four published courses loaded. |
| Search SQL; nonmatching/matching category | PASS: one → zero → one course with explicit no-match state. |
| SQL course details | PASS: matching title, category, two modules, four lessons and LKR 2,750.00; Buy Course shown, not pressed. |
| Actual course browser reload | PASS: same course URL and metadata restored. |
| Course Back after reload | PASS: Explore rendered. |
| Course URL in a fresh tab; fallback Back | PASS: course rendered independently; Back returned to Explore. |
| Home | PASS: discovery and explicit no-enrollments state loaded. |
| My Courses | PASS: explicit empty library state loaded. |
| Profile → Settings | Settings rendered, but URL stayed `/#/profile`: FAIL. |
| Browser Back/Forward around Settings | Screen restored from browser history, but retained the incorrect Profile URL. |
| Actual Settings reload | FAIL: returned to Profile because its URL never changed. |

The session was already available through the browser. No credentials are stored
in this record, and no personal, order or financial data was changed. Existing
published sample metadata was read; no dummy production content was inserted.
No enrolled-content, payment, password change, preferences persistence or
protected media acceptance is implied by these navigation checks.

## Reproduction and repair

Profile used `context.push(RouteNames.settings)`. The configured go_router
behavior keeps the declarative Profile URL for that imperative stack. Reload
therefore reconstructs Profile. Direct Settings loads also lacked a Back button.

Profile now uses `context.go(RouteNames.settings)`, keeping the location in the
browser address. Settings supplies Back explicitly: pop an existing stack when
present, otherwise navigate to the existing Profile route. No global router flag,
new route, hardcoded destination, or business-policy change is introduced.

RED: both new regressions failed on unchanged source: expected `/settings`, got
`/profile`; direct Settings had no BackButton. GREEN: all 39 Settings/Profile/
account-navigation tests passed after the repair, including three new tests for
the real screens' URL/reinitialization, direct-link fallback and existing stack.
The three changed Dart files pass analysis; formatting and diff checks pass.

Local release-browser verification: PASS. A temporary ignored QA entry point
renders the actual Profile and Settings widgets, with the same top-level route
paths and repository-backed providers overridden only with empty synthetic
preferences/avatar state. No Supabase connection or live account is used. A
release JavaScript build succeeded and was served on loopback port 8896. The
optional Wasm dry run hit a local DartWorker thread-start failure; Wasm
compatibility is not claimed from that attempt. The existing Cupertino font
warning was also reported. The debug-server preview did not render and was
stopped; browser acceptance below uses the successful release output instead.

The actual local browser verified Profile → `/#/settings`, physical reload
remaining on Settings, Settings Back → Profile, browser Back → Profile and
browser Forward → Settings, each with the matching address. A screenshot of
Settings after reload is attached to the chat. The isolated preview verifies the
modified real screens, not authentication or the entire deployed router shell.

Commands: `flutter test --no-pub test/features/settings test/features/profile
test/core/widgets/navigation/account_navigation_test.dart --reporter expanded`
(39 passed, zero failed/skipped); `flutter analyze --no-pub` restricted to the
three changed Dart files (no issues); changed-file `dart format` and
`git diff --check` (clean). The ignored local preview build used
`flutter build web --release --no-pub -t build/csa285_navigation_preview.dart
--output build/csa285-navigation-web` (exit 0, 159.4 seconds).

At submission, hosted acceptance still awaited review and rollout. The final
evidence below supersedes that submission-time limitation.

## Final integration and hosted acceptance — PASS

[PR #244](https://github.com/iamramishka/acendra/pull/244) received collaborator
approval and merged into dev as `5fb7bb9837b66ef311ce6cc7e33f858e4bcfb551`.
The [merge-commit CI](https://github.com/iamramishka/acendra/actions/runs/41211071098)
passed 1,272 Flutter tests, 53 configured Chrome checks, analysis, formatting,
release build and tooling regressions. The separately owner-authorized
[production deployment](https://github.com/iamramishka/acendra/actions/runs/41211605981)
succeeded for that exact commit; logs identify release
`/var/www/acendra/releases/20261031-145119`. Its deployed security checker returned
HTTP 200 with no policy findings; HTTPS/redirect/header smoke checks passed.

Browser permission failures delayed acceptance but were subsequently resolved.
The owner selected Chrome and personally signed in. The agent then directly
observed the following on the live host on 2026-10-31:

| Requested check | Result and evidence |
| --- | --- |
| Login | PASS for owner-performed sign-in and resulting authenticated session; Home displayed Student Account. Agent did not test credential submission/error cases. |
| Home | PASS: personal welcome, discovery and explicit no-enrollments state. |
| My Courses | PASS: navigation reached `/dashboard/courses` and loaded the explicit empty-library state. |
| Explore | PASS: four published courses loaded at `/marketplace`. Earlier restored-browser checks also verified SQL search and category matching/mismatching. |
| Course details / Back | PASS: SQL for Beginners displayed matching category, two modules, four lessons and LKR 2,750.00; Back returned to Explore. Actual course reload and fresh-tab direct links were checked earlier in this task. |
| Settings URL | PASS: account menu → Profile → Settings changed the browser address to `/#/settings`. |
| Settings refresh | PASS: actual Chrome reload retained Settings and its URL, restored the signed-in account and loaded preference controls. |
| Settings Back | PASS: Back after reload reached `/#/profile` and the real profile form. |
| Browser Back / Forward | PASS: reopening Settings, Chrome Back restored Profile; Forward restored Settings, each with matching URLs. |

Screenshot `chrome-settings-live-pass.png` is attached to the chat; no credentials
or private profile values are included in this repository. Final evidence is
also recorded in closed [issue #243](https://github.com/iamramishka/acendra/issues/243).
At acceptance, the newer `65f31c1` deployment was waiting and was not used as
evidence. This record describes the tested `5fb7bb9` release, not a fresh browser
test on the documentation date or any later release.

The requested navigation scope is DONE. No preferences or personal data changed,
no order was created, and no purchase/password/media action was performed.
Enrolled learning, artwork availability, preferences persistence, payment and
protected playback acceptance remain separate tasks. The original live Settings
refresh defect is fixed and its hosted retest passed.
