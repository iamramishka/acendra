# CSA-015 - Privacy and security baseline

Date: 2026-10-11 (Asia/Colombo)
Status: PROPOSED - IN_REVIEW; no policy or production approval recorded
Preparation owner: CODEX security agent
Decision owner: Project Lead, with finance and privacy/legal review
Policy base: e1cf11f on origin/dev (merged approved policy baseline); initial foundation inspection: 9355311
Scope: Documentation only; no backend, configuration or deployment changes

## Decision requested

Approve the control baseline below for MVP implementation after resolving the decision register. Existing mandatory security requirements remain applicable while this proposal is under review. Approval of this document means approval of a design, not proof that deployed controls work. CSA-015 must remain IN_REVIEW until the Lead records approval; implementation and release verification remain separate gates.

Sources reviewed: AGENTS.md, TASKS.md (Phase 0), SRS.md, SECURITY.md, ARCHITECTURE.md, DATABASE_DESIGN.md, the parallel review board, and foundation code listed below. The approved requirements/policy records on origin/dev were subsequently reviewed: docs/requirements/README.md, CSA-003-ROLES.md, CSA-006-ENROLLMENT-REFUNDS.md and CSA-010-PDF-DELIVERY.md, plus updated SRS/SECURITY and merged threat register. Sri Lanka, PayHere/LKR, roles/MFA, bank limits, lifetime purchased access, seven-day refund requests and authenticated proxy PDF delivery are approved. Full customer territories, financial retention periods, processor terms and production configuration remain gates.

## Data inventory and minimum visibility

The following is the proposed purpose and access boundary. The approved CSA-003 permission matrix is normative. References to support/identity/enrollment/recovery operators describe duties, not additional application roles: those duties must be assigned within approved capabilities (other-student management/manual grants/role changes require explicit super-admin authority). All access is denied unless a trusted permission check authorizes it.

| Data / classification | Minimum purpose and fields | Permitted visibility | Collection limits |
| --- | --- | --- | --- |
| Identity / confidential | Supabase Auth identifier, email, verification/account state; profile display name and timestamps | Student owns their profile; support sees only fields required for an authorized case; identity operators have audited operational access | Passwords remain with Auth; do not duplicate them in profiles. Locale/avatar are optional; no national ID, address, phone, date of birth or bank details without a separately approved need |
| Roles / confidential | User, assigned capability, assigning actor, time and revocation | Authorized identity operator; student may receive only their effective capabilities | No client-writeable admin role or trusted user-metadata role claim; individual staff identities |
| Orders/payments / restricted | Student/course/order IDs, amount, currency, provider reference, verified outcome and timestamps | Student's own safe status/history; assigned finance operators; narrowly scoped trusted processing service | Provider handles card entry. Never retain raw card credentials; minimize callback fields and redact provider payloads |
| Bank receipt / restricted | Private object, order reference, submission state, finance decision and verification reference | Submitting student only through approved ownership workflow; authorized finance reviewer; trusted upload/review service | Receipt is evidence, not settlement. Ask users to omit unrelated statement information; avoid copies in tickets/email/logs; do not collect full bank statements by default |
| Entitlement / confidential | Student/course, source, state, start/expiry and revocation reason | Own student; authorized enrollment operator; content authorization service | Do not expose payment/receipt details to content editors or general student lists |
| Progress / confidential | Student/lesson, completion, supported position, updated time | Own student; trusted progress service; exceptional support access for an authorized case | No keystroke capture, screen recording, browsing surveillance, advertising identifiers or session replay |
| Course assets / confidential (published catalog metadata is public) | Licensed PDF/video/text/image content and private asset references | Authorized enrolled learner or explicitly approved preview; scoped content operator | Catalog responses contain only published metadata; never expose private receipt or media paths through public records |
| Watermark / confidential | Approved display name plus opaque license ID, bound to actor/asset version | Authorized viewer; issuer; only explicitly authorized super-admin/finance staff may resolve identity | Use approved "Licensed to <display name> - <opaque license ID>" on every page; no email, phone, NIC, bank data or another student identity. Privacy/retention and accessibility implementation review remain gates |
| Security/access logs / confidential | Event/time, correlation ID, safe operation/outcome/error code, pseudonymous actor/resource reference | Designated security/operations staff | No passwords, JWTs, refresh/reset tokens, signing secrets, full signed URLs, receipt bytes, raw card data or unnecessary profile fields |
| Administrative audit / restricted | Actor/action/resource, time, reason, outcome and safe transition metadata | Relevant authorized finance reviewer, explicitly authorized super admin and narrowly scoped audit service | Append through trusted operations; deny user edits/deletes; separate audit evidence from verbose diagnostic payloads |
| Support / confidential | Case ID, request category, necessary correspondence and decision | Requesting student and assigned support operator | Never request passwords/tokens; redact irrelevant financial details and attachments |
| Backups / restricted | Approved recoverable database records, private objects and operational configuration | Named recovery operators only | Encrypted and private; separate credentials; no restoration into ordinary development; apply deletion ledger after restore |

