# CSA-001 / CSA-002: SRS review and MVP acceptance baseline

Date: 2026-10-11
Status: APPROVED baseline - project owner accepted on 2026-10-11; downstream gates retained
Reviewed baseline: SRS.md 1.0, PLAN.md, TASKS.md and repository security rules.
Result: SRS 1.1 is the approved requirements baseline with explicit downstream
gates. Product implementation and release have not been verified or approved.

## MVP scope

Retain every existing MUST functional and non-functional requirement. Deliver
Flutter Web authentication/profile, public catalog/search/category filtering,
course details and curriculum metadata, course checkout, PayHere/LKR payments,
independently verified bank transfers, backend entitlements, learning dashboard,
video/text/image/PDF lessons, protected watermarked PDF reading, progress,
role-limited course/student/payment administration, email notifications,
responsive light/dark UI, accessibility, security/audit/privacy and operational
release controls. Online payments and bank transfers are both in scope.

Existing SHOULD requirements are deferred unless explicitly promoted. Native
apps, subscriptions, multi-instructor selling, live classes, quizzes, graded
assignments, certificates, affiliates, AI assistants, gamification, advanced
recommendations, offline protected downloads and forums remain outside MVP.
Approved checkout boundary: one course per order; carts and bundles are deferred.

## Review findings and approved resolutions

| Finding | Resolution / approval boundary |
| --- | --- |
| RLS wording permits API-only protection | SRS baseline now requires enabled RLS and reviewed grants on protected exposed tables plus trusted API authorization, matching AGENTS.md |
| Dashboard list exposes financial aggregates ambiguously | SRS baseline explicitly requires backend role filtering of statistics |
| Content management does not state assignment scope | Baseline clarifies course-level authorization; detailed publishing/price authority follows the approved CSA-003 policy |
| Mandatory screen list conflicts with optional reports/preview | Approved: logical views may share routes; UI-AD-007/015 follow FR-COURSE-011/FR-APAY-008 SHOULD priority; mandatory operational statistics remain |
| Curriculum preview could imply free paid assets | Approved: public curriculum is approved metadata; playable free lessons remain optional under FR-CAT-012 |
| Generic resume MUST vs video timestamp SHOULD | Approved: last-opened lesson/completion and PDF page/position are MVP; video timestamp persistence remains SHOULD |
| Unpublishing vs existing purchases unspecified | Approved: stop public listing/new purchases; preserve existing entitlements unless separately revoked under approved policy |
| Bank duplicate-reference flag is optional | Mandatory settlement non-reuse invariant is stated in CSA-005; optional heuristics remain optional |
| State lists lack full transition/rollback contracts | CSA-005 specifies bank flow; provider refund/chargeback and entitlement transitions require CSA-006 approval before implementation |
| Notification delivery failure unclear | Approved: bank decisions appear in order status and generate email; failures are observable and never reverse committed payment/grant |
| DEC identifiers differ across documents | Use document-qualified references and crosswalk below; do not renumber historical identifiers |
| Performance/recovery language is not fully measurable | Approve browser, device/network/file/load fixtures and recovery targets before release testing; no invented SLA |

The accepted scope and policy resolutions are applied to SRS 1.1 and its linked
normative policy documents. Unspecified operational values remain gated; approval
does not invent those values or satisfy implementation tests.

## Acceptance matrix

Each row is a required future verification gate, not an executed test result.
Every MUST ID in each listed family remains binding, including requirements not
individually repeated in the summary. Before product acceptance, attach a
per-requirement implementation/test or review-evidence record for every MUST.

