# Post-MVP feature proposals: CSA-226–230 and CSA-235

Date: 2026-10-16 (Asia/Colombo)
Status: IN_REVIEW — proposed scope, not approved policy or delivered functionality.
Authority: project owner requested parallel work and selected preparation of proposals for review. CODEX owns preparation; see [coordination record](../tasks/CSA-226-235-PARALLEL-PREPARATION.md).

## Review boundary

TASKS.md section 25 supplies titles and priorities only. PLAN.md section 6 and SRS.md section 3.2 defer these capabilities. The request authorizes preparation and review; it does not supply missing commercial, privacy or authorization rules. No feature is marked DONE, no implementation contract is approved, and no production change is proposed for immediate execution.

Current normative baseline: [MVP scope](CSA-001-002-SRS-MVP.md), [role policy](CSA-003-ROLES.md), [enrollment/refunds](CSA-006-ENROLLMENT-REFUNDS.md), AGENTS.md, ARCHITECTURE.md, DATABASE_DESIGN.md and SECURITY.md. Preserve existing requirements when approving additive changes.

## CSA-226 — Advanced student analytics (P2)

Proposed scope: authenticated learning-progress summaries and course/cohort aggregates derived from existing learning data, with bounded date filters, loading/error/empty states and accessible presentation. Define audience and metrics before collecting new data. Existing dashboard presentation must not be treated as verified student analytics.

Owner decisions:

- Student self-view, assigned instructor view, administrator view, or which combination?
- Which metrics and formulas: completion, lesson engagement, progress trends, cohort comparison? Define denominators, timezone, stale data and incomplete history behavior.
- Which personal fields may be shown, exported or aggregated? Decide retention, deletion handling, small-cohort suppression and any new tracking disclosure.
- Required date range, freshness, dataset size and performance acceptance limits?

Integration investigation: `lib/features/admin/**`, `lib/features/learning/**`, `supabase/functions/admin-dashboard-stats/**`, existing progress persistence and course staff permissions. Use trusted queries/Edge functions and RLS; do not put privileged keys in Flutter or derive cross-student authorization from client filtering.

Data limitation: current progress stores the latest student-supplied resume/completion state. It cannot establish historical activity, trustworthy watch time, assessment results or certified completion. The current Flutter admin dashboard provider uses synthetic totals/payment rows; wire the trusted reporting boundary before presenting real analytics. The privacy baseline excludes optional advertising, session replay and unrelated analytics by default.

Future acceptance: direct cross-user and cross-course access denied; approved roles see only allowed fields; aggregates agree with synthetic source records including duplicates and missing progress; date boundaries and empty cohorts correct; sensitive fields absent from responses/logs; pagination/filter limits enforced; keyboard access, reference widths and both themes verified. Performance and privacy tests use owner-approved thresholds.

## CSA-227 — Discount coupons (P2)

Proposed scope: audited coupon administration, trusted eligibility and price calculation, checkout entry/results and atomic redemption accounting.

Owner decisions:

- Fixed amount, percentage, or both; currency, rounding, maximum discount and minimum payable amount?
- Allow 100% discounts? If yes, approve a separate trusted free-fulfillment contract: current online initialization rejects nonpositive amounts.
- Eligible courses/users, validity timezone and exact boundary behavior?
- Per-user/global limits; when usage is reserved, consumed and released; treatment of abandoned, failed, refunded or cancelled orders?
- Stacking with bundles, referral rewards or other offers; administrative creation/revocation authority?

Integration: `lib/features/checkout/**`, `supabase/functions/create-checkout-order/**`, `initialize-checkout/**`, `payment-provider-webhook/**`, `admin-review-bank-transfer/**`, and new forward migrations for pricing/redemption. Current order input accepts course/payment method only. Extend approved request and idempotency contracts before dependent UI integration.

