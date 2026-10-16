# Phase 10 (proposed): Oracle Cloud ARM deployment

Date: 2026-10-16. Author: CLAUDE. Status: READY — owner-approved 2026-10-16.
Builds on: Phase 9 (PLAN.md §25), [CSA-205/206 hosting prep](CSA-205-206-HOSTING.md),
[CSA-012 budget](../decisions/CSA-012-ENVIRONMENTS-BUDGET.md).

This phase proposes Oracle Cloud Infrastructure (OCI) Always Free Ampere A1 as the
CSA-205 hosting provider. Task IDs CSA-253+ are proposed numbers; they become real
only after the project owner adds them to TASKS.md and opens GitHub Issues.

## Scope decision

| Component | Proposed host | Reason |
| --- | --- | --- |
| Flutter Web static build | OCI A1 VM + Nginx | Free, full header/fallback control |
| Supabase (DB, Auth, Storage, Edge Functions) | Supabase Cloud (unchanged) | Managed backups, RLS, auth; self-hosting adds ops risk to financial data |
| TLS | Let's Encrypt (Certbot) | Free, auto-renew |
| Hostname | Free `<ip-dashed>.sslip.io` on the VM's reserved public IP | No domain purchase; enables a Let's Encrypt cert. Bare `http://<IP>` is not acceptable for production (passwords and payment redirects over plaintext) |

Self-hosting Supabase on the VM is **out of scope** for this phase. It would move
bank receipts, payment state and backups onto an unmanaged single VM; revisit only
with a separate ADR.

## Cost reality

- Always Free A1: 4 OCPU / 24 GB RAM, 200 GB block, 10 TB egress/month — USD 0.
- Card verification is required at signup. Use Always-Free-tagged shapes only;
  trial-credit resources are billed after 30 days.
- Idle Always Free instances can be reclaimed by Oracle (low CPU/network over 7 days).
  Production must not rely on a single reclaimable VM without a tested rebuild path
  (CSA-259).
- A1 capacity is often unavailable in popular regions; region choice is a blocker.

## Proposed tasks

| ID | Title | Pri | Owner (proposed) | Depends on | Scope |
| --- | --- | --- | --- | --- | --- |
| CSA-253 | Oracle provider ADR + owner approval | P0 | Project owner | CSA-205 | `docs/decisions/` |
| CSA-254 | OCI tenancy, region, IAM, MFA, compartments (staging/prod) | P0 | Project owner | CSA-253 | Console only, record in docs |
| CSA-255 | Provision A1 VM, VCN, security list (22 restricted, 80/443 open) | P0 | CODEX | CSA-254 | `infra/oracle/**` |
| CSA-256 | VM hardening: SSH keys only, ufw/iptables, unattended-upgrades, fail2ban, non-root deploy user | P0 | CODEX | CSA-255 | `infra/oracle/**` |
| CSA-257 | Nginx config: SPA fallback, cache headers, CSP/HSTS/security headers, gzip/brotli | P1 | CLAUDE | CSA-255 | `infra/oracle/nginx/**` |
| CSA-258 | Reserved public IP + sslip.io hostname + Let's Encrypt TLS with auto-renew test | P0 | CODEX | CSA-257 | `infra/oracle/**`, docs |
| CSA-259 | Infra-as-code / rebuild script (cloud-init or Terraform OCI provider) | P1 | CODEX | CSA-256 | `infra/oracle/**` |
| CSA-260 | GitHub Actions deploy: build web (public defines only) → asset secret scan → rsync to versioned release dir → atomic symlink switch | P0 | CLAUDE | CSA-257 | `.github/workflows/deploy-oracle.yml` (shared, lock required) |
| CSA-261 | Rollback: keep last N releases, one-command symlink rollback, rehearsed in staging | P0 | CLAUDE | CSA-260 | `infra/oracle/scripts/**` |
| CSA-262 | Monitoring: uptime check, TLS expiry alert, disk/CPU alert, idle-reclaim keepalive review | P1 | CODEX | CSA-213, CSA-258 | `docs/operations/` |
| CSA-263 | Staging release + smoke tests (deep links, refresh, auth redirect URLs, PDF reader, checkout against staging Supabase) | P0 | CLAUDE | CSA-260 | `integration_test/**`, docs |
| CSA-264 | Production go-live checklist + owner release approval | P0 | Project owner | CSA-261, CSA-262, CSA-263 | docs |

