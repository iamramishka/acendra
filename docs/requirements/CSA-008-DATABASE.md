# CSA-008: Database entities and relationships baseline

Date: 2026-10-11
Status: APPROVED design baseline - owner accepted and authorized merge on 2026-10-11
Baseline: DATABASE_DESIGN.md 1.0 on origin/dev b9bc60b.
Existing csa-008-db-design uncommitted draft was inspected read-only. It expands
ER diagrams/FK documentation; this review preserves it without copying its edits.
No SQL migration, applied schema or runtime verification is part of this batch.

## Canonical entity design

Retain existing identity/roles/course staff, categories/courses/sections/lessons,
private media, orders/payment attempts/events, bank submissions/reviews,
enrollments/grants, progress and audit/outbox entities. The following addendum
resolves missing integrity boundaries; it takes precedence over illustrative
base tables for the accepted design. Owner acceptance is recorded in the coordination document.

| Entity | Relationships and invariants |
| --- | --- |
| bank_account_versions (private) | Immutable destination version; logical bank account has many versions; never edit instructions already bound to an order |
| order_bank_instructions (private) | Exactly zero/one per order; bank-transfer order requires one before accepting funds; FK to immutable account version and trusted instruction snapshot |
| verified_settlements (private) | Each belongs to one order; an order may have multiple real settlements but one fulfillment; method, account/provider/merchant/environment scope, exact amount/currency, confirmed identity/evidence/time |
| refund_cases (private) | Order/purchaser/settlement, original grant timestamp and deadline, received time, reason, reviewer/decision, stable command and processing lifecycle; one active case per requested settlement/order operation |
| financial_reversals (private) | Verified settlement/order FK; refund/chargeback/reversal kind, exact amount/currency, scoped confirmed external identity, evidence, actor and lifecycle timestamps; approved request is distinct from confirmed money movement |
| enrollment_grants | One enrollment has many sources; valid_from/valid_until, source-specific invalidated_at/reason; order-funded source uniquely references matching owned course/order; admin source uses authorized actor/reason without fabricated payment |
| access_restrictions (private) | Explicit grant, user-course or account scope, reason, current lifecycle and audit; exactly one valid target shape; dispute restriction does not masquerade as enrollment expiry |
| enrollments | UNIQUE(user_id,course_id); current access projection derived from surviving eligible sources and restrictions; ACTIVE/EXPIRED/REVOKED remain existing vocabulary |
| media_assets | Immutable content digest/version and validated/readiness state; invalid or uninspected asset cannot be delivered |
| pdf_derivatives (private) | CSA-010 output linked to original version + user/license + watermark policy version, immutable digest/size/readiness and private object; uniqueness prevents cross-user cache reuse |
| protected_delivery_records (private) | If opaque resource IDs are used, bind to actor, derivative, version and validity; not a bearer permission; proxy reauthorizes every request |
| idempotency_records (private) | Non-null principal/service scope + operation + key unique, request hash and safe result; avoids NULL-actor uniqueness bypass for service callbacks |

Existing category association may be optional; a grant's source order is optional
only for authorized admin sources. One order funds at most one source grant in
the one-course MVP; one enrollment may have independent valid sources.

Purchased grants use valid_until=null for the owner's lifetime selection. Store
first trusted fulfillment timestamp immutably for the approved 168-hour request
deadline. New purchases have new sources, not rewritten original grants. Source
invalidation and restrictions are separate from deletion.

## Money, identity and referential constraints

- Use exact minor units or constrained NUMERIC consistently with immutable LKR
  order snapshots; never float. Currency and amount must match the verified event,
  order and permitted adjustment, and cumulative confirmed refunds cannot exceed
  verified refundable funds. No automatic partial/FX behavior is inferred.
- Uniqueness uses independently verified settlement identity in its real scope:
  receiving bank account/provider for bank credits, merchant/environment/provider
  for online funds. One settlement cannot fund two orders. Receipt hash or student
  reference is merely a heuristic.
- PayHere payment_id is outside the callback checksum in the approved CSA-004
  review. Do not authenticate settlement identity solely by that supplied field;
  verified retrieval/reconciliation and replay identity remain prerequisites.
- FK checks alone do not prove matching user/course/order. Restricted operations
  or appropriate composite constraints must enforce all source/beneficiary/course
  associations and legal status transitions.
- Partial unique indexes prevent overlapping active roles/staff assignments and
  multiple active bank submissions. Define active-case predicates against accepted
  state mappings before writing migrations.
- Financial/review/grant/audit parents use RESTRICT/NO ACTION rather than cascading
  erasure. Archive purchased courses. Preserve evidence for extra/late settlements
  as reconciliation cases instead of discarding real funds or granting twice.

## Authorization and transactions

Public callers receive published metadata only. Students receive own safe
profile/order/enrollment/progress projections under RLS plus narrow grants.
Do not broadly SELECT bank submissions exposing receipt_asset_id/internal notes.
Private financial records, bank versions, settlements, reversals, restrictions and
derivatives have no direct student grants. Own receipt delivery uses the approved
safe-view API; PDF delivery uses the CSA-010 approved boundary.

Resolve current roles, MFA and assignments on sensitive calls, including old
tokens. Restrict privileged RPC EXECUTE, use safe search_path/schema qualification,
derive actor from trusted session provenance and enforce permitted fields.
Service-role access requires explicit checks; it is not evidence of permission.

Lock in a documented consistent order across fulfillment, bank review, refund,
dispute and manual access changes. Atomically commit verified settlement/decision,
legal order transition, source lifecycle/projection, audit and durable outbox.
External payout and notification calls remain outside PostgreSQL transactions.
Recompute access with live timestamps, valid independent sources and applicable
restrictions. Refunding source A must preserve eligible source B. Stale success
cannot restore a refunded source or remove a broader restriction.

## Migration and acceptance plan

1. Map the accepted CSA-006/007/010 contracts and entity/state additions into API
   contracts. Assign one migration owner; do not change shared/applied migrations.
2. Add versioned bank instructions, settlement/reversal/refund/restriction/source
   lifecycle and derivative schema with constraints and supporting indexes.
3. Add restricted operations plus grants/RLS/safe projections together. Validate
   upgrade/backfill ordering and preserve existing financial sources.
4. Test synthetic local data before any staging/production release approval.

Required tests: two-user database/API/storage denial; role forgery/revocation,
self-review/self-grant/last-admin protection; safe-column and privileged RPC grants;
duplicate and bank/online concurrent fulfillment; settlement non-reuse; transaction
rollback including outbox; refund source A with valid B; global restriction;
repurchase/reversal race; server-time expiry; service-scope idempotency; FK/delete
behavior and migration ordering. No tests above are claimed executed.

Retention/account erasure remains a production gate: the profile/auth FK and
financial owner references cannot safely hard-delete a user without an approved
pseudonymous identity/anonymization workflow. Set separate evidence/learning/audit/
abandoned-upload/derivative periods; do not invent legal retention. Delete stored
objects through supported Storage APIs. Destination/reconciliation identity,
provider refund capability, derivative runtime and production limits remain gated.