| Gate | SRS coverage | Observable acceptance evidence |
| --- | --- | --- |
| MVP-AC-01 Accounts | MUST FR-AUTH, FR-PROFILE | Registration/verification/login/logout/recovery/password changes work; expired sessions denied; cross-user profile access/write denied |
| MVP-AC-02 Catalog | MUST FR-CAT | Only published metadata via UI/direct API; search/category filter/details/owned state correct; no private lesson bodies/assets |
| MVP-AC-03 Authoring | MUST FR-COURSE | Authorized four-type curriculum editing/reordering/publishing; cross-course unauthorized writes fail; purchased access and audit history preserved under approved policy |
| MVP-AC-04 Checkout | MUST FR-CHECKOUT; BR-016 | Server amount/LKR authoritative and immutable; tampering rejected; retry behavior avoids unintended duplicate charges/access; visible failure recovery |
| MVP-AC-05 PayHere | MUST FR-PAY; NFR-REL | Valid verified payment grants once; signature/order/amount/currency/reference mismatches denied; duplicate/concurrent/delayed/out-of-order events safe; no card data or client secrets |
| MVP-AC-06 Bank | MUST FR-BANK, FR-APAY | Private validated upload grants nothing; independent credit and authorized reviewer required; settlement non-reuse, atomic finalization/replay/concurrency/rejection tested |
| MVP-AC-07 Access | MUST FR-ENROLL; BR-001/009/010 | Missing/expired/revoked/cross-user/course grants deny direct access; valid grants scoped; source/revocation auditable; CSA-006 refund cases tested |
| MVP-AC-08 Learning | MUST FR-LEARN/VIDEO/TEXT/IMAGE | All four lesson types work for entitled users; required controls/readability; user-owned progress and agreed resume granularity; recoverable loading/network failures |
| MVP-AC-09 PDF | MUST FR-PDF, FR-PDF-SEC | Private authorization; page/zoom/fit/expanded/scroll/position controls; themes/mobile; disclosed readable personal watermark; new access denied after revocation; delivered-byte limitations documented |
| MVP-AC-10 Admin | MUST FR-ADMIN/STUDENT | Permission matrix enforced in APIs and UI, including statistics; no unrelated student/financial data; authorized changes audited |
| MVP-AC-11 Notices | MUST FR-NOTIFY | Verification and bank decision messages generated; status agrees; delivery failure observable without undoing payment/access |
| MVP-AC-12 Release | All MUST NFR; sections 15/16/21 | RLS/storage negative tests, uploads/rate limits/secrets/log review; automated checks; 390/768/1440 and narrow/intermediate widths, both themes; keyboard/focus/names/contrast; approved browsers/load/restore/monitoring/policies and release review |

Existing AT-001..014 are retained. Add cross-user progress, role-limited
statistics, concurrency, transaction rollback, revocation and operational/privacy
verification to implementation test plans. No tests are waived by this grouping.

## Decision crosswalk and dependencies

| Topic | SRS decision | PLAN decision | Owner / current disposition |
| --- | --- | --- | --- |
| Gateway | DEC-001 | DEC-001 | CSA-004: PayHere confirmed |
| Currency | DEC-002 | DEC-002 | CSA-004: LKR confirmed |
| Customer countries | DEC-003 | DEC-003 | Business Sri Lanka confirmed; full customer territory policy open |
| Receipt limits | DEC-004 | DEC-006 | CSA-005: approved 5 MiB JPEG/PNG/PDF |
| Bank review/disputes | DEC-005 | No direct equivalent | CSA-005 approved baseline; operational targets pending |
| Enrollment duration | DEC-006 | DEC-004 | CSA-006 pending; outside this batch |
| Refund/revocation | DEC-007 | DEC-005 | CSA-006 pending; outside this batch |
| Admin separation/MFA | DEC-016 | DEC-012 | CSA-003 approved policy |
| Watermark/delivery | DEC-008/018 | DEC-008/009 | Separate PDF/privacy decisions pending |
| Video provider | DEC-009 | DEC-007 | Separate media decision pending |
| Retention | DEC-014 | DEC-011 | Business/legal review pending |
| Browser/languages | DEC-012/013 | DEC-016/017 | Owner selection pending |
| Load/budget/recovery | DEC-010/011/015/017 | DEC-013/014/018 (related, not identical) | Quantified release fixtures/targets pending |

The owner approved this versioned scope baseline on 2026-10-11 while retaining
these downstream gates. That does not authorize unresolved financial behavior,
prove implementation, or constitute production release approval.