Maps to NFR-PRIV-001 through NFR-PRIV-008, FR-PROFILE-004/007/008, FR-PAY-011/012/013, FR-BANK-006/009/018, FR-ENROLL-008/009 and FR-PDF-SEC-008.

## Retention and deletion proposal

These durations are engineering/business proposals for review, not statutory requirements or approved policy. DEC-014 / SEC-OPEN-008/009 remain unresolved. No production retention job or destructive cleanup is authorized by this draft.

| Category | Proposed default | Deletion/review trigger and exception |
| --- | --- | --- |
| Profile and Auth account | While account is active | On a verified deletion request, disable access, revoke sessions and delete/anonymize unnecessary profile/Auth data after approved financial relationship handling. Inactivity policy remains an owner decision |
| Learning progress | While account/entitlement needs progress restoration | Delete with account closure unless an explicit student request and lawful purpose justify otherwise; retain no personal progress after deletion by default |
| Ordinary diagnostics and security/access logs | 30 days of diagnostics; 90 days of security/access logs | Rolling expiry; isolate incident evidence under a documented case/hold rather than extending all logs indefinitely |
| Support cases | 180 days after closure | Delete unnecessary correspondence and attachments; link disputed transactions to an approved restricted hold instead of copying receipts |
| Watermark-generation intermediates | Request lifetime; proposed maximum 24 hours for temporary derived files | Purge failed/expired intermediates; never retain a parallel identity history merely for watermarking |
| Orders, payments, financial audits and bank receipt evidence | Numeric period intentionally unresolved | Finance/legal must approve periods by record category, lawful purpose, jurisdiction, dispute window and hold rules before production. Receipts may require a shorter period than transaction ledgers; no automatic cascading deletion of financial history |
| Privilege and administrative audits | Period unresolved pending security/finance review | Preserve accountability for approved period; restricted incident/legal holds require owner, purpose, scope and review date |
| Backups | Proposed rolling 30-day application/object backup window, subject to provider feasibility and recovery objectives | Expire copies on schedule. Delete primary data promptly where permitted; disclose bounded backup expiry and replay deletion ledger before a restored service serves users. Incident/legal holds require separate restricted copies |

Deletion workflow: authenticate the requester without collecting extra identity by default; check ownership; open a tracked case; identify active disputes/required records; obtain finance/legal decision for exceptions; revoke access; delete or irreversibly anonymize eligible database and actual Storage objects using supported APIs; propagate to processors; record safe completion/exception evidence and backup expiry; notify the requester through the approved process. Do not assume deleting storage metadata deletes file bytes, or that removing an Auth user can safely cascade financial records. A hold must be scoped and periodically reviewed; account deletion does not imply erasing necessary financial audit history.

