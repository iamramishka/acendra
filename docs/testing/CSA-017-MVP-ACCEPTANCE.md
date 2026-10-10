# CSA-017: MVP acceptance test strategy

Owner approval recorded 2026-10-11 (Asia/Colombo): the project owner replied "go ahead" after these six reviews were presented. This accepts the documentation baseline and authorizes merge; runtime, legal/processor, provisioning and production gates remain unverified. See [approval and completion record](../requirements/CSA-011-017-APPROVAL.md). Earlier proposal/pending wording below describes preparation or retained downstream conditions, not a missing owner decision.

Date: 2026-10-11 (Asia/Colombo). Status: APPROVED strategy - owner accepted 2026-10-11; tests unexecuted.
Owner: CODEX coordinator. Base: origin/dev e1cf11f.
Branch: codex/docs/csa-017-phase0-review.
Worktree: C:/Users/ramis/.codex/worktrees/csa-017-phase0/acendra.
Scope: this document only. Runtime tests and CI are later implementation tasks.

## Acceptance authority and baseline

Use approved SRS 1.1, the CSA-001/002 MVP acceptance baseline, CSA-003 roles,
CSA-004 PayHere/LKR, CSA-005 bank policy, CSA-006 lifetime/refunds and CSA-010
authenticated personalized PDF proxy. They were merged in PRs #1 through #5;
do not reopen or replace them with mocks or proposed generic defaults.

Retain every MUST requirement and AT-001 through AT-014. Existing SHOULD
requirements remain deferred unless promoted by the owner. This document turns
those obligations into test packages; grouping never waives individual clauses.
The detailed standards remain [docs/TESTING.md](../TESTING.md).

Approval of this strategy establishes how acceptance will be demonstrated,
not that the software passed. The project lead accepts the strategy and release
evidence; named human reviewers assess finance/security, privacy and accessibility.
The implementer cannot describe self-review as independent approval.

## Test layers and execution order

1. For each critical invariant, write a failing domain/database test, implement
   minimally, refactor and rerun. Test meaningful behavior, not generated code shape.
2. Run unit/widget tests for domain behavior, routing, semantics and state feedback.
3. Test migrations, grants, RLS and privileged operations on an isolated local
   Supabase database with actual anonymous/student/staff credentials. Never use
   service-role credentials to assert student access rules.
4. Test trusted Edge/API operations with deterministic signed synthetic events,
   failure injection and concurrent independent sessions. Mocked provider tests
   supplement but cannot replace sandbox proof of the real verification flow.
5. Run integrated web journeys against isolated staging with approved provider
   sandbox accounts and synthetic bank evidence, media and identities.
6. Before release, assess supported browsers, accessibility, representative load,
   revocation, private-cache behavior, backup restoration and operational recovery.

Use the repository's Flutter testing tooling and proposed pgTAP/Deno layers
from TESTING.md. Selecting/installing a browser automation framework is a later
coordinated tooling task; no dependency or CI configuration is added here.

## Synthetic fixture and actor matrix

Fixtures: guest; students A and B; suspended student; content managers assigned
to separate courses; finance reviewer F and alternate F2; super admin S; revoked
staff role with an older valid JWT. Staff purchases follow student rules.

Courses: public published, draft, unpublished with existing purchases; video,
text, image and PDF lessons; immutable PDF versions with dense/scanned/rotated
pages. Grants: none, valid paid lifetime, revoked, expired complimentary,
independent admin grant plus refunded purchase, broader account/course restriction.

Orders: exact LKR amount, payable, pending verification, paid, cancelled, refunded;
bank credits with reusable student reference but distinct trusted settlement IDs;
same trusted settlement submitted to two orders. Receipts: valid JPEG/PNG/PDF at
the limit (5,242,880 bytes), one byte over, spoofed type, malformed/encrypted/unsafe,
abandoned object and cross-user object association. Use no real financial data.

Each task has its own local database/project namespace, ports, storage prefix,
test accounts and fixture output. Separate worktrees alone do not isolate remote
state. Deterministic IDs and a controlled clock support deadline/race tests.
Cleanup must check environment identity and delete only the task's synthetic data.

## Acceptance packages

