# CSA-007: Architecture approval candidate

Date: 2026-10-11
Status: IN_REVIEW - technical baseline candidate; owner approval pending
Sources: ARCHITECTURE.md, SRS 1.1, approved CSA-003..005 policies,
SECURITY.md, API contracts and twelve ADR drafts.

## Proposed architectural contract

- Keep Flutter Web/Dart/Material 3, Riverpod and go_router in a feature-first
  modular application. Presentation depends on domain; data implements domain
  interfaces and calls SDKs. App composition injects concrete adapters. A request
  flow diagram is not a license for domain code to import data implementations.
- Keep Supabase Auth, PostgreSQL with reviewed grants/RLS, private Storage and
  Edge Functions. Direct browser access is limited to published metadata and
  permitted own safe projections. Browser writes cannot set payment status,
  entitlements, roles or private asset identities.
- Resolve verified identity, current roles/course assignments, account eligibility,
  MFA assurance, allowed fields and resource scope at each sensitive backend
  operation. Service-role access bypasses RLS, so orchestration must explicitly
  enforce authorization before invoking restricted privileged operations.
- One restricted PostgreSQL operation commits verified settlement/payment/order,
  source grant, audit and outbox atomically. External payout/provider calls and
  actual email delivery sit outside that transaction, with durable commands,
  idempotency and reconciliation for ambiguous results.
- Current access derives from valid independent grant sources and scoped
  restrictions. Use server time. Refund/reversal invalidates its funding source;
  unrelated valid grants survive. CSA-006 supplies the reviewed lifecycle rules.
- Private lesson delivery resolves user/course/lesson/asset version and checks
  live authorization. CSA-010 proposes authenticated proxy PDFs and server-applied
  personalized derivatives; its runtime and reader compatibility remain gates.
- Feature dependencies stay acyclic. Consume another feature's domain contract,
  never its data or presentation internals. Shared router/theme/core/schema/API
  changes retain one coordinated owner and reviewed integration.

## Candidate corrections applied to ARCHITECTURE.md

Previously approved PayHere/LKR, finance/super-admin MFA and scoped authoring
policies are reflected instead of marked unselected. Publication/pricing authority
follows CSA-003. The candidate links the four coordinated deliverables and clearly
separates unresolved decisions from previously approved rules.

Section 4 numbering is aligned to the twelve existing ADR drafts: 009 PDF,
010 video, 011 parallel engineering and 012 controlled integration. This is an
index reconciliation, not approval of those draft ADRs or future provider choices.
Use the existing docs/API_CONTRACTS.MD and docs/TESTING.md path casing.

## Contract and implementation gates

| Boundary | Required evidence before enabling |
| --- | --- |
| Identity/roles | Two-user RLS/storage checks; revoked role with old token denied; self-review/self-grant denied; MFA checked server-side |
| Financial finalization | Duplicate and bank/online races, immutable source identity, rollback injection, safe payout reconciliation |
| Grants | Lifetime/expiry server-time checks; source-specific refund and repurchase concurrency; broader restrictions respected |
| PDF | Authenticated descriptor/GET/HEAD/range checks, no original-storage bypass, watermark bytes, cache/revocation/readability/accessibility proof |
| Flutter boundary | No privileged secrets in web build; no domain->data import inversion; responsive loading/error/session behavior |
| Integration | Canonical schema and API align with accepted policies; migration grants/RLS and contracts tested together |

No architecture implementation, migration, payment or browser checks were run
by this document review. Final acceptance selects boundaries; runtime verification
remains mandatory. Video/hosting/email/monitoring providers, retention and
backup/recovery targets remain independent decisions. SECURITY.md and API contract
wording must be aligned under separately coordinated ownership before sensitive
implementation; the latest accepted SRS/policy governs approved choices.