## Security gates

- Only `SUPABASE_URL` and publishable/anon key are passed as `--dart-define`; the
  build artifact is scanned for service-role keys before upload (CSA-260).
- Deploy SSH key is a GitHub environment secret scoped to the `production`
  environment with required reviewers; it never runs on PR workflows.
- The VM holds no Supabase secrets, no payment secrets and no student data.
- Supabase Auth redirect/site URL allowlists are updated to the new origin only.
- No claim that hosting protects PDFs; access control stays in Supabase.

## Exit gate

- [ ] CSA-253 ADR approved by project owner.
- [ ] Staging and production VMs rebuilt from CSA-259 at least once.
- [ ] HTTPS A+ grade, security headers verified, deep-link refresh works.
- [ ] Deploy and rollback each executed in staging with recorded evidence.
- [ ] Asset secret scan passes on the release artifact.
- [ ] Monitoring alerts fire in a test.
- [ ] Owner release approval recorded (CSA-264).

## Provisioned resources (2026-10-16)

Provisioned by CLAUDE via OCI console (Singapore region, ap-singapore-1):

| Resource | Name | OCID / details |
| --- | --- | --- |
| Compartment | acendra-prod | ocid1...q4pvspbbtza |
| Compartment | acendra-staging | ocid1...31yg4fchivwa |
| VCN | acendra-prod-vcn | ocid1.vcn.oc1.ap-singapore-1.amaaaaaatykyvsianbwmmzb3cwsjs7akdpjozaet3bqj3vkpgz4wld6if6ha |
| Public subnet | public subnet-acendra-prod-vcn | 10.0.0.0/24 |
| Private subnet | private subnet-acendra-prod-vcn | 10.0.1.0/24 |
| Internet gateway | Internet gateway-acendra-prod-vcn | — |
| NAT gateway | NAT gateway-acendra-prod-vcn | — |
| Service gateway | Service gateway-acendra-prod-vcn | — |

### VM provisioning — BLOCKED (capacity + region limit)

Instance `acendra-prod-web` (VM.Standard.A1.Flex, Ubuntu 24.04, compartment acendra-prod,
VCN acendra-prod-vcn, public subnet) was configured and submitted but rejected with:

> Out of capacity for shape VM.Standard.A1.Flex in availability domain AD-1.

**Singapore blocker**: Singapore (ap-singapore-1) has a single AD (AD-1) and A1.Flex
capacity is currently exhausted — a well-known and common OCI issue.

**Mumbai blocker**: Attempted to switch to ap-mumbai-1. The Free Trial tenancy has a
**1-region limit** (home region only). Mumbai is "Not subscribed" and subscription is
blocked by the tenancy quota — confirmed via Region Management page and a live navigation
test showing "Tenancy not subscribed to this region."

**SSH key pair** was generated and downloaded to the `sshkeys/` folder (git-ignored).

**Options for owner (choose one):**

| Option | Cost | Speed | Action required |
| --- | --- | --- | --- |
| A — Keep retrying Singapore | $0 | Hours–days | None; just retry |
| B — Request region limit increase | $0 | 1–3 business days | OCI Support ticket |
| C — Upgrade account to PAYG | $0 (Always Free resources stay free) | Minutes | Confirm billing in OCI console; no charge if only Always Free shapes used |
| D — Different free host | $0 | Today | Switch provider (see below) |