All packages below are NOT_IMPLEMENTED as acceptance suites in this task; existing
foundation unit tests are not end-to-end evidence. Owners are proposed functional
responsibilities, not invented GitHub assignments. Backend owner covers security
assertions; frontend owner covers interaction; integration owner owns joined proof.

| ID / risk | SRS trace / original acceptance | Required assertions and evidence | Primary layer / proposed owner |
| --- | --- | --- | --- |
| AC-01 / P1 | MUST FR-AUTH, FR-PROFILE; AT-001 | Register, verification, login, logout, password recovery, errors and own-profile changes; no credential disclosure; deny profile B and role-field injection | Auth integration + RLS / backend and frontend |
| AC-02 / P1 | MUST FR-CAT; MVP-AC-02 | Published listings show all required metadata; search/filter and owned indication correct; direct draft metadata/lesson requests disclose nothing | Widget + API + browser / marketplace |
| AC-03 / P1 | MUST FR-COURSE; MVP-AC-03 | Assigned content managers author/reorder all four lesson types only in assigned courses; only super admins change price/publish/archive; unpublish preserves purchases and deletion preserves financial history | API/RLS + browser / admin |
| AC-04 / P0 | MUST FR-CHECKOUT; BR-016 | One course/order; immutable backend amount/LKR and official bank destination; tampered price/currency/course denied; idempotent retries and visible recovery | Domain/database + integration / commerce |
| AC-05 / P0 | MUST FR-PAY; AT-003, AT-004, AT-005 | PayHere sandbox success verifies documented checksum plus merchant/environment/order/amount/currency/reference association; grants exactly once; redirect grants nothing; changed unsigned payment_id cannot authorize an unrelated order | Edge + database + sandbox / payments |
| AC-06 / P0 | FR-PAY-008/009/010; NFR-REL-001/002/003; AT-014 | Duplicate/concurrent/delayed/out-of-order events, failure/cancel/pending, callback vs bank approval produce one legal fulfillment; unknown outcomes remain pending; joined checkout/status UI shows recoverable failure without unlocking; injected payment/grant/audit failure rolls back all writes | Concurrent DB/API + recovery / payments |
| AC-07 / P0 | MUST FR-BANK; AT-006 | Valid private receipt creates pending state without access; boundary sizes/types/signatures/unsafe files checked; cross-user download/list/path/overwrite denied; rejected evidence retained and eligible resubmission creates new evidence | Storage/RLS + API + browser / bank |
| AC-08 / P0 | MUST FR-APAY; FR-BANK-009..018; AT-007, AT-008 | Independent settled bank credit matches exact destination/amount/currency/order; student direct approval, own-purchase approval and revoked role denied without financial mutation; audit/review/grant atomic; one credit cannot fund two orders; opposing/replayed reviews resolve safely | DB + MFA/API + finance journey / bank |
| AC-09 / P0 | MUST FR-ENROLL; AT-002; BR-001/009/010 | Every direct content request checks current actor/course/resource/grant/restrictions; missing/wrong-course/expired/revoked access denied; source/audit recorded; paid grants have no scheduled expiry | RLS + API/storage negative suite / entitlements |
| AC-10 / P0 | CSA-006; FR-ENROLL-010; NFR-REL | Request cutoff at first fulfillment +168h, exactly at boundary accepted; +1 tick enters exception channel; client time/retry cannot extend; request/rejection/approval do not revoke; confirmed refund invalidates only funding grant; independent valid grant survives | Controlled-clock domain + transaction/API / refunds |
| AC-11 / P0 | CSA-006; FR-PAY/ENROLL; NFR-REL | Ambiguous payout reconciled before retry; duplicate refund confirmation cannot double-pay; refund/repurchase races and late callbacks cannot revive invalidated grants; trusted dispute opens source restriction, student allegation alone cannot restrict, reversal invalidates source without fabricated refund, and restoration never overrides another restriction; notification failure preserves committed state | Failure-injected integration / refunds |
| AC-12 / P1 | MUST FR-LEARN/VIDEO/TEXT/IMAGE; MVP-AC-08; AT-013 | Entitled navigation, all lesson types, required player controls, readable text/images, progress/completion/resume; A cannot read/write B's progress; network errors recover safely | Widgets + database + browser / learning |
| AC-13 / P0 | FR-VIDEO-006/007; AT-002 | Backend scoped token issue denies guest/B/revoked grant; direct playback not public; measure expiry, refresh, seek and revocation replay window; vendor origin checks alone cannot authorize; document delivered-byte limitation | Actual provider PoC + API / video |
| AC-14 / P0 | MUST FR-PDF-SEC; AT-009, AT-010; CSA-010 | Private original/derivative bypass denied; personalized bytes have correct user's readable mark every page; no cross-user cache; descriptor/full GET/HEAD/range/conditional requests reauthorize; validators/304 cannot bypass checks; no Storage redirects or student signed-download URLs; failed derivative never serves original; new request after revocation denied absent surviving grant; already delivered bytes not recalled | Storage/API + rendered output + browser / PDF |
| AC-15 / P1 | MUST FR-PDF; AT-009, AT-011 | Page/zoom/fit/scroll/expanded view/progress work; authenticated immutable 200/206/416 range handling, renewal/preparing/retry; no fallback to original on failed transformation; theme does not damage source page readability | Viewer integration + representative files / PDF |
| AC-16 / P0 | MUST FR-ADMIN/STUDENT; AT-008; CSA-003 | Role-filtered dashboard aggregates, related-payer-only finance lookup, assigned authoring and least privilege; deny self-role/self-grant, last-admin removal, finance curriculum changes; live role revocation applies despite valid older JWT; production privileged MFA enforced | RLS/grants + direct API + browser / authorization |
| AC-17 / P1 | MUST FR-NOTIFY; MVP-AC-11 | Email verification and bank approve/reject notices agree with committed status; safe student reasons omit internal notes; outbox retry observable without duplicate financial writes or receipt attachments | Worker integration + email sandbox / notifications |
| AC-18 / P1 | MUST NFR-UX/RESP/ACC; AT-011, AT-012 | Both themes at 320/390/600/768/1024/1440 and breakpoint ±1 widths; loading/error/empty/success, validation, keyboard/focus/names/contrast/non-color status, reachable actions and no unintended horizontal overflow; manual screen-reader assessment for key journeys | Widget + real browser + manual / frontend QA |
| AC-19 / P0 | MUST NFR-SEC; MVP-AC-12 | HTTPS, input/rate limits, RLS and grants on protected exposed tables, no raw card/server secrets, redacted logs and error responses; malicious upload and direct unauthorized request suite; required human review | Build/log inspection + DB/API negative suite / security |
| AC-20 / P0 | MUST NFR-PRIV; FR-PDF-SEC-008; CSA-015 proposal | Minimal data, role-restricted receipts, published privacy and watermark notice, no hidden monitoring; approved retention/deletion/hold procedures tested including derivatives/logs/backups; processor terms/regions/optional analytics and age/territory gates reviewed; copyright provenance and capture limits disclosed | Policy evidence + privacy integration / privacy reviewer |
| AC-21 / P1 | MUST NFR-PERF; NFR-PERF-003/004 proposed targets | Pagination/lazy assets/resolution limits; instrument representative browser/network/files/concurrency, p95 catalog and PDF first-page performance; record memory/egress/runtime regressions; targets become gates only after owner workload approval | Load + measured browser / performance |
| AC-22 / P0 | MUST NFR-REL; MVP-AC-12 | Network/retry recovery, transactional integrity, backup and isolated restoration; verify private object/content/financial/audit completeness, replay deletion ledger before restoring service, reconcile provider events after recovery; named incident responders/tabletop cover signing-key exposure and receipt disclosure; approved RPO/RTO measured and monitoring/alerts demonstrated | Failure/recovery exercise / operations |
| AC-23 / P1 | MUST NFR-MAIN; MVP-AC-12 | Feature boundaries, format/analyze/test/build, documented architecture/dependency justification, reviewed PR and traceability; preserve regression tests, no security waivers | Repository/CI review / integration |