Proposed service target: acknowledge a request within 7 calendar days and resolve eligible deletion within 30 days, subject to confirmed legal deadlines and documented exceptions. Privacy reviewer must reconcile this target with supported jurisdictions before publication. Maps to NFR-PRIV-007, FR-PROFILE-007/008 and SECURITY.md sections 26-29/35.

## Trusted control baseline

| Boundary | Required design | Acceptance evidence |
| --- | --- | --- |
| Auth/session | Supabase Auth; verified trusted identity on protected requests; fail closed for expired/invalid sessions; safe recovery and logout; endpoint rate limits | Registration/recovery/session tests, revoked/expired-token requests, generic errors and throttling evidence (FR-AUTH-001 through 009/012; NFR-SEC-005/006) |
| Staff permissions | Individually assigned least privilege; server-side capability checks; no student role writes; MFA required for finance/super-admin production operations; current roles/assignments rechecked; no self-approval/self-role changes/last-admin removal; independent beneficiary-change review | Student/foreign-role/direct RPC rejection, revoked staff access, privilege audit and MFA enforcement proof (FR-AUTH-009; FR-ADMIN-001/003/004/005; SEC-OPEN-014/015) |
| Database/API | Grants and RLS reviewed together; default deny exposed data; functions authorize each sensitive operation; constrained function execution/search path; client cannot create paid state or active paid grants | Guest and two-student read/write/delete/RPC tests for each protected entity; migration ordering and privilege review (NFR-SEC-001/004/010/011; FR-PROFILE-004) |
| Payment | Provider-authenticated notification; trusted order/amount/currency/status/reference match; event idempotency; atomic payment/order/entitlement transition; pending on uncertainty | Forged/mismatched/duplicate/replayed/out-of-order/concurrent events; failure rollback and one-grant result (FR-PAY-003 through 010; AT-003/004/005/014) |
| Bank review | Private authorized upload; validate JPEG/PNG/PDF, maximum 5 MiB and actual content; current independent finance decision after exact settled LKR credit/destination verification; no settlement reuse; auditable atomic transition | Submission/pending/rejection never grant; unauthorized reviewer, spoofed/oversized upload and concurrent decision tests (FR-BANK-005 through 012/015/016/018; AT-006/007/008) |
| Entitlement/content | Trusted identity, eligible account, entitlement owner, course/lesson, surviving grants and restrictions checked before new delivery. Paid grants are lifetime; explicit complimentary expiry is enforced. PDFs use private server-watermarked derivatives via authenticated proxy on descriptor/GET/HEAD/range/conditional requests, no direct student Storage URL or original fallback. Video temporary grants follow CSA-011; private/no-store media policy | Guest, foreign student, wrong course, expired/revoked grant, direct-object and expired-token denial for PDF/video/text/image paths (FR-ENROLL-002/003/010; FR-PDF-SEC-001/002/003/007/010; FR-VIDEO-002/003/006/007; AT-002/009/010) |
| Watermark/reader | Disclosed approved display-name/opaque-license watermark burned into PDF derivative bytes; authorized student only; readable/selectable and accessible controls | Correct identity, no cross-student information, readability and accessibility review; disclose capture limitations (FR-PDF-SEC-005/006/008; NFR-PRIV-006/009) |
| Secrets/build/operations | HTTPS; environment separation; private signing/payment/secret credentials only on trusted systems; review secrets and dependencies; safe user errors; validate untrusted rendered content | Built-asset/repository scanning, runtime permissions, redacted logs, upload/content injection and deployment configuration review (NFR-SEC-002/003/005/007/008/009/012) |

