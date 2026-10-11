# CSA-104/105 atomic finalization and idempotency

Status IN_REVIEW. Owner CODEX financial_finalization. Branch codex/feat/csa-104-105-finalization; isolated managed worktree csa-104-105-finalization. Coordination issue76 comment6110545061. Dependencies merged migration011–015 and approved CSA004/006/008. Root owns TASKS/package integration; this worker owns new migration016, SQL tests and exact RPC contract only. Project owner retains acceptance authority.

Implemented retrieved-evidence exact terms/scope validation, globally scoped real-payment identity, stable event replay/conflict, atomic paid order/attempt/source/enrollment/audit/outbox, additional/late settlement reconciliation with no grant revival. Integrated one narrowly purchased source grant required by DATABASE_DESIGN §38; CSA116 general grant APIs remain separate. Notification sending remains CSA119.

Verification: native isolated PostgreSQL16 on loopback port55504 with minimal Supabase auth bootstrap. RED: SQL failed missing initialization function before016. GREEN: 32 actual transactional SQL assertions pass after016, including injected outbox failure rollback, invalid evidence no replay reservation, extra payment and refunded late success. Root verified three real independent-session race scenarios: initialization distinct keys, duplicate verified payment, and two distinct real payments with one grant. Docker daemon unavailable; native auth bootstrap does not establish GoTrue/PostgREST integration acceptance.

CSA100 real sandbox checkout/callback/retrieval unavailable per owner. Checkout remains disabled; no hosted database or provider operations, no production credentials. IN_REVIEW until CI/security review and provider acceptance; not DONE.