**Option C details** — upgrading from Free Trial to Pay-as-you-go:
- Go to: Billing → Upgrade and Manage Payment → Upgrade account
- You keep all Always Free resources (4 OCPU / 24 GB A1, etc.) forever at $0
- You can then subscribe to Mumbai and create the VM immediately
- Risk: if you accidentally create a paid resource, you will be charged

**Option D alternatives** (no region-limit issue):
- **Fly.io** — free hobby Machines (256 MB, limited), easy deploy; not Always Free for larger sizes
- **Oracle Sign Up Again** — new OCI account with a different home region (Mumbai or Hyderabad) chosen at signup; your current tenancy compartments/VCN are in Singapore only
- **Hetzner / DigitalOcean / Vultr** — ~USD 4-6/mo for a real VPS with consistent availability

---

## AWS EC2 pivot — INSTANCE RUNNING (2026-10-16)

OCI capacity exhausted in Singapore (both A1.Flex and E2.1.Micro out of capacity in AD-1).
Owner created an AWS account ("Whimsical Whiteboard", account 091199627656) with $100 credits
valid 183 days. Pivoted to AWS EC2 t3.micro in ap-southeast-2 (Sydney).

### AWS provisioned resources

| Resource | Value |
| --- | --- |
| Instance name | acendra-prod-web |
| Instance ID | i-01d881474132dd4ca |
| Instance type | t3.micro (2 vCPU, 1 GB RAM) — Free Tier eligible |
| AMI | Canonical Ubuntu 26.04 LTS amd64 (ami-06259b63260eddc13) |
| Region | ap-southeast-2 (Sydney) |
| **Public IPv4** | **3.25.99.105** |
| State | Running ✅ |
| Security group | launch-wizard-1 (SSH 22 + HTTP 80 + HTTPS 443, all from 0.0.0.0/0) |
| Key pair | None (SSH key injected via cloud-init — see below) |
| Storage | 8 GiB gp3 (root volume) |
| sslip.io hostname | 3-25-99-105.sslip.io |

### SSH access

SSH key injected via cloud-init User Data at instance launch:
- User: `ubuntu`
- Key: `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPbMfRpF/A6erkZpFhUR/Ms3+J4CYHn1dyb3Lg0WEywX ramishkam@sunketa.com`

Connect with:
```bash
ssh ubuntu@3.25.99.105
```

### Note on free tier

AWS t3.micro is free for **12 months only** (750 hours/month). The $100 credits cover costs
beyond the free tier and extend usability. This is not "free forever" like OCI Always Free —
budget for the post-12-month cost (~USD 8–10/month for t3.micro + EBS) or migrate to a
permanent free host before the 12-month mark.

### Pending next steps

- [ ] SSH in and verify cloud-init ran (check `~/.ssh/authorized_keys`)
- [ ] CSA-256: VM hardening (ufw, fail2ban, unattended-upgrades, non-root deploy user)
- [ ] CSA-257: Install Nginx + SPA fallback config + security headers
- [ ] CSA-258: Let's Encrypt TLS on `3-25-99-105.sslip.io` via Certbot
- [ ] Allocate an Elastic IP (to pin the IP across stop/start)
- [ ] CSA-260: GitHub Actions deploy pipeline
- [ ] CSA-261: Rollback mechanism
- [ ] CSA-263: Staging smoke tests

---

## Open decisions for the owner

1. ~~Approve OCI as hosting provider~~ → Pivoted to AWS EC2 (see above).
2. ~~Region selection~~ → ap-southeast-2 (Sydney) running.
3. Separate staging VM, or staging on the same VM under a second server block?
4. Accept the sslip.io hostname (`3-25-99-105.sslip.io`) for launch; a custom domain can be added later without rebuilding.
5. Supabase free tier limits (pauses when idle, 500 MB DB, 1 GB storage, no backups): accept for staging/early launch, or budget Supabase Pro.
6. Allocate an AWS Elastic IP to keep the public IP stable across stop/start cycles.