Supabase secret/service-role access can bypass RLS; trusted privileged code must independently authorize its caller and resource, and must not trust a client-provided user ID as authority. [Supabase API-key documentation](https://supabase.com/docs/guides/getting-started/api-keys).

For video delivery, short-lived bearer media links can be copied until expiry. The approved PDF proxy must not issue student Storage signed download URLs. Revoke/expire future issuance and document the selected provider's behavior for outstanding grants. Previously delivered bytes and browser screenshots/recordings cannot be reliably recalled or prevented; watermarking reduces risk rather than guaranteeing protection (SRS LIMIT-001 through 004 and AT-010). No hidden student monitoring is permitted.

## Vendor, notice and operational requirements

Before sending real student data to Supabase, payment/video/email/monitoring providers, record processor purpose, minimum fields, hosting regions, subprocessors, access controls, contractual data terms, deletion/export capabilities, incident contacts and retention. Confirm customer jurisdictions and any cross-border obligations with the privacy reviewer; provider selection alone is insufficient approval. Use synthetic student/payment/receipt fixtures in development and staging. CSA-011/012 must reconcile delivery capabilities, regions, cost limits and protected-content availability with this baseline. Concurrent draft proposals (not approved): Mux Basic signed VOD without optional Mux Data tracking/cookies, five-minute playback tokens with conditional renewal; separate staging/production Supabase projects, a USD 150 monthly review envelope and RPO 24 hours/RTO 4 hours. Video token reuse until expiry/buffered-byte limitations must be disclosed. Confirm processor telemetry separately from optional analytics. Financial reconstruction and stricter recovery needs can require revised budget/backup design; the proposed 30-day application/object backup window needs explicit feasibility and cost reconciliation.

Publish understandable privacy/data-use information before collecting student data, including processors, purposes, retention, rights/request contact, necessary security/course-access logging and watermark practices. No optional advertising, session replay or unrelated analytics by default. Confirm the supported student age range and any required child/guardian handling before registration opens; do not collect birthdays simply because the policy is undecided.

The Sri Lankan Data Protection Authority lists the Personal Data Protection Act No. 9 of 2022 and Amendment Act No. 22 of 2025. If Sri Lanka is in scope, the privacy reviewer must verify current commencement instruments, applicable duties and transfer/notification rules rather than relying on historical launch announcements. No statutory retention or breach deadline is asserted here. [DPA official legislation index](https://www.dpa.gov.lk/).

Operational controls: name the security lead, privacy request owner, finance operator and deployment/recovery owner; review privileged access at least quarterly as a proposed operating cadence; document secret rotation, emergency revocation, rate limits and alert routing. Logs must use allowlisted safe fields; exceptions and debug stack traces require the same privacy discipline as production logs.

Incident runbook must cover detection, triage, containment, preserved restricted evidence, scoped credential/session revocation, suspension of unsafe payments or content issuance, investigation, verified recovery and post-incident actions. Legal/privacy review determines notification recipients/deadlines by actual jurisdiction and facts; do not invent a universal deadline. Test the response with a tabletop containing an exposed signing credential and unauthorized receipt access before launch.

Database backups exclude Storage file objects; establish separate private object recovery, integrity checks and deletion-ledger handling. Test database plus PDF/receipt recovery in an isolated environment against the approved RPO/RTO. [Supabase backup documentation](https://supabase.com/docs/guides/platform/backups). Maps to NFR-REL-001 through 005/007 and SECURITY.md sections 34/35.

## Current evidence versus future verification

Observed initially on base 9355311 and rechecked after rebasing this documentation-only change onto e1cf11f: foundation widgets, navigation, themes and frontend tests exist. `lib/core/config/env_config.dart` declares public Supabase build variables; `lib/app/bootstrap.dart` only initializes Flutter and Riverpod. `lib/core/utils/logger.dart` permits arbitrary debug messages/errors/stack traces and is not evidence of redaction. No `supabase/` migrations, Edge Functions or backend permission/payment tests are present in this checkout. No Auth integration, deployed RLS/private buckets, payment verifier, entitlement issuer, approved retention jobs, vendor agreement, production alerting, MFA, recovery drill or policy publication was verified.

SECURITY.md on merged origin/dev contains THREAT-001 through THREAT-018 and the approved reconciliation record. Its course access, forgery/replay, privilege escalation, cross-user data, secret leakage, uploads, CI/dependency, backup and capture risks are addressed above. Some original threat rows retain historical open-choice wording; current approved CSA-003/005/006/010 policy records and reconciliation govern those resolved choices. Threat acceptance scenarios remain future evidence; no tests are claimed passed.

No security/financial runtime tests were run for this documentation-only task. Required future evidence is described above and in CSA-017. Security approval cannot be inferred from passing Flutter widget tests.

## Decision register and release gates

| Decision | Accountable reviewer | Required resolution |
| --- | --- | --- |
| Customer regions, legal entity, lawful purposes and supported ages | Lead + privacy/legal | Confirm countries and required privacy/consumer obligations; approve notices/rights handling (DEC-003; SEC-OPEN-013) |
| Numeric retention by category and deletion workflow | Privacy/legal + finance + operations | Approve nonfinancial proposals; provide financial/audit periods and backup/hold handling (DEC-014; SEC-OPEN-008/009) |
| Privileged operations readiness | Lead + security + finance | Preserve approved CSA-003 roles/separation/MFA; assign operators/alternate, secure first-admin bootstrap and prove current-role/MFA checks. No reapproval of DEC-016 requested |
| Payment/bank/refund readiness | Lead + finance | Implement approved PayHere/LKR, 5 MiB JPEG/PNG/PDF, independent matching and CSA-006 source-specific refund/revocation policy; provide merchant activation, bank destination, named reviewers, inspection runtime and unresolved eligibility/operating terms. DEC-001/004/005/006/007 choices remain approved |
| Watermark and media delivery | Lead + privacy + content/security | Review approved display-name/license watermark privacy and retention; implement approved authenticated PDF proxy; resolve reader accommodations and video grant/revocation behavior (DEC-008/009/018; SEC-OPEN-005/006/007; CSA-011) |
| Operations and environments | Lead + operations | Named contacts, monitoring, vendor regions/terms, budget, backups/RPO/RTO and security-test plan (DEC-011/015; SEC-OPEN-001/010/011/012; CSA-012/017) |

Documentation approval checklist:

- [ ] Lead, finance and privacy/security reviewers record names, date, accepted decisions and unresolved exceptions.
- [ ] Inventory, retention schedule, notice, deletion and processor controls are approved consistently with SRS/SECURITY.
- [ ] CSA-011/012/017 and approved CSA-003/005/006/009/010/016 artifacts are reconciled; no contradictory role/retention/media promises remain.
- [ ] Follow-up implementation tasks have owners and requirement/test references; CSA-015 status is updated only through the coordinator.

Production security/privacy gate (every item requires actual evidence):

- [ ] Trusted Auth, grants/RLS, role/MFA and cross-user/direct API/storage denial tests pass.
- [ ] Verified payment, bank authorization, concurrency/idempotency and entitlement revocation tests pass.
- [ ] Private PDF/video delivery, upload validation, watermark privacy/readability and secret/log review pass.
- [ ] Approved notices and request contacts are published; retention/deletion/holds/backup expiry work and processor terms/regions are reviewed.
- [ ] Incident tabletop and database/object restore succeed against approved objectives; alerts and named responders work.
- [ ] High-severity findings are resolved; required security review and explicit production deployment approval are recorded.

## Preparation handoff

Task/owner: CSA-015 / CODEX preparation; Lead approval pending.
Branch: codex/docs/csa-015-phase0-review.
Files changed: this document only. Shared contracts changed: none.
Completed: reviewable inventory, retention/deletion proposal, control/evidence map, decisions and release gates.
Remaining: owner/legal/finance approval; approved-policy integration; implementation and operational verification.
Verification: documentation whitespace and diff self-review; no runtime-control verification claimed.
Next action: coordinator submits for review and reconciles CSA-017; do not mark DONE before formal acceptance.
