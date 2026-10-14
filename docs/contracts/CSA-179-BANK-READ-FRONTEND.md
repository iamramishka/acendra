# Bank receipt read/review frontend contract

User approved implementation and documentation reconciliation, 2026-10-14.
POST bank-transfer-read accepts exactly {order_id: UUID} (owner status) or
{queue:true} (current finance/super admin AAL2). SQL rechecks live user/session/role
through csa108_require_session. Queue bounded100 pending nonself submissions;
status nonexistent and nonowned orders both404. No student email, bank credit,
private notes, object paths or signed URLs leave reads. service_role alone calls
csa179_read_bank_transfer; authenticated table grants remain revoked. New deployed
read index hard-disabled503 BANK_READ_UNAVAILABLE, no environment enablement.

The authorized frontend reconciles existing CSA112 verified_credit request
shape from CSA-112-BANK-REVIEW.md as the implementation contract. Generic legacy
verification/amount fields are not sent. Review still requires independent bank
credit, exact canonical integer amount, matched account/reference, settled timestamp
and current MFA finance authority; SQL validates these again atomically. Rejection
sends only submission_id, decision, student-safe rejection_reason. Retry retains
principal/submission/decision key; changed evidence must conflict rather than
create a second decision. UI never declares enrollment active from approval.
All upload/review entrypoint release gates remain closed pending operational
inspection, bank and financial acceptance. Neither contract implementation nor
synthetic tests establishes real bank funds or production readiness.