For each MUST identifier, implementation PRs must add a named executable case or
manual evidence item in its package. Release reconciliation compares that ledger
against the approved SRS: any unmapped MUST or unexecuted mandatory case blocks
acceptance. Business rules BR-001..016 and AT-001..014 are checked in addition to
functional IDs. Copying a family label is not execution or coverage evidence.

## Browser, accessibility and quantitative proposals

Propose Chrome, Edge, Firefox and Safari stable/current previous major desktop
versions, Android Chrome and iOS Safari on representative devices. Record actual
tested browser/OS/device versions at execution; emulator-only checks cannot prove
mobile Safari playback. Owner must approve the support matrix (SRS DEC-012).
Run key registration, checkout, finance, video and PDF flows with keyboard and
screen reader. DS-AC refinements from CSA-014 are pending proposals and must be
reconciled before tests adopt them. Honor approved NFR-ACC requirements; document
PDF accommodation process and any unsupported interaction honestly.

Use the existing proposed 90% critical-domain and 80% general-business statement
coverage targets in TESTING.md for review, with meaningful transition/error branch
coverage. They do not replace invariant tests or establish achieved percentages.
SRS p95 catalog <1s and first PDF page <4s are provisional SHOULD targets, not
invented mandatory SLAs. Owner must approve representative files/page counts,
networks, concurrent users, recovery targets and accessibility acceptance process
before release. No unspecified threshold is treated as a pass.