Invariants: server computes immutable minor-unit totals; private eligibility records remain protected; provider verification matches the final total; limits hold across retries/concurrency; changed financial inputs under the same idempotency key conflict.

Future acceptance: tampered totals and unauthorized administration denied; eligibility/expiry/rounding boundaries match approved rules; concurrent final-use redemption never exceeds limits; retries consume once; coupon edits do not rewrite purchased prices; forged settlement and unverified receipts never grant access; existing checkout and bank/provider flows remain correct.

## CSA-228 — Course bundles (P2)

Proposed scope: published bundle catalog/details, immutable membership and price snapshots, aggregate checkout and atomic course-level entitlement fulfillment.

Owner decisions:

- Fixed bundle price or derived pricing; currency and per-course allocation?
- Already-owned courses: allow, reject or adjust pricing under which rule?
- Course membership/version changes and unpublished or unavailable members after purchase?
- Whole-bundle versus partial refunds/revocation; compatible coupons; creation/publishing authority?

Current blocker: approved checkout is one course per order. `orders.course_id` is mandatory; `enrollment_grants_one_order_idx` permits one grant per source order and validation requires matching course identity. A multi-item order model requires reviewed additive contracts and migrations, including bank approval, financial reporting and refund/reversal behavior.

Integration: checkout paths listed under CSA-227, course catalog presentation, reviewed order-item/bundle metadata, and source-level grants. Inspect foundations `20261011001000_csa092_orders_payment_attempts.sql`, `20261011001300_csa095_enrollments.sql`, `20261011001600_csa101_105_online_payment.sql` and `20261012002000_csa117_checkout_alignment.sql`; do not edit historical migrations.

Future acceptance: aggregate total and allocations match approved pricing; immutable membership survives later edits; every purchased item grants atomically after verified settlement; one failure rolls back all fulfillment; duplicate/concurrent settlement grants once; other valid grants survive source-specific reversal; protected media remains course-authorized; legacy single-course purchases remain valid.

## CSA-229 — Subscription billing (P3)

Proposed scope: plan lifecycle, recurring invoices/settlements, source-specific period entitlements, student cancellation/status views and authorized management. Provider capability and recurring protocol verification are prerequisites, not established facts.

Owner decisions:

- Per-course, bundle or catalog coverage; price/currency/billing cycles?
- Renewal consent, notices and cancellation timing; refunds and access ending rules?
- Grace periods, payment retries/dunning limits and failed-renewal recovery?
- Trials, proration, upgrades/downgrades and exact time boundaries?
- Interaction with existing lifetime purchases and independent grants?

Current boundary: the payment adapter implements single-purchase checkout and retrieval; this review establishes no recurring capability. Approved paid grants are lifetime, with null expiry, and existing order snapshots constrain access duration to null. Add a reviewed subscription source/product model while preserving purchased lifetime rights.

Integration: `supabase/functions/_shared/payments/payhere.mjs`, `initialize-checkout/**`, `payment-provider-webhook/**`, trusted initialization/finalization routines in migration `20261011001600`, entitlement authorization and `lib/features/checkout/**`. Verify deployed function activation and merchant readiness separately; do not activate provider paths as part of drafting.

Future acceptance: exact paid-period boundaries; authenticated, signature-verified duplicate/out-of-order renewal and cancellation events; concurrent renewal/refund/reversal; cancellation timeout reconciliation; unauthorized management denied; atomic invoice/payment/grant/audit rollback; lifetime/admin grants remain independent. Validate provider sandbox protocol before integration, then retain authorized production release gates.

## CSA-230 — Referral and affiliate system (P3)

Proposed scope: validated referral attribution, auditable commission ledger and authorized reconciliation/administration. Treat automated payouts as a separately approved capability; a referral code alone never verifies payment or grants course access.

Owner decisions:

