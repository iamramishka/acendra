# CSA-213 — Monitoring and alert activation plan

Status: IN_REVIEW, preparation only. Date: 2026-10-15 (Asia/Colombo).
Owner: CODEX; activation authority: project owner/designated operations maintainer.
Assignment: [preparation board](../tasks/CSA-211-216-PREPARATION.md).
Production target, provider, recipient and deployed telemetry are unverified.
Existing dummy deployment targets are placeholders and must not receive production data.

## Signals and proposed alert rules

All thresholds below are proposals requiring operations approval and staging calibration.
Absence of samples is unknown, never evidence of health. Measure rates with both a
numerator and denominator; low volume requires absolute failure signals as well.

| Signal | Proposed trigger | Response and acceptance test |
|---|---|---|
| Application/backend availability | Three failed synthetic probes at one-minute intervals; any missing probe stream for five minutes | Operations lead checks hosting/Auth/database dependencies. Inject synthetic failure and missing telemetry; prove delivery and recovery notification. |
| Backend/function errors | Five failures in five minutes, or >5% with at least 20 requests | Group by safe error class and release; inspect redacted logs. Inject known error; verify grouping and recovery. |
| Payment callbacks | Three processing failures in five minutes; any settlement/grant invariant violation immediately | Finance and operations reconcile authenticated provider evidence; preserve pending state. Replays must not produce duplicate fulfillment. |
| Bank approval and privileged actions | Any authorization/invariant failure; repeated denied privileged attempts (five in five minutes) | Security/finance review audit evidence. Test a synthetic denied actor without changing permissions. |
| Notification queue | Oldest eligible undelivered item >15 minutes, or five retry failures in five minutes | Inspect worker leases, provider availability and stable idempotency key. Email failure must not undo settlement. |
| Protected content/storage | Five unexpected delivery failures in five minutes; any public exposure immediately | Distinguish expected access denial from service failure. Probe synthetic authorized and unauthorized access; never put signed URLs in alerts. |
| Database capacity/latency | >80% of approved capacity for 15 minutes, or p95 above approved latency budget for five minutes | Inspect measured workload and provider limits; latency budget remains pending. Verify synthetic threshold crossing. |
| Backup failure/freshness | Any failed scheduled backup; newest independently validated recoverable set >18 hours old; >24 hours is RPO breach | Apply [backup plan](CSA-214-BACKUPS.md). Test failed job, stale set and absent heartbeat. Age must include objects and deletion ledger. |
| Secrets/audit integrity | Any detected credential exposure, unexpected privilege change or missing audit write | Security lead contains and rotates through authorized procedure; preserve minimal evidence. Test with inert marker only. |

## Configuration and evidence checklist

- [ ] Record actual project/environment, release revision and approved monitoring provider/account.
- [ ] Name primary and alternate recipients; confirm their monitored channels and on-call coverage with [recovery baseline](../decisions/CSA-200-RECOVERY-OPERATIONS-BASELINE.md).
- [ ] Approve thresholds, sampling, maintenance suppression, grouping and recovery rules. Retain immediate alerts for financial integrity and exposure.
- [ ] Capture allowlisted timestamp, environment, event type, request ID, safe resource reference and error classification. Exclude tokens, credentials, signed URLs, receipt bodies and unnecessary student/payment identifiers.
- [ ] Restrict diagnostic access, audit administrative access and enforce retention at most 30 days. Minimize further where sufficient.
- [ ] Configure independent missing-telemetry detection; test channel outage and escalation without contacting real students.
- [ ] Demonstrate each rule with synthetic events in isolated staging; record actual alert receipt, acknowledgement and resolution times.
- [ ] Verify approved rules are active on the actual production target and have a recent heartbeat; obtain authorized review before marking DONE.

Evidence record per rule: environment/project; configuration revision; reviewer;
signal source; trigger/recovery expression; synthetic event ID and UTC timestamp;
alert ID; delivery and acknowledgement times; redacted evidence location;
observed result; unresolved issue; approver. Store private evidence in restricted
operations storage; repository summaries contain no credentials or personal data.

This document configures no external service and proves no operational alert delivery.