## Gates, evidence and defect handling

Planning exit: approve strategy, assign actual suite owners, resolve required
contracts and test inputs. PR gate: scoped format/analyzer/unit/widget checks;
database/API negative and concurrency tests for relevant critical changes;
required security reviewer; include commit, environment and result artifacts.
Integration gate: use combined accepted revision, isolated staging and actual
sandbox integrations. Release gate: all approved MUSTs/ATs evidenced, zero
unresolved P0/security/financial blocker, required recovery/privacy/operational
evidence and authorized production acceptance. No average score waives a blocker.

Evidence record for each case: requirement/case ID, actor and fixture, code SHA,
browser/runtime version, environment, command or manual steps, expected/actual
assertions, timestamp, status, redacted artifact and reviewer. Use TESTING.md
statuses NOT_IMPLEMENTED/READY/RUNNING/PASSED/FAILED/BLOCKED/SKIPPED/FLAKY.
Archive redacted reports for a proposed 90 days, subject to CSA-015 retention
approval; never include tokens, raw receipts, private paths or customer data.

Failed critical assertions block integration. Flaky mandatory tests require
investigation; rerunning until green or quarantine cannot count as a verified
pass. Scope changes/exceptions require owner review and cannot waive AGENTS
payment/security invariants. A synthetic bank review proves software behavior,
not a real bank credit. Sandbox payment success proves sandbox integration,
not merchant activation or production authorization.

## Commands and present limitations

Run when the corresponding implementation/tooling exists in an isolated workspace:

```text
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
supabase test db
```

Execute configured Edge/API/browser suites using their documented runner once
created; do not claim a command for nonexistent harnesses. On base e1cf11f the
repository has foundation Flutter tests, but no supabase/, integration_test/ or
.github/ directory. Therefore actual RLS, financial, provider, browser E2E and
CI acceptance remain unimplemented/unverified. This task ran documentation
whitespace and traceability checks only; no runtime pass is claimed.

## Remaining decisions and handoff

- CSA-011/012: video provider, token/revocation PoC, staged environments and funded
  capacity; proposed vendor budget does not authorize spending.
- CSA-015: final retention, privacy publication, legal/commercial review and
  current threat-register mitigation evidence, not merely baseline approval.
- SRS DEC-010/012/015/017/018: workload, browsers, recovery, PDF benchmarks and
  accommodation. TEST-OPEN entries in TESTING.md stay open until evidence exists.
- Backend/commerce owners: finalize PayHere unsigned-reference reconciliation,
  sandbox access, bank safe inspection and stable settlement identity contracts.
- Integration owner: configure actual runners/CI, test report storage, support
  versions and a requirement-by-case evidence ledger before acceptance testing.

Next owner: project lead approves this strategy revision and assigns suite
implementation tasks. Acceptance of this document does not mark any acceptance
test PASSED, finish dependent implementation or authorize production launch.