- Student referral rewards, commercial affiliates, or both; eligibility and application/approval process?
- Attribution window, first/last attribution, conflict handling, self-referrals and abuse controls?
- Commission basis/rate/currency; discounts, taxes, fees, bundles and subscriptions included or excluded?
- When earnings become payable; refund/reversal clawbacks and disputed transactions?
- Payout method, threshold, schedule, authority, reconciliation and applicable commercial obligations?
- Tracking disclosure, consent where required, permitted data visibility and retention?

Integration investigation: trusted order creation/financial finalization, immutable attribution snapshots, source-linked accounting, financial reporting and role-limited affiliate views. Current single-purchase provider code does not establish a payout capability. Shared pricing and settlement contracts must be agreed with CSA-227–229 before implementation.

Future acceptance: forged attribution and unauthorized commission/payout writes denied; approved attribution boundaries deterministic; duplicates/concurrent settlement cannot credit twice; unpaid orders earn nothing; refunds and reversals follow approved source-specific rules without rewriting history; payout retries reconcile without duplicate disbursement; affiliates cannot read student receipts, unrelated users or other affiliates' earnings; existing enrollment/payment invariants remain intact.

## CSA-235 — Multi-instructor administration (P3)

Proposed scope: authorized assignment/revocation and management views for course staff, extending the existing `course_staff` owner/editor model. Do not silently equate this with a multi-seller marketplace or revenue sharing.

Owner decisions:

- Staff administration only or independent instructor selling? Revenue sharing requires separate financial scope.
- Who invites/assigns/revokes, transfers ownership, publishes, edits price and manages media?
- Multiple owners, last-owner removal, disabled accounts and pending invitation rules?
- Instructor access to learner identity, analytics, progress, orders and exports?
- Effects of revocation on active sessions, uploads, publication and pending operations?

Integration investigation: `course_staff`, course authoring/publication/upload APIs, role-assignment boundaries and `lib/features/admin/**`. Course membership must not grant finance or global administrator powers. Enforce current membership at trusted boundaries with audited changes and reviewed RLS.

Current role boundary: application roles are student, content_manager, finance_admin and super_admin; no instructor application role exists. Decide whether instructors use content_manager plus a course assignment or require a separately reviewed role. Existing course creation assigns an owner; no general staff assignment/revocation API or administration UI was found. The admin course repository also contains stubs, so do not assume its operations already persist.

Future acceptance: cross-course reads/writes and role escalation denied; forged assignment and unauthorized ownership transfer rejected; revocation affects subsequent protected requests; concurrent staff edits preserve approved ownership constraints; uploads/publication and analytics enforce identical course scope; student paid access survives unrelated staff changes; accessible administration across themes/reference widths.

## Controlled parallel implementation after review

1. Owner resolves decisions above and approves additive scope plus testable acceptance criteria. Record decisions individually; accepting this preparation does not approve unspecified policies.
2. Restore GitHub access, verify Issues/PRs/locks and assign one accountable owner, writable scope and isolated worktree per task.
3. Assign one financial integration owner for CSA-227–230. Agree order/pricing, idempotency, fulfillment, refunds and reporting contracts. Serialize shared migrations and payment-state changes.
4. Prepare analytics and instructor UI independently only after the common course-visibility contract is approved. Serialize role/RLS changes; agree analytics field visibility with CSA-235.
5. Parallelize feature-local UI, contract fixtures and independent tests after contracts stabilize. Read-only preparation in this run used three workers; no workers shared mutable implementation files.
6. Use TDD for critical financial/authorization behavior, then run relevant database/RLS/Edge tests, Flutter formatting/analyzer/tests/build, and combined integration checks in isolated environments. Review each focused PR; owner controls sensitive integration and release.

## Preparation evidence and limits

Reviewed local task/scope documents and code integration constraints using read-only parallel analysis. GitHub issue/PR queries failed to resolve the configured repository, so remote ownership remains unverified. This document defines future tests; no runtime, provider, RLS, UI, performance or production acceptance tests were executed for these unimplemented features.
