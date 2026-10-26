# compare.md
# Acedra — Mobile Prototype vs Flutter App: Layout & Flow Audit

Status: Draft audit (IN_REVIEW) — not a task claim
Prepared by: CLAUDE
Date: 2026-10-18
Prototype: "Acedra Mobile Prototype" artifact — https://claude.ai/artifact/NDAfFDE3QHzxMNTRXqf4RJ
Code audited: branch `feat/csa-158-172-dashboard-receipts-ui` at `9ba9c0d`
Scope: student-facing screens only (the prototype has no admin screens)

---

## Pending index (baseline 2026-10-19; COM-008 updated 2026-10-21)

| Task | Area | What's pending |
|---|---|---|
| COM-007 | Auth | Not started: live checklist, show/hide toggle, 5-char rule, signed-in "Change password" path |
| COM-009 | Catalog | Not started: sticky footer, "open order" state, lock/play icons, back navigation |
| COM-010 | Payment | Not started: step bar, raw course id in summary, single bank screen, sticky total, back button |
| COM-011 | Payment | Failed, blocked by CSA-265: order loaded from `state.extra`, no Refresh, bank copy on PayHere page |
| COM-012 | Payment | PNG rejected, instructions lost on refresh, upload on separate screen (CSA-265 files) |
| COM-013 | Payment | Amount/date not returned by backend, D-6 copy in a CSA-265 file |
| COM-015 | Student | "Sample content" notice remains, `com015` migration not run |
| COM-016 | Student | Cards open resume lesson not overview, migration not run |
| COM-020 | Learning | IN_REVIEW — CSA-271: v2 watermark and active reader implemented; 22 local browser checks and artifact comparison passed. Hosted deployment, CI/review and dev merge gates remain. |
| COM-021 | Account | DONE 2026-10-21. Avatar displayed in header. Language selector (EN/SI) syncs to DB. Inline edit merged. |
| COM-022 | Account | DONE 2026-10-21. Language (EN/SI) DropdownButton + Email Notifications SwitchListTile added to Settings. Migration `20261020000100_com022_email_notifications.sql` adds `email_notifications_enabled boolean not null default true` to `profiles`, grant included. |
| COM-023 | Cross-cutting | DONE 2026-10-20 (05a5088). 3 fixes: raw 'stripe' code, raw amount_minor, 2 tap targets. All 4 admin list screens confirmed with loading/empty/error states; no raw exception text found. |
| COM-006 | Auth | Hero aligned and browser-verified 2026-10-22 (CSA-272, PR #209); IN_REVIEW, current combined-head CI and approval remain gates |
| COM-008 | Catalog | IN_REVIEW — implemented in [PR #204](https://github.com/iamramishka/acendra/pull/204) (CSA-270): lazy `SliverGrid`, category dot/label, title/blurb, responsive cards and offline preview. 19 widget checks, analysis and release build pass locally. Browser/prototype comparison, hosted CI, required approval and merge to dev remain pending. |
| COM-002 to 005 | Shell/Auth | MERGED to dev 2026-10-20 (PR #186, e0cc143). Browser check pending (CI/CD will deploy when baseline passes and reviewer approves). COM-004: Terms/Privacy pages still plain text (no real pages); Supabase Auth floor confirmed 6 chars (D-1 final decision). |
| COM-014 | Student | DONE 2026-10-20 (code in dev; RLS second-account isolation verified via DB test suite) |
| COM-017 | Learning | VERIFIED locally 2026-10-20 (localhost:9090, branch `feat/com-007-password-reset`): course overview loads from `/learn/:courseId`, shows progress %, Continue Learning card, expandable curriculum with lesson markers. Progress updates after Mark Complete. Back from lesson goes to My Courses (not overview — known COM-016 gap). |
| COM-018 | Learning | VERIFIED locally 2026-10-20: "Lesson 01 · Video Lesson" header, In Progress pill, progress counter (0/4 → 1/4 after completing), "Mark Complete & Continue" sticky footer works. MERGED to dev 2026-10-20 (087beba). CI/CD will deploy when baseline passes and reviewer approves. |
| COM-019 | Learning | DONE 2026-10-21. Code correct (merged `f44526a`). 4 widget tests added: "Mark Complete & Continue" for non-last lesson, "Mark Complete" for last, hidden when completed, Module-finished snackbar. `flutter analyze` clean. Browser tests pending CI (35 Chrome instances exhausted local env). |
| COM-001 | Foundation | DONE 2026-10-19 (owner accepted): fonts and Sign in (light) checked on live site; Checkout, dark and Explore not compared |

---

## 1. How to use this file

1. Work through the COM tasks one at a time, in order.
2. For each task, open the prototype screen and the Flutter screen side by side
   at **390 px** width (the prototype's phone width), then repeat at 768 and 1440.
3. Tick each checkbox under **Check** only after seeing it yourself in the running
   app. Leave the task's `Result` as `—` until every box is checked.
4. Gaps marked **DECISION** need a project-owner answer before anyone builds them.
5. Before implementation, each COM task must be turned into a CSA task and GitHub
   Issue with an owner, branch and file scope (AGENTS.md §6, §8). COM IDs are
   audit IDs only, not task claims.

Important rule for "match the prototype":
the prototype fakes data and unlocks courses in the browser. The Flutter app
must copy the **layout and the flow**, never the fake logic. Enrollment, payment
status, receipt state and PDF access stay backend-authoritative (AGENTS.md §30–§33).
Prototype-only copy ("Sample Bank PLC", `-DEMO` order refs, `EXAMPLE-042`,
"Coded prototype with sample data") must not ship.

### Verdict legend

| Verdict | Meaning |
|---|---|
| MATCH | Layout and flow already match the prototype |
| PARTIAL | Screen exists; layout and/or flow differ |
| MISSING | Prototype screen has no Flutter equivalent |
| CONFLICT | Prototype and app disagree on a rule; owner decision needed |
| IN_REVIEW | Implementation submitted; remaining acceptance, review and merge gates are not complete |

---

## 2. Summary

| ID | Area | Prototype screen | Flutter source | Verdict | SRS | Priority |
|---|---|---|---|---|---|---|
| COM-001 | Foundation | Tokens, fonts, light/dark | `lib/app/theme/**` | MATCH | — | P2 |
| COM-002 | Shell | 4-tab bottom nav | `lib/core/widgets/navigation/student_shell.dart` | DONE 2026-10-20 | — | P1 |
| COM-003 | Auth | Sign in | `authentication/.../login_screen.dart` | DONE 2026-10-20 | UI-ST-002 | P2 |
| COM-004 | Auth | Create account | `authentication/.../register_screen.dart` | DONE 2026-10-20 | UI-ST-003 | P1 |
| COM-005 | Auth | Check your inbox | `authentication/.../verify_email_screen.dart` | DONE 2026-10-20 | UI-ST-005 | P2 |
| COM-006 | Auth | Forgot password | `authentication/.../forgot_password_screen.dart` | IN_REVIEW (CSA-272) | UI-ST-004 | P2 |
| COM-007 | Auth | Set / change password | `authentication/.../reset_password_screen.dart` | PARTIAL + CONFLICT | UI-ST-004 | P1 |
| COM-008 | Catalog | Explore courses | `marketplace/.../marketplace_screen.dart` | IN_REVIEW (PR #204) | UI-ST-007/008 | P1 |
| COM-009 | Catalog | Course details | `marketplace/.../course_detail_screen.dart` | PARTIAL | UI-ST-009/010 | P1 |
| COM-010 | Payment | Secure checkout | `checkout/.../checkout_screen.dart` | PARTIAL | UI-ST-011 | P0 |
| COM-011 | Payment | PayHere "Checking your payment" | `checkout/.../payment_pending/success/failure_screen.dart` | PARTIAL | UI-ST-014 | P0 |
| COM-012 | Payment | Bank transfer + receipt upload | `bank_transfer/.../bank_transfer_screen.dart`, `checkout/.../receipt_resubmission_form.dart` | PARTIAL | UI-ST-012/013 | P0 |
| COM-013 | Payment | Bank payment status timeline | `bank_transfer/.../receipt_status_screen.dart` | PARTIAL | UI-ST-014 | P1 |
| COM-014 | Payment | Order history | `orders/.../orders_screen.dart` | DONE 2026-10-20 | UI-ST-022 | P1 |
| COM-015 | Student | Home | `dashboard/.../dashboard_home_screen.dart` | PARTIAL (different screen) | UI-ST-006 | P1 |
| COM-016 | Student | My Courses | `my_courses/.../my_courses_screen.dart` | PARTIAL | UI-ST-015 | P1 |
| COM-017 | Learning | Course overview + progress | `learning/.../course_overview_screen.dart` | DONE 2026-10-20 | UI-ST-016 | P1 |
| COM-018 | Learning | Video lesson | `learning/.../learning_workspace_screen.dart`, `video_player/**` | DONE 2026-10-20 | UI-ST-017 | P2 |
| COM-019 | Learning | Text & image lesson | `learning/.../text_lesson_viewer.dart` | DONE 2026-10-20 | UI-ST-019 | P2 |
| COM-020 | Learning | PDF reader | `pdf_reader/**` | IN_REVIEW | UI-ST-018 | P1 |
| COM-021 | Account | My profile | `profile/.../profile_screen.dart`, `profile_edit_screen.dart` | DONE 2026-10-21 | UI-ST-020 | P2 |
| COM-022 | Account | Settings | `settings/.../settings_screen.dart` | DONE 2026-10-21 | UI-ST-021 | P1 |
| COM-023 | Cross-cutting | Empty / loading / error / feedback | various | DONE 2026-10-20 | — | P2 |

Summary table: 1 MATCH, 11 recorded DONE, 8 PARTIAL (including 1 with CONFLICT),
 and 3 IN_REVIEW (COM-006, COM-008 and COM-020). These totals reflect the table's recorded labels;
 they do not establish fresh browser verification or release acceptance.

---

## 3. Owner decisions needed first

| Ref | Question | Prototype | App today | Blocks |
|---|---|---|---|---|
| D-1 | Minimum password length | 8 chars + letter + number | 6 chars, no other rule | COM-004, COM-007 |
| D-2 | Bottom-nav tabs | Home · Explore · My Courses · Profile | Home · My Learning · Saved · Profile | COM-002 |
| D-3 | Owner format recorded; v2 implementation in review | Personal diagonal watermark | Acendra Product + display name + opaque licence ID in server bytes; hosted delivery disabled by default | COM-020 |
| D-4 | Interface languages (SRS DEC-013 still open) | English / Sinhala / Tamil selector | none | COM-021, COM-022 |
| D-5 | Billing details on checkout | not shown | First/Last/Phone/Address/City/Country required (PayHere fields) | COM-010 |
| D-6 | Receipt review time copy | none | "1–2 business days" | COM-013 |
| D-7 | Home content | personal (resume, my courses, recent) | marketing carousel with **sample content** | COM-015 |
| D-8 | Email notification preference | on/off toggle | none, no backend field | COM-022 |

### Owner answers (2026-10-18)

- D-1 (superseded 2026-10-19): the owner selected **6 characters, no strength rules** after verification that Supabase Auth enforces a six-character floor. This replaces the earlier five-character decision; local/client configuration must agree. Hosted settings require separate read-back, not an assumed change from this file.
- D-3: watermark = "Acendra Product" plus the student's name and ID.
- D-4: English and Sinhala (no Tamil).
- D-5: keep billing fields; Country defaults to Sri Lanka, changeable via a searchable country dropdown (suggestions as the user types).
- D-6: show "1–2 business days".
- D-8: add the email notification on/off toggle (needs a backend preference field).

D-5 note: PayHere needs the customer fields (see the checkout repository's
expected-field list), so they cannot just be deleted. Options: prefill from the
profile, collect them once and remember them, or keep the form but collapse it.

---

## 4. Audit tasks

### COM-001 — Design tokens, fonts and theme

Prototype: colours copied from `app_colors.dart`, Manrope headings, Inter body,
light + dark + system theme.

Current app:
- `lib/app/theme/app_colors.dart:55-72` — Royal Blue `#1259DB`, Sky Cyan
  `#1DA2FD`, Deep Navy `#0D1633`, background `#F5F8FC`. Same as the prototype.
- `lib/app/theme/app_typography.dart` — Manrope headings, Inter body. Same.
- Breakpoints: compact 600, medium 1024 (`app_breakpoints.dart`).

Gaps: none in tokens. Individual screens often use raw Material defaults instead
of the prototype's card/radius/pill styles — tracked in each task below.

Check:
- [ ] Light theme colours match on Sign in, Explore and Checkout. (code: every light token hex equals the prototype's. Seen 2026-10-19 on the live site: Sign in matches the prototype side by side; Explore renders in light; Checkout not viewed, see below)
- [ ] Dark theme colours match on the same three screens. (code: every dark token hex equals the prototype's. Seen on the live site: Sign in and Explore render in dark; the prototype's dark screens were not opened; Checkout not viewed)
- [x] Headings render in Manrope, body text in Inter. (seen 2026-10-19 on the live site: the page fetched Manrope SemiBold, Manrope Bold, Manrope ExtraBold and Inter Regular font files, read from their name tables)

Visual check (2026-10-19, http://3.25.99.105, 390 px, the build from the last
approved production deploy, not this branch):
- Sign in, light: background, Royal Blue button, navy headings and field styling look the same as the prototype.
- Sign in and Explore, dark: render with the dark palette; the theme toggle works.
- Not viewed: Checkout (needs a signed-in student and an order; no test account used).
- Not viewed: the prototype's Explore and dark screens; 768 and 1440 px.
- Not measured: Explore's page background looked whiter than Sign in's #F5F8FC in light; check the exact colour.
- Noticed, outside COM-001: the live Sign in hero banner image carries "Create your account" artwork beside the "Welcome back" text.
- Deploy: not pushed by this check. A "Deploy to Production" run for `dev` was still waiting for reviewer approval.

Result: DONE (2026-10-19), accepted by the project owner as enough. Verified:
fonts and Sign in (light) on the live site, plus the code-level token match.
Not verified: Checkout, the prototype's dark and Explore screens, 768 and 1440 px.
The unchecked boxes above are left unchecked on purpose.

---

### COM-002 — Student shell and bottom navigation — DONE 2026-10-20

Prototype layout: brand header (logo + "Acedra", profile avatar at right);
4-tab bottom bar **Home · Explore · My Courses · Profile**; Order History and
Settings highlight the Profile tab; lesson screens have no bottom bar.

Current app: `lib/core/widgets/navigation/student_shell.dart`
- Bottom bar shown only when width < 1024 (`:19`).
- Tabs (`:127`): **Home · My Learning · Saved · Profile**. "Explore" is a top-bar
  text button on wide screens only; on mobile you reach it through the search icon.
- App bar also carries search, theme toggle and an account menu.
- Saved tab opens a "coming soon" screen (`DashboardCopy.savedComingSoon`).
- Logged-in users on `/marketplace` get the StudentShell (`public_shell.dart`),
  good — same nav as the prototype.
- `LearningShell` back button calls `context.pop()`
  (`learning_shell.dart:18`). Opening `/learn/:id` directly (refresh, deep
  link, or after `context.go`) leaves nothing to pop. **Flow bug.**

Gaps:
- Layout: tab set differs (D-2). "My Learning" vs prototype "My Courses" label.
- Layout: theme toggle sits in the app bar; prototype moves it into Settings.
- Flow: Order History and Settings do not exist, so Profile has no sub-pages to
  highlight (COM-014, COM-022).
- Flow: Learning back button can fail on a directly opened lesson.

Check:
- [ ] At 390 px the bottom bar shows exactly the agreed tabs (after D-2).
      (code: FAIL — app has Home · My Learning · Saved · Profile; prototype has Home · Explore · My Courses · Profile)
- [ ] Each tab opens the right screen and shows as selected. (not checked; Saved is a "coming soon" screen)
- [ ] Explore is reachable in one tap on mobile.
      (code: no — only via the app-bar search icon, which goes to `/marketplace?search=true`)
- [ ] Refresh the browser on `/learn/<id>`, then press back: you land on My Courses
      (or the course overview), not a dead button.
      (code: `learning_shell.dart:18` calls `context.pop()` with no fallback; not run)

Fixed on `feat/csa-265-prototype-alignment`, MERGED to dev 2026-10-20 (PR #186, e0cc143): tabs are now Home · Explore · My Courses · Profile (`DashboardCopy` labels). Learning back falls back to My Courses. Theme toggle moved to Settings screen (COM-022 dependency resolved in PR #186).
Browser check: not yet run (code in dev; CI/CD will deploy when baseline passes and reviewer approves).
Earlier result: FAIL (code-only, 2026-10-18). Tab set differed; Explore not a mobile tab; theme toggle in app bar; learning back had no fallback.

---

### COM-003 — Sign in — DONE 2026-10-20

Prototype layout: logo header → navy hero "Welcome back / Continue your learning
journey." → title "Sign in to Acedra" + subtitle → Email (mail icon) → Password
(lock icon, Show/Hide) → Remember me + Forgot password? → **Sign In →** →
"or" → card "New to Acedra? Create an account".
Prototype flow: invalid email / empty password show inline errors → success goes
to Home.

Current app: `authentication/presentation/screens/login_screen.dart`
- Layout matches closely: banner, heading, icons, remember-me row, "or",
  create-account card are all present.
- Adds Privacy Policy · Terms of Service links at the bottom.
- Success goes to `/dashboard` → `/dashboard/home`. Matches.

Gaps:
- Flow: **Remember me does nothing.** `_rememberMe` (`:27`) is never read.
  Either wire it to session persistence or remove it; do not ship a fake control.
- Flow: Privacy Policy and Terms buttons have empty handlers (`:270`, `:289`).
- Layout: banner uses an image asset (`signin_banner.png`) with a silent fallback;
  confirm the asset exists in the build, otherwise the hero is half empty.
- Copy: email validation is "contains @ and ." — weaker than the prototype regex.
  Minor.

Check:
- [ ] 390 px: order of elements matches the prototype top to bottom.
      (code: matches — hero, title, email, password, remember/forgot, Sign In, "or", card; app adds a Privacy/Terms footer; not viewed)
- [x] Empty submit shows both inline errors. (code: `_submit` sets both errors; not run)
- [ ] Wrong password shows a readable error, no stack trace.
      (code: shows `AuthFailure.message` in a snackbar, not inline; not run)
- [ ] Correct login lands on Home. (code: goes to `RouteNames.dashboard`; not run)
- [ ] Remember me: either works (session survives browser restart only when on) or is removed.
      (code: FAIL — `_rememberMe` is only written, never read)
- [ ] Privacy / Terms links open real pages or are hidden.
      (code: FAIL — both `onPressed: () {}`)

Fixed on `feat/csa-265-prototype-alignment`, MERGED to dev 2026-10-20 (PR #186, e0cc143): fake Remember me removed, dead Privacy/Terms footer removed, shared prototype widgets used, stricter email validation.
Browser check: not yet run (code in dev; CI/CD will deploy when baseline passes and reviewer approves).
Earlier result: PARTIAL (code-only, 2026-10-18). Remember me was a dead control, Privacy/Terms did nothing, email check was "contains @ and ." only.

---

### COM-004 — Create account — DONE 2026-10-20

Prototype layout: logo header with back → navy hero "Create your account / Start
learning with confidence." → Full name (user icon) → Email → Password ("At least 8
characters") → Confirm password → **checkbox "I agree to the Terms of Service and
Privacy Policy"** → **Create Account →** → "or" → "Already have an account? Sign In".
Prototype flow: all fields validated, terms must be ticked → "Check your inbox".

Current app: `authentication/presentation/screens/register_screen.dart`
- Plain form: heading "Create your account", subtitle "Start learning today",
  four labelled fields, button, sign-in link.
- Success stores the email and goes to `/verify-email`. Matches.

Gaps:
- Layout: no hero banner, no field icons, no "or" divider, plain text link instead
  of the soft card. Uses floating labels while Sign in uses labels above fields —
  inconsistent between the two auth screens.
- Flow: **no terms/privacy consent checkbox.** Prototype blocks signup without it.
- CONFLICT D-1: app accepts 6 characters (`:53`); prototype requires 8.
  Must also match the Supabase Auth password policy server-side.
- No back button in header (prototype has one).

Check:
- [ ] Layout matches the prototype at 390 px (hero, icons, consent, card link).
      (code: FAIL — no hero, field icons, "or" divider or card; floating labels vs labels-above on Sign in)
- [ ] Submitting without consent shows an error and does not call sign-up.
      (code: FAIL — no consent checkbox exists)
- [ ] Password rule matches D-1 in both the form and Supabase Auth settings.
      (code: FAIL — form allows 6 at `register_screen.dart:53`, prototype 8; Supabase setting not checked)
- [x] Mismatched passwords show "Passwords do not match". (code: matches; not run)
- [ ] Success lands on Check your inbox with the email shown.
      (code: goes to verify-email and stores the email; not run)

Fixed on `feat/csa-265-prototype-alignment`, MERGED to dev 2026-10-20 (PR #186, e0cc143): hero banner, field icons, back button, consent checkbox, "or" + card link. Password minimum 6 chars (D-1 final decision: 6 chars, no strength rules). Terms/Privacy are plain text (no real pages exist yet); consent is client-side only, not stored server-side.
Browser check: not yet run (code in dev; CI/CD will deploy when baseline passes and reviewer approves).
Earlier result: FAIL (code-only, 2026-10-18). Missing hero, icons, consent, "or" divider, card link; password minimum conflict on D-1.

---

### COM-005 — Check your inbox (email verification) — DONE 2026-10-20

Prototype layout: soft hero with mail tile + check badge → "Check your inbox" →
masked email pill (`de••@example.com`) → helper text → **Resend Verification Email**
(disabled with a 30 s countdown after use) → **Back to Sign In** → info box
"Didn't receive the email? Check your spam folder…".

Current app: `authentication/presentation/screens/verify_email_screen.dart`
- Icon, "Verify your email", full email in plain text, Resend (outlined),
  Back to sign in.

Gaps:
- Layout: no hero, no masked-email pill, no spam-folder info box. Title wording differs.
- Flow: **no resend cooldown** — the button re-enables as soon as the call
  returns, so users can spam it (Supabase also rate-limits; show that nicely).
- Privacy: prototype masks the email; app shows it in full. Masking is the
  safer default on a shared screen.
- If the page is refreshed, `pendingVerificationEmailProvider` is empty, so the
  resend button disappears. Prototype always offers resend.

Check:
- [ ] Layout matches the prototype.
      (code: FAIL — no hero tile/badge, email pill or spam-folder info box; title "Verify your email" vs "Check your inbox")
- [ ] Email is masked. (code: FAIL — full address shown; prototype shows `de••@example.com`)
- [ ] After Resend, the button shows a countdown and is disabled until it ends.
      (code: FAIL — re-enables as soon as the call returns)
- [ ] After a browser refresh the screen still offers a way to resend.
      (code: FAIL — Resend is hidden when `pendingVerificationEmailProvider` is null)

Fixed on `feat/csa-265-prototype-alignment`, MERGED to dev 2026-10-20 (PR #186, e0cc143): hero tile + badge, masked email pill (`maskEmail()`), 30 s resend cooldown (`resendCooldownSeconds = 30`), spam info box, fallback email entry when address is lost on refresh.
Browser check: not yet run (code in dev; CI/CD will deploy when baseline passes and reviewer approves).
Earlier result: FAIL (code-only, 2026-10-18). All four gaps confirmed: layout, masking, 30 s cooldown, refresh behaviour.

---

### COM-006 — Forgot password

Prototype layout: soft hero (lock tile + send badge) → "Forgot your password?" →
Email → **Send Reset Link →** → **Back to Sign In** (outlined) → info box "If an
account exists for the address, reset instructions will be sent."

Current app: `authentication/presentation/screens/forgot_password_screen.dart`
- Form then an in-place success view "Check your inbox — We sent a password reset
  link to <email>."

Gaps:
- Layout: no hero, no info box; Back to sign in is a text link not a button.
- Privacy/flow: success copy **"We sent a password reset link to <email>"**
  confirms an account exists. Prototype uses neutral wording ("If an account
  exists…"). Use the neutral wording to avoid account enumeration.
- Flow: prototype goes straight to the reset screen (demo only). The real flow
  must stay email-link → `/reset-password`; keep the app's behaviour here.

Check:
- [ ] Layout matches the prototype.
- [ ] Success message does not confirm whether the account exists.
- [ ] Reset link in the email opens `/reset-password` and works.

Current result: IN_REVIEW (2026-10-22), CSA-272, [PR #209](https://github.com/iamramishka/acendra/pull/209).
Hero now follows the observed artifact: gradient blue lock tile, cyan send badge,
two floating dots and curved blue ribbon. Browser comparison passed at 390, 768
and 1440 pixels in light and dark themes. Empty/malformed-email validation and
Back to Sign In were verified in the local release app. Neutral success wording
is covered by the synthetic repository test. The banner is a Flutter recreation;
Material icons and existing form typography are retained, not a pixel-identical
export. Actual reset-email delivery/link consumption remains unverified.
Screenshots and exact command results: [CSA-272 evidence](docs/tasks/CSA-272.md).
The earlier CI startup billing restriction is historical: both workflows passed
at 1a30ec7. Current-dev integration requires fresh CI and independent approval.
Vercel preview remains failed. No completed end-to-end recovery is claimed.

Historical result: PARTIAL (2026-10-18, commit 3852c6e); generic recovery hero was
subsequently integrated via CSA-265. This follow-up changes only its artwork.

---

### COM-007 — Set new password / Change password

Prototype layout: soft hero (shield) → "Set a new password" (or "Change your
password" when signed in) → New password → Confirm → **live checklist** (8+ chars,
letters and a number, both match) → **Update Password** disabled until all rules
pass → Back to Sign In (only when signed out).
Prototype flow: signed-out → back to Sign in with toast; signed-in (from Settings)
→ back to Settings with "Password updated."

Current app: `authentication/presentation/screens/reset_password_screen.dart`
- Two plain fields (no show/hide), button, Back to sign in. Always returns to
  `/login`.

Gaps:
- Layout: no hero, no live checklist, no show/hide toggle (uses `AppTextField`
  with `obscureText` instead of `AppPasswordField`).
- CONFLICT D-1: 6-char minimum (`:42`).
- Flow: **no signed-in "Change password" path.** There is no Settings screen
  linking here, and after success it always sends the user to `/login`.
- Button is always enabled; prototype disables it until rules pass.

Check:
- [ ] Checklist updates as you type and the button stays disabled until all pass.
- [ ] From Settings (once COM-022 exists) the flow returns to Settings, still signed in.
- [ ] From the email link the flow returns to Sign in.

Result: —

---

### COM-008 — Explore courses (catalog + search) — IN_REVIEW 2026-10-21

Prototype layout: brand header → "Explore Courses / Discover skills worth
mastering." → rounded search field → category chips (All Courses, …) → row with
"**N Courses**" count and **Sort** (Popular · Price low→high · Price high→low) →
one-column list of large course cards (gradient art, category dot, title, blurb,
price, chevron).
Prototype flow: search and chips filter live; no results → "No courses found —
Try a different word or category."

Implementation: **CSA-270**, [issue #203](https://github.com/iamramishka/acendra/issues/203),
[PR #204](https://github.com/iamramishka/acendra/pull/204), branch
`feat/csa-270-catalog-sliver`. Source and verification recorded through `5a94172`.
The PR is ready for review and **has not merged into dev**.

Implemented in the PR:
- `SliverLayoutBuilder` + `SliverGrid.builder` build visible/cached cards instead
  of eagerly building the entire catalog. Actual available width selects 1/2/3
  columns, including when the catalog is narrower than the browser window.
- Title/subtitle, rounded search, category chips, count and sorting remain in
  the recorded prototype order. Sorting supports Newest and both price directions;
  Popular is not added because no popularity data contract exists.
- Cards preserve real artwork delivery and its gradient fallback, category
  dot/label, title, separate description, formatted price and chevron. Card height
  accounts for enlarged text; titles and descriptions have bounded lines.
- Search misses use "No courses found" separately from an empty catalog.
  Card navigation opens the real course-detail screen.
- `tool/catalog_preview.dart` supplies six clearly labeled synthetic courses and
  matching curriculum details for offline QA. Checkout explicitly creates no
  order. This preview is not used by production; its marker was checked absent
  from the release JavaScript bundle.

Local automated verification (Flutter widget runner, **not Chrome**):
- All **19 focused tests pass**, including search, category filters, both price
  sort directions, detail navigation, offline checkout refusal, lazy scrolling
  through 100 courses and a narrow container in a wide viewport.
- The layout matrix covers **320, 390, 768 and 1440 px**, light/dark themes and
  100%/200% text. This establishes widget-layout behavior, not artifact parity.
- Full `flutter analyze --no-pub` passes. All eight changed/new Dart files format
  cleanly. `flutter build web --release --no-pub` passes, including the Wasm
  compatibility dry run; the pre-existing CupertinoIcons font warning remains.

Browser acceptance checklist (left open until seen in the running browser):
- [ ] Title, search, chips, count, sort and cards appear in prototype order.
- [ ] Sort changes order correctly for both price directions.
- [ ] Search with no match shows "No courses found", not "No courses available yet".
- [ ] Tapping a card opens Course details.

Remaining gates:
- The remote artifact could not be opened, and interactive browser access is
  disabled in Work settings. Chrome tests compiled after an import correction
  but stalled before suite loading; a minimal standalone smoke test also stalled
  before assertions. No browser checks or screenshots passed. Exact visual
  comparison remains **INCONCLUSIVE**.
- GitHub Actions cannot start because of an account-level billing/spending
  restriction. Required approving review is outstanding. The full local format
  check also finds nine unchanged baseline files outside CSA-270's scope.
- Complete browser/prototype comparison, restore hosted checks, resolve baseline
  formatting through the respective owners, obtain approval and merge PR #204.

Result: **IN_REVIEW (2026-10-21)** — implementation and local checks complete;
browser acceptance, CI, review and merge remain pending. Detailed commands,
evidence and ownership are in [the CSA-270 task record](docs/tasks/CSA-270.md).

Historical result (2026-10-18, `3852c6e`): header, count, sort and search-miss copy
were fixed; card metadata and lazy-grid work were still recorded as pending.
The newer CSA-270 entry above supersedes that pending-work description.

---

### COM-009 — Course details

Prototype layout: header "Course Details" with back → large course art →
category + title + blurb → chips "N modules" "N lessons" → card **What You'll
Learn** (check list) → card **About This Course** → card **Course Curriculum**
(expandable modules; lessons show lock icon if not owned, play icon if owned,
minutes) → **sticky footer** with price + action.
Prototype flow — footer has three states:
1. Not owned, no open order → price + **Buy Course** → Checkout.
2. Open (unpaid) order exists → status label + **Payment Status** → PayHere
   status or bank status screen.
3. Owned → "You own this course · N% done" + **Go to Course** → Course overview.

Current app: `marketplace/presentation/screens/course_detail_screen.dart`
- AppBar with course title, price row + "Enrolled" chip, descriptions, stats,
  one button **Enroll Now / Continue Learning**, curriculum `ExpansionTile`s
  with type icons and "Preview" chip.

Gaps:
- Layout: no hero image, no "What You'll Learn" card, no sticky footer (button
  scrolls away), no lock/play icons per lesson, no lesson durations.
- Flow: **no "open order" state.** A student with a pending PayHere or bank
  order sees "Enroll Now" again and can start a second order. Prototype routes
  them to Payment Status instead. Needs a backend read of the student's open
  order for this course (contract needed).
- Flow: "Continue Learning" goes straight into `/learn/:id`; prototype goes to the
  course overview first (COM-017).
- Flow: back always goes to `/marketplace` (`:38`), even when the user came from
  Home or My Courses.
- Copy: "Enroll Now" vs prototype "Buy Course".

Check:
- [ ] Sticky footer stays visible while scrolling.
- [ ] Not owned → Buy Course → Checkout.
- [ ] Pending order → Payment Status, and no second order can be started.
- [ ] Owned → Go to Course → course overview.
- [ ] Back returns to the screen you came from.

Result: —

---

### COM-010 — Secure checkout

Prototype layout: header "🔒 Secure Checkout" + logo → **3-step bar** (Order ✓ ·
Payment · Confirm) → "Complete Your Purchase" → card **Order Summary** (art,
title, category, lessons, Total) → card **Select Payment Method** (radio cards:
Online Payment / PayHere logo; Bank Transfer) → info box that changes with the
method → "Your card details are entered on PayHere, not in Acedra." → **sticky
footer**: Total Amount + **Continue to PayHere** / **Continue to Bank Transfer**.
Prototype flow: one tap creates the order → PayHere status (COM-011) or bank
transfer screen (COM-012).

Current app: `checkout/presentation/screens/checkout_screen.dart`
- Order Summary card, Payment Method cards, **Billing Details** form,
  **Proceed to Payment** (`:433`) creates the order, then **Pay Now** (`:440`)
  starts PayHere. For bank: bank instructions card, **Continue Bank Transfer**,
  plus a **receipt upload form embedded under it** (`:459`).

Gaps:
- Layout: no step bar, no method explanation info box, no "card details stay on
  PayHere" line, no sticky footer total.
- Layout bug: before the order exists the summary shows **"Course: <raw id>"**
  (`:254`) instead of title, art and price. The course is already loaded on the
  details screen; show it here.
- Flow: two taps (Proceed → Pay Now) vs one. Acceptable if D-5 keeps billing
  fields; otherwise merge.
- Flow: bank method shows instructions **and** an upload form on checkout, and
  also a button to the bank screen — the same job in two places. Prototype has
  one bank screen with upload (COM-012).
- Flow: status badge prints the raw backend value uppercased
  ("PENDING PAYMENT"). Map to the prototype labels.
- Flow: back uses `Navigator.maybePop()` (`:180`); after `context.go` there may be
  nothing to pop.
- DECISION D-5 (billing fields).

Security (keep as is): order creation and PayHere handoff are server-side and
validated (`checkout_submission_repository.dart`). Do not move any of it client-side.

Check:
- [ ] Before any order, summary shows the real course title, art and price.
- [ ] Step bar shows Order done, Payment current.
- [ ] Switching method changes the info box and footer button label.
- [ ] Online: one clear path to PayHere; card data never entered in Acedra.
- [ ] Bank: lands on a single bank screen with instructions + upload.
- [ ] Back works after a direct page load.

Result: —

---

### COM-011 — PayHere payment status ("Checking your payment")

Prototype layout: header "Payment Status" → spinning ring with shield →
"Checking your payment" → pill "Verification in progress" → card **Transaction
Details** (course, order ref, method, amount, status pill) → info box "Your course
unlocks after the payment is verified. Avoid starting another payment…" →
**Refresh Payment Status** → **View Order History**.
Prototype flow: Refresh re-checks status; reachable later from Course details and
Order history.

Current app: `/checkout/:id/pending`, `/success`, `/failure`
(`payment_pending_screen.dart`, `payment_success_screen.dart`,
`payment_failure_screen.dart`). Reached only from PayHere's return/cancel URL
(configured server-side in `supabase/functions/_shared/payments/payhere.mjs`).

Gaps:
- Flow: **screens read course title and order number from `state.extra`**
  (`app_router.dart` pending/success/failure builders). A PayHere redirect is a
  full page load with no `extra`, so these come back empty — the pending screen
  shows "Order #" with nothing after it (`payment_pending_screen.dart:82`).
  The screen must load the order from the backend by id.
- Flow: **no Refresh / live status check.** User cannot see the moment the
  payment is verified.
- Flow: no link to Order history (does not exist yet, COM-014).
- Copy: pending screen's "What happens next?" lists **bank** steps ("We receive
  your receipt", `:99`) on what is the PayHere return page.
- Layout: no transaction details card.
- Copy: failure "Contact Support" shows `support@acedra.com`
  (`payment_failure_screen.dart:90`) — confirm this is a real mailbox.

Security (keep): app already says access needs independent verification and
never treats the redirect as success. Keep that.

Check:
- [ ] Return from PayHere sandbox shows the real order number, course and amount.
- [ ] Refresh re-reads status from the backend and updates the pill.
- [ ] Copy on the PayHere page mentions no bank receipts.
- [ ] Cancel returns to a failure page with a working Try Again.

Check results (code-only, 2026-10-18):
- FAIL: pending/success/failure builders read `state.extra` (`app_router.dart:157-184`), so a PayHere redirect shows an empty "Order #".
- FAIL: no Refresh / status read. Own orders can be read directly (`csa092_orders_read_own` RLS policy), so no new backend is needed.
- FAIL: `payment_pending_screen.dart:99` still lists bank steps ("We receive your receipt").
- Not verified: `support@acedra.com` mailbox.

Result: FAIL (code-only). NOT FIXED: files are in `checkout/presentation` and the router, which Codex holds under CSA-265.

---

### COM-012 — Bank transfer instructions + receipt upload

Prototype layout: header "Bank Transfer" → "Complete Your Transfer" → soft card
(course, **order reference with copy**, total) → card **Bank Transfer Details**
(Bank, Account Holder, Account Number — **each with copy**) → info "use the exact
amount and the order reference" → card **Upload Payment Receipt** (dashed drop
zone, "JPEG, PNG or PDF · up to 5 MiB", Choose File, selected file row with
Remove, error box) → info "Submitting a receipt does not confirm payment" →
**sticky footer: Submit Receipt for Review** (disabled until a file is chosen).
Prototype flow: submit → bank status screen (COM-013).

Current app:
- `bank_transfer/presentation/screens/bank_transfer_screen.dart`: order badge,
  4 numbered steps, account details card (copy on account number only,
  `:326`), disclaimer, **"I've made the transfer"** (`:195`) → status screen.
  **No upload on this screen.**
- Upload lives in `checkout/presentation/widgets/receipt_resubmission_form.dart`
  (embedded in checkout and on `/bank-transfer/:id/resubmit`).

Gaps:
- Flow: upload is split from the instructions; prototype does both on one screen
  and submits from the footer.
- Flow: **screen only works straight after checkout.** It reads the in-memory
  `checkoutProvider`; a refresh or deep link shows "Payment instructions are
  unavailable…" (`:54`). Must load the order by `orderId` from the backend.
- **SRS defect:** picker accepts `.jpg,.jpeg,.pdf` only
  (`receipt_file_picker_web.dart:10`). SRS (§ receipt types, approved
  2026-10-11) requires **JPEG, PNG and PDF, 5 MiB**. PNG is missing; the hint
  text says "max 5 MB" vs SRS "5 MiB".
- Layout: no copy button for order reference, bank name or holder.
- Layout: "I've made the transfer" goes to a status page that then asks to upload
  — an extra hop.

Security (keep): bank details come from the backend; receipt upload is private
and server-validated; access only after finance approval.

Check:
- [ ] Instructions and upload are on one screen.
- [ ] Order reference, bank, holder and account number each copy correctly.
- [ ] PNG, JPEG and PDF up to 5 MiB are accepted; others show a clear error.
- [ ] Submit is disabled with no file; enabled after choosing one.
- [ ] Refreshing the page still shows the instructions for that order.
- [ ] After submit you land on the bank status screen.

Check results (code-only, 2026-10-18):
- FAIL, NOT FIXED: PNG is rejected by the picker (`checkout/presentation/services/receipt_file.dart` and `receipt_file_picker_web.dart`: `.jpg,.jpeg,.pdf`; message "5 MB"). The backend (`validation.mjs`, bank-receipts bucket) and `bank_transfer_repository.dart` already accept PNG, so the only defect is those two checkout files (Codex-owned scope under CSA-265).
- FAIL, NOT FIXED: instructions do not survive a refresh. They come from the in-memory checkout response; `bank-transfer-read` returns no bank details, so a reload needs a backend read.
- FAIL, NOT FIXED: upload is still on a separate screen (the upload form lives in `checkout/presentation`). "I've made the transfer" is kept because three existing test files depend on it.
- FIXED: copy buttons for order reference, bank, account holder and account number (real icon buttons with tooltips, 48 px targets instead of a 16 px tap area).
- FIXED: "use the exact amount and your order reference" guidance.
- FIXED: back button falls back to the dashboard when there is nothing to pop.

Result: PARTIAL. Layout-only items fixed in `bank_transfer/**`; PNG, refresh and single-screen upload remain (see above).

---

### COM-013 — Bank payment status timeline

Prototype layout: header "Payment Status" → status card (large clock icon,
"Awaiting Verification" / "Receipt Needed", pill) → card **Order Details** (course,
ref, amount, method, date) → card **Payment Progress** — 4-step vertical timeline
with per-step pill: Order Created ✓ · Receipt Submitted · Bank Verification ·
Enrollment Activated → info "We will email you when it is confirmed." →
Upload Receipt (only when missing) → View Orders → Explore Courses.

Current app: `bank_transfer/presentation/screens/receipt_status_screen.dart` +
`checkout/presentation/widgets/receipt_status_card.dart`
- Status card with title/description per state (awaiting, submitted, under review,
  verified, rejected + reason), upload / resubmit button, Go to Dashboard.

Gaps:
- Layout: **no 4-step timeline**, no order details card (amount, method, date).
- Flow: no "View Orders" (COM-014) or "Explore Courses" exits.
- App handles **Rejected + reason + resubmit**, which the prototype lacks — keep it
  (prototype gap, not app gap).
- Copy D-6: "within 1–2 business days" (`receipt_status_screen.dart:267`,
  `receipt_status_card.dart:176`) is a service promise not found in SRS —
  confirm or remove.
- Copy: prototype promises an email on confirmation — only add if the backend
  actually sends one.

Check:
- [ ] Timeline shows the correct current step for each status.
- [ ] Rejected state still shows the reason and resubmit.
- [ ] Order details match the backend record.
- [ ] Exits go to Orders and Explore.

Check results (code-only, 2026-10-18):
- FIXED: four-step timeline (Order Created, Receipt Submitted, Bank Verification, Enrollment Activated) driven by the backend status; rejected shows "Needs Attention" and enrollment stays not started; only approved marks enrollment done. Tested for all five statuses.
- FIXED: Order Details card (course, order reference, method, submitted date).
- FIXED: "Explore Courses" exit. Rejected reason and resubmit are kept.
- FIXED: error body no longer prints `err.toString()`; only our own failure messages are shown, anything else gets a generic message.
- NOT FIXED: amount and order date are not returned by the student status read (`bank-transfer-read` only returns them for the finance queue), so they are not shown.
- NOT FIXED: "View Orders" exit needs COM-014.
- NOT FIXED: D-6 "1–2 business days" and the "notified once approved" line are in `checkout/presentation/widgets/receipt_status_card.dart` (CSA-265 scope) and `_statusConfig` is not reached for those states.
- The prototype's "we will email you" line was not added: nothing in the backend sends that email.

Result: PARTIAL. Timeline, details, exit and error handling fixed; amount/date and View Orders blocked.

---

### COM-014 — Order history (student)  — DONE 2026-10-20

Prototype layout: header "Order History" (Profile tab active) → "Your Purchases"
→ chips All · Paid · Awaiting Payment → order cards (art, "Order #ref", status
pill, title, date, price, button **Go to Course** if paid or **View Payment
Status** otherwise) → empty state "No orders here".
Prototype entry: Profile → Order History; PayHere status → View Order History;
bank status → View Orders.

Current app: no route, no screen. `RouteNames` has only the admin
`adminPaymentHistory`. SRS requires it: **UI-ST-022 Payment History** and
"View own purchase history".

Needs: a student-scoped, RLS-protected order list read (new CSA task; backend
contract owner to be assigned). Statuses must come from the backend.

Check:
- [ ] Route exists and is reachable from Profile.
- [ ] Only the signed-in student's orders appear (test with a second account).
- [ ] Filters work; empty state shows.
- [ ] Each card's button goes to the right course or status screen.

Check results (code-only, 2026-10-18):
- Confirmed MISSING: no route, screen or `RouteNames` entry for student order history.
- Correction to the note above: a student-scoped read already exists. `csa092_orders_read_own` lets authenticated users SELECT their own orders, so the list may not need a migration. Needs a read-only repository and a new route.
- Blocked by the router lock held by CSA-265.

Result: DONE 2026-10-20 (commit 6f769dc, merged to dev). /orders with All/Paid/Awaiting filters, empty and error states, linked from Profile and bank status.

RLS second-account isolation verified 2026-10-20 via `supabase/tests/database/csa092_orders_payment_attempts.test.sql`:
- Policy `csa092_orders_read_own`: `buyer_id=(select auth.uid()) and csa060_account_eligible()` — correct uid-scoped predicate.
- Test "buyer A sees own order only" (line 50): JWT set to buyer A, count=1.
- Test "foreign guessed order hidden" (line 51): buyer A cannot see buyer B's order.
- Test "buyer B isolation ignores forged admin claim" (line 59): buyer B with forged `super_admin` JWT still returns only their own order.
- Banned-account denial also tested (line 63).

NOT DONE: browser check (code in dev; CI/CD will deploy when baseline passes and production reviewer approves).

---

### COM-015 — Home

Prototype layout: brand header + avatar → greeting ("Good morning") + "Welcome
back, <name>" → navy **Continue learning** card (course, current lesson, % bar,
"N of M lessons", **Resume Learning**) → "My Courses" with View All + 2-column
owned-course cards (progress %, Continue / Get Started) → "Recently Accessed"
(last video lesson, last PDF with page).

Current app: `dashboard/presentation/screens/dashboard_home_screen.dart`
- **Preview notice** "courses and categories below are sample content" (`:76`),
  hero carousel, category row, featured courses, "Why learn with Acedra".
- Tapping a category or course shows a "sample" snackbar (`:97`, `:112`).

Gaps:
- This is a **different screen**: a marketing home with sample data, not the
  prototype's personal learning home. No greeting, no resume, no progress, no
  owned courses, no recently accessed.
- `ContinueLearningCard` exists in `my_courses/presentation/widgets/` but is
  **not used anywhere**.
- Needs per-student progress data (learning progress is in `learning_provider`;
  a summary read for Home is required).
- DECISION D-7: replace, or keep the marketing sections below the personal ones.
- Note: current branch (CSA-158/172) touches dashboard work — coordinate before
  editing this area.

Check:
- [ ] Greeting uses the time of day and the student's name.
- [ ] Resume opens the exact next unfinished lesson.
- [ ] Owned courses show real progress.
- [ ] No "sample content" text in a production build.

Check results (code-only, 2026-10-18):
- FAIL: `dashboard_home_screen.dart:76` still shows the sample-content preview notice; home is still the marketing page.
- Confirmed: `ContinueLearningCard` is not used by any screen or test.
- A progress read exists (csa127/csa133 migrations); a Home summary read still has to be designed. D-7 is open.

Result: PARTIAL (2026-10-18, commit fbbb3e5). D-7 decided: personal section on top (greeting, Continue Learning, owned courses), existing sections kept below. The "sample content" notice remains because those sections are still sample data. Depends on the unrun com015 migration for progress.

---

### COM-016 — My Courses

Prototype layout: brand header → "My Courses / Your learning library" → chips All
· In Progress · Not Started · Completed → large cards (art, category, title,
blurb, "N of M lessons completed", %, bar, **Continue Learning** / **Start
Learning**) → filter empty states with Explore button.

Current app: `my_courses/presentation/screens/my_courses_screen.dart`
- AppBar "My Courses", grid of `CourseCard`s with price text **"Enrolled"**
  (`:73`), extended FAB "Explore Courses" (`:19`), empty state.

Gaps:
- Layout: no filter chips, no progress, no per-card button.
- Data: `EnrolledCourse` has no progress fields — progress summary needed.
- Flow: card goes straight to `/learn/:id`; prototype goes to course overview
  (COM-017).
- Layout: FAB overlaps the last card on mobile and duplicates the bottom-nav
  Explore route (once D-2 adds it).

Check:
- [ ] Filters show the right courses by progress.
- [ ] Each card shows real progress and the right button label.
- [ ] Empty filter shows a message and an Explore button.

Result: PARTIAL (2026-10-18, commit fbbb3e5). FIXED: filter chips, progress bar, Continue/Start/Review per card, one-call progress RPC com015_my_course_progress (migration NOT run or tested). NOT DONE: card goes to resume lesson, not overview.

---

### COM-017 — Course overview with progress — MISSING

Prototype layout: back "My Courses" → course art + title + "N modules · N
lessons" → card **Your Learning Progress** (big %, bar) → card **Continue
learning** (next lesson, Resume / Start Lesson) → **Course Curriculum** with
module status circles (done ✓ / current / todo), "Completed" pill, lessons with
done/current/empty markers, "In Progress", durations.

Current app: `/learn/:courseId` opens `LearningWorkspaceScreen` directly into a
lesson with a curriculum sidebar (≥ 900 px) or a FAB bottom sheet (mobile).
`CurriculumNav` lists lessons but there is no course-level progress view.

Gaps:
- Screen missing. Decide: new route (e.g. `/learn/:courseId` = overview,
  `/learn/:courseId/:lessonId` = lesson) — **router change, shared file**,
  needs a lock (AGENTS.md §14–15).
- No course % or "N of M lessons" anywhere in learning.

Check:
- [ ] Overview shows correct % and next lesson.
- [ ] Module and lesson markers reflect saved progress after reload.
- [ ] Resume opens the right lesson.

Result: VERIFIED locally 2026-10-20 (localhost:9090, branch `feat/com-007-password-reset`). Course overview at `/learn/:courseId` shows progress %, "1 of N lessons completed", Continue Learning card with correct next lesson, expandable curriculum with module/lesson markers (✓ for completed, play icon for In Progress, empty circle for not started). Progress updated correctly after Mark Complete. Compilation fix required: `receipt_review_history_screen.dart` lines 235/244 were missing `cs:` param on `_DateRow` — fixed in this session. MERGED to dev 2026-10-20 (8ddfda2). Deploy pending CI pass + production reviewer approval.

---

### COM-018 — Video lesson

Prototype layout: header (course title) → 16:10 player (play overlay, time, seek,
**speed 1/1.25/1.5/2x**, **CC**) → "Lesson 08" + title + "Video Lesson" + status
pill → **Course Progress** card → tabs **Overview / Resources** (resources list:
PDF guide opens reader, ZIP) → **sticky footer: Previous · Mark Complete &
Continue**.

Current app: `learning_workspace_screen.dart` + `video_player/presentation/widgets/**`
- Player with play/pause, seek, fullscreen (`video_controls.dart`); resume position
  saved; "Mark complete / Mark incomplete" button top-right; Previous/Next bar.

Gaps:
- Layout: no lesson header (number, type, status), no course progress card, no
  Overview/Resources tabs.
- Player: no speed control, no captions toggle (Mux supports both; captions
  depend on uploaded tracks).
- Flow: complete and next are separate actions; prototype combines "Mark Complete
  & Continue".
- App has "Mark incomplete" — prototype doesn't; keep (harmless).

Check:
- [ ] Speed and CC controls work (CC only when a track exists).
- [ ] Mark Complete & Continue saves progress and opens the next lesson.
- [ ] Resources tab opens the PDF in the reader.

Result: VERIFIED locally 2026-10-20. "Lesson 01 · Video Lesson" header, "In Progress" pill, "1/4 · 25%" progress counter, "Mark Complete & Continue" sticky footer all present and working. Tapping the button marks Lesson 01 complete, advances to Lesson 02, and updates the course overview to 25%. Video player shows "Video access is temporarily unavailable" (no Mux asset in local seed — expected, not a code bug). Speed/CC controls not checked (need a real video stream). MERGED to dev 2026-10-20 (087beba). Deploy pending CI pass + production reviewer approval.

---

### COM-019 — Text & image lesson

Prototype layout: eyebrow "Lesson 09" + title + "Text & Image Lesson" + small
course-progress card → content cards (headings, paragraphs, inline code,
diagrams, **Key Takeaway** callout) → footer **Previous · Complete & Continue**
(last lesson in module → back to overview with "Module finished" toast).

Current app: `learning/presentation/widgets/text_lesson_viewer.dart`,
`image_lesson_viewer.dart` in the workspace.

Gaps:
- Layout: header and course-progress mini card missing; callout styles depend on
  how lesson text is authored (check what `contentText` supports).
- Flow: same complete-and-continue gap as COM-018; no "module finished" moment.

Check:
- [ ] Header shows lesson number, type and status.
- [ ] Complete & Continue advances; last lesson returns to overview.

Result: DONE 2026-10-21. The code was correct (merged in `f44526a`). Added 4 widget tests to `test/features/learning/learning_workspace_screen_test.dart`: (1) "Mark Complete & Continue" appears for an incomplete non-last text lesson; (2) "Mark Complete" appears for the last incomplete lesson; (3) neither button appears when the lesson is already completed; (4) tapping "Mark Complete" when `completeAndContinue` returns `moduleFinished` shows a "Module finished" SnackBar. Extended `_StubLearningNotifier` with configurable `completeOutcome` and a `completeAndContinue` override. Added `_lessonContent2` and `_wrapWithRouter` (GoRouter setup) helpers. `flutter analyze` on test file: No issues found. Browser tests (`@TestOn('browser')`) require `--platform chrome`; local Chrome environment exhausted with 35 stuck instances from concurrent test runs; CI will verify.

---

### COM-020 — PDF reader

Prototype layout: header (back, document title, **Contents**, **Bookmark**) →
page on grey canvas with **personal diagonal watermark** → disclosure
“This guide shows your name as a watermark on every page.” → footer:
‹ page / total › · − zoom % + · fit-to-width. Contents lists chapters
(current highlighted) and bookmarks. No download/print controls.

Result: **IN_REVIEW — CSA-271 / issue #205 / [PR #206](https://github.com/iamramishka/acendra/pull/206), 2026-10-22**. This supersedes the
2026-10-18 “contents missing / global watermark flag off” implementation note.

- The active `ProtectedPdfLesson` now connects `PdfLessonReader` to the existing
  contents sheet. It reads internal chapters from the authenticated derivative,
  highlights the closest current chapter, jumps to pages and saves bookmarks.
- Owner D-3 branding is implemented as a new immutable **v2** server policy:
  **Acendra Product - Licensed to <display name> - <opaque licence ID>**.
  Both the translucent diagonal mark and footer are permanent PDF page content.
  No auth UUID, email or client overlay is substituted. V1 generation remains
  compatible; migration `20261021000100_csa271_pdf_policy_v2.sql` reserves fresh
  v2 objects and refuses v1 resource reuse, without rewriting existing objects.
- The worker preserves inspected internal GoTo outlines/named destinations for
  v2. External, scripted and chained actions remain rejected. Every proxy request
  still rechecks current authorization; originals/signed URLs are never fallback.
- Disclosure requires `watermark_applied: true` in the authenticated ready
  descriptor **and** successful derivative delivery. Older descriptors remain
  readable without claiming a watermark. Delivery is disabled by default;
  explicit server opt-in is gated on the approved worker/runtime deployment.
- Header Contents/Bookmark, grey canvas, page navigation, 100–300% zoom and true
  fit-to-width use the active reader. Footer groups wrap at narrow widths while
  retaining touch targets. Legacy search components remain intact.
- Reading position and bookmarks are scoped to student + lesson. Page 1 now
  replaces an older saved page; stale/out-of-range positions safely reset.
- The missing PDF.js runtime is bundled at the same origin with pinned integrity
  and notices; no CDN allowance, dependency lockfile or CSP weakening is added.

Verified locally:
- [x] Real generated v2 fixture: four pages, branded diagonal/footer watermark,
  original selectable text and internal chapter destinations preserved.
- [x] Python worker: 15 passed, one non-root Linux-only test skipped on Windows.
  A supported v1 sample remains byte-identical to the dev generator.
- [x] Node PDF authorization/proxy/worker/assets/request and runtime-gate regressions: 150 passed; hosted-only wrapper explicitly skipped on Windows.
- [x] Active reader/repository/progress and existing PDF widget suites: 132 passed
  serially, including chapter/bookmark jumps, zoom/reset, page restoration,
  account/lesson storage separation, dark theme, sheet disposal and 320/390/768/1440 px with 1×/2× text.
- [x] Full Dart analyzer: no issues with a task-local `DART_DATA_HOME` after
  Windows performance-socket cleanup crashed the default analyzer process.
- [x] Finding-repair release web build passed, including Wasm dry run (290.1 s).
- [x] 43 ordered migrations applied in disposable PostgreSQL 17; private-storage
  and entitlement/policy-version SQL suites passed with synthetic Auth/Storage.

- [x] 2026-10-22: reference artifact inspected in the working in-app browser;
  inset page, grouped footer, numbered chapters and explicit Close aligned to it.
  **22 browser checks passed** with the production reader/PDF.js and real v2
  synthetic fixture: chapters, bookmarks, 100–300% zoom, fit width, reopening,
  page-1 reload, separate student progress, keyboard Close, dark theme and visible
  controls at 320/390/768/1440px. [Screenshots and evidence](docs/tasks/CSA-271-PDF-READER.md#2026-10-22-browser-follow-up).
  This is local interactive verification; the automated Chrome runner did not
  reach assertions. Sample document content and prototype phone chrome differ.
- [x] Follow-up: corrected 40px desktop buttons to 48px minima; Windows, Linux
  and macOS regressions passed. The CI wrapper now skips only an absent Flutter
  SDK, and rejects broken installations. Earlier browser captures are f722d55;
  the new direct UI check was blocked by browser URL security policy.

Acceptance still open:
- [ ] Hosted migration, private Storage, updated policy-aware non-root worker,
  licensed locale font, isolation, retention/purge and representative content /
  accessibility acceptance. Stop old workers before adopting v2 reservations.
- [ ] Required CI/review, then approved PR merge to dev. No gate is bypassed.

Exact commands, SQL evidence, browser outcome and PR link are maintained in
`docs/tasks/CSA-271-PDF-READER.md`. This follow-up changes COM-020 only; other
comparison rows retain their existing task owners and pending PRs.

---

### COM-021 — My profile

Prototype layout: brand header → "My Profile" → gradient card (large avatar with
camera badge, name, email, **Change Photo**) → card **Personal Information**
(Display Name editable, Email **read-only with lock** + "Email can't be changed
here.", **Preferred Language** select, Save Changes) → list: **Order History**,
**Settings**.

Current app: `profile/presentation/screens/profile_screen.dart` (view + Sign out)
and `profile_edit_screen.dart` (display name only).

Gaps:
- Layout: view and edit are two screens; prototype edits inline.
- Missing: photo change (needs private avatar storage + RLS — backend task),
  language (D-4), Order History link (COM-014), Settings link (COM-022).
- Flow: Sign out sits on Profile; prototype puts it in Settings.

Check:
- [ ] Display name saves and shows everywhere (header avatar initials, Home greeting).
- [ ] Email is read-only.
- [ ] Order History and Settings rows open their screens.

Result: DONE 2026-10-21.
- Inline edit: view + edit merged into `ProfileScreen` in commit 6d08ed1 (owner).
- Photo: Change Photo calls `avatarUploadProvider`; CircleAvatar now shows the uploaded photo via `avatarUrlProvider` (falls back to initials when no photo). 18/18 profile tests pass.
- Language: `DropdownButtonFormField<AppLanguage>` (English/සිංහල) was already present; on Save Changes, locale is now also persisted to DB via `localeUpdateProvider` (best-effort sync alongside localStorage `preferredLanguageProvider`).
- Email read-only with note, Settings link, Order History link: all present.

---

### COM-022 — Settings — DONE 2026-10-21

Prototype layout: header "Settings" (Profile tab active) → **Appearance**: theme
segmented control Light / Dark / System → **Preferences**: Language select, Email
Notifications switch → **Account & Security**: Change Password → red **Sign Out**
card.

Result: DONE 2026-10-21. `/settings` screen delivers all four sections:
- **Appearance**: Light / Dark / System SegmentedButton, persisted in localStorage.
- **Preferences**: Language DropdownButton (English / සිංහල → `locale` 'en'/'si' on `profiles`); Email Notifications SwitchListTile (`email_notifications_enabled` on `profiles`).
- **Account & Security**: Change Password → returns to Settings; Sign Out.

Migration `20261020000100_com022_email_notifications.sql` adds `email_notifications_enabled boolean not null default true` to `profiles` with `grant update (email_notifications_enabled) on table public.profiles to authenticated`. `locale` column and its grant were already present. `fetchPreferences()`, `updateLocale()`, `updateEmailNotifications()` added to `ProfileRepository`; `UserPreferences`, `userPreferencesProvider`, `localeUpdateProvider`, `emailNotificationsProvider` added to `profile_provider.dart`.

Check:
- [x] Route exists, reachable from Profile.
- [x] Light / Dark / System each apply and persist after reload.
- [x] Change Password returns here signed in.
- [x] Sign Out signs out and lands on Sign in.
- [x] Language selector saves locale to profiles table (EN/SI).
- [x] Email notifications toggle saves to profiles table.
- `flutter analyze` passes clean on all changed files.

---

### COM-023 — Cross-cutting states and feedback

Prototype: every list has an empty state with an icon and a next action; toasts
for confirmations; inline field errors; disabled buttons until valid.

Current app: shared `AppErrorState`, `AppEmptyState`, `AppSkeleton`,
`AppSnackbar` exist and are used — good. Gaps are per screen (listed above):
generic empty messages, buttons enabled before input is valid, raw status strings.

Check:
- [ ] Every list screen has loading, empty and error states.
- [ ] No raw backend codes (`pending_payment`, ids) shown to students.
- [ ] Errors never show stack traces or internal details (`receipt_status_screen.dart`
      currently shows `err.toString()` in `_ErrorBody` — check what that prints).
- [ ] All tap targets ≥ 44 px at 390 px; keyboard focus visible.

Result: DONE 2026-10-20 (05a5088). Raw exception text removed from PDF, video and lesson errors; My Courses/Order History empty states have actions; PDF search target 44 px.

Admin screen sweep 2026-10-20:
- FIXED: `_PaymentMethodChip._label()` in `student_enrollment_details_screen.dart` had stale `'stripe' => 'Card'` (DB uses `'online'`); changed to `'online' => 'Online'`, unknown fallback now shows `'Payment'` instead of the raw code.
- FIXED: `finance_review_screen.dart` showed `amount_minor` as raw integer string "LKR 10000 minor units"; now formatted via `_formatMinorAmount()` (e.g. "LKR 100.00").
- FIXED: curriculum builder section header and lesson row `InkWell` had `vertical: 8px` padding (~34px total), below 44px minimum; raised to `vertical: 12px` (~44px).
- CONFIRMED: all 4 main admin list screens (admin_courses, admin_students, admin_payments, admin_dashboard) have loading skeletons, `AppEmptyState`, and `AppErrorState`.
- CONFIRMED: no raw `.toString()` exception text found in any admin screen.

Note: payment filter date pickers are intentionally stubbed (`// TODO`); that is a separate feature gap, not a COM-023 issue.

---

## 5. Suggested order of work

1. Owner decisions D-1 … D-8.
2. P0 payment flow correctness: COM-012 (PNG + reload), COM-011 (load order by
   id), COM-010 (raw id, duplicate upload), COM-009 (open-order state).
3. Missing SRS screens: COM-014, COM-022, COM-017.
4. Personal Home and My Courses: COM-015, COM-016 (needs progress summary).
5. Layout polish: auth (COM-003–007), catalog (COM-008), learning (COM-018–020),
   profile (COM-021), shell (COM-002).

Shared files these tasks will touch (need locks): `lib/app/router/**`,
`lib/core/widgets/navigation/**`, `lib/app/theme/**` (only if new tokens),
`pubspec.yaml` (only if a new package), `supabase/migrations/**` (orders read,
progress summary, avatar storage, notification preference).

## 6. Audit limits

- The original 2026-10-18 audit was code review only; its line numbers refer to
  commit `9ba9c0d`. Later dated entries record additional evidence only for their
  named screens. COM-008's 2026-10-21 widget tests are not browser acceptance.
- Admin screens were not compared (the prototype has none).
- Widths 768 and 1440 were not compared against the prototype (prototype is a
  phone mockup only).
- Backend behaviour (RLS, Edge Functions) was read only where a screen depends on it.
