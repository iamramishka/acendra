# Recovery and diagnostic operations baseline

Date: 2026-10-13, Asia/Colombo. Decision authority: project owner delegated the
requested recovery-target, owner and retention choices with “you can decide” in
the current acceptance continuation. CODEX records the following baseline.

| Setting | Selected baseline |
|---|---|
| Recovery point objective (RPO) | At most 24 hours of recoverable data loss |
| Recovery time objective (RTO) | Restore usable authorized service within 4 hours of declaring recovery |
| Recovery lead | Project owner; a named alternate must be designated before production release |
| Backup retention | Rolling 30 days, separately protected from the primary system |
| Diagnostic log retention | At most 30 days; shorter retention when sufficient for the incident purpose |
| Diagnostic access | Least-privilege operations/security personnel; audited administrative access |

RPO is measured using the newest recoverable database and object/event backup,
including deletions. RTO includes database, Auth/configuration, private object
bytes, deletion-ledger replay, permission checks, provider reconciliation and
service verification. Timing a small local SQL restore cannot establish either
objective. Backup cadence must meet the selected RPO; backup location, encryption,
key recovery and retention enforcement must be verified before launch.

Restore into an isolated destination first. Compare protected object hashes and
database references; replay authorized deletion/tombstone records before exposing
data. Reconcile financial events with the payment provider; do not infer settlement
from client redirects or receipts. Prove active entitlements and denied unauthorized
requests after restoration. Do not restore deleted receipts from retained backups
into live availability. Backup expiry does not override a deletion obligation.

Diagnostic records use allowlisted fields and redact tokens, credentials, signed
URLs, receipt bodies and unnecessary student/payment identifiers. These settings
do not choose statutory financial/audit/receipt retention periods or permit deletion
of financial audit evidence; the existing category-specific policies govern those.

This decision resolves the missing selection of baseline targets and accountable
role. It does not claim provider capability, implemented encryption/retention,
an alternate assignee, measured production-scale recovery, deployed log controls,
or production activation. Those remain independently verifiable acceptance gates.
No deployed staging URL was supplied; deployment verification remains pending.
