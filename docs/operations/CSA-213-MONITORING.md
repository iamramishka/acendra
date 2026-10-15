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

## Existing-service, zero-spend execution (2026-10-15)

The current user instruction permits existing services only, with missing features
held. Assignment: [free operations board](CSA-PHASE9-FREE-OPERATIONS-BOARD.md),
GitHub issue #160. Current authorized application targets are **staging**:
Supabase `worrsweluwjmppwsygre` and `https://acendra.vercel.app`.
They are not approved production targets. The plan and actual enabled capabilities
must be verified in their existing dashboards before use; no upgrade is authorized.

The following procedure uses existing consoles without adding a monitor or recipient:

1. In the existing Vercel project, inspect the deployment matching the accepted
   release SHA. Record deployment state, UTC inspection time and safe deployment ID.
   This Flutter static application has no Vercel runtime function merely because
   its frontend is deployed there. Deployment/build success is not backend health.
2. In [Supabase Logs](https://supabase.com/dashboard/project/worrsweluwjmppwsygre/logs/explorer),
   select a recent bounded interval and the relevant API/Auth/Edge Function source.
   Inspect aggregate failures and request IDs, never export raw receipt/callback
   bodies, Authorization headers or session credentials into GitHub artifacts.
3. Correlate an existing synthetic staging request with function and database audit
   evidence. Record expected access denials separately from unexpected server errors.
   Missing data means unknown. Do not repeatedly poll or generate keepalive traffic
   to prevent free-plan pausing.
4. Review [repository Actions](https://github.com/iamramishka/acendra/actions) for the
   exact release SHA and named Flutter/Supabase jobs. CI notifications are evidence
   of CI outcomes only, not production availability or payment failure alerts.
5. Record the result using the evidence template below. If there is no configured
   alert route with a named responder and receipt evidence, keep alert activation
   on hold. Do not add a paid drain, external service or scheduled automation.

| Requirement | Available free work | Operational hold |
|---|---|---|
| Failure diagnosis | Inspect existing bounded console logs and deployment/CI state | No demonstrated independent uptime or missing-telemetry detection |
| Sensitive log handling | Apply allowlisted summary fields and restricted console access | Actual retention, exports and access review require deployment evidence |
| Alert delivery | Document signal, responder and test criteria | No recipient/channel activation or delivery test performed |
| Production acceptance | Reuse this checklist once production is designated | Staging evidence cannot close CSA-213 production acceptance |

Evidence template (no private payloads): `inspection UTC; environment; release SHA;
source; interval; aggregate count; safe request ID; expected/observed outcome;
alert configuration ID or absent; recipient role; delivery evidence or not tested;
reviewer; follow-up`.

Capability references checked 2026-10-15: [Supabase Logs in Studio](https://supabase.com/docs/guides/observability/logs)
provides console diagnosis; [Vercel runtime logs](https://vercel.com/docs/logs/runtime)
describes runtime request/function logs. Console visibility alone does not implement
this plan's automated rules. Retention and entitlements can change; inspect the
existing account rather than assuming a paid tier or a fixed free retention period.

**Hold:** CSA-213 remains IN_REVIEW for preparation; production alert activation is
BLOCKED pending production designation, existing eligible telemetry capabilities,
named responders and observed delivery. No service was added or charged.
