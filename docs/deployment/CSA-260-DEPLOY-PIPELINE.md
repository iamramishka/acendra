# CSA-260: GitHub Actions Deploy Pipeline

Date: 2026-10-16. Author: CLAUDE. Status: READY — pending GitHub Secrets setup.

Workflow file: `.github/workflows/deploy-production.yml`

---

## How it works

Updated 2026-10-18 for Audit-001 (deploy no longer bypasses CI).

Push to `dev` → `Flutter baseline` (`flutter-ci.yml`) runs. **Only if it
succeeds**, `Deploy to Production` starts and waits for approval on the
`production` environment. After approval it:

1. Checks out the exact commit CI tested (`workflow_run.head_sha`)
2. Uses Flutter 3.44.0 and `--enforce-lockfile`, same as CI
3. Runs `flutter analyze` + `flutter test`
4. Builds `flutter build web --release` with Supabase URL/anon key
5. Scans the build output for service-role keys (fails the pipeline if found)
6. Rsyncs `build/web/` to a timestamped release dir on the server
7. Atomically switches the `current` symlink
8. Reloads Nginx
9. Runs a smoke test

The commit message no longer matters. The old `deploy` keyword does nothing.

- CI failed or was cancelled → no deploy.
- Pull-request CI runs → no deploy.
- Deploys never overlap; a newer one waits for the running one.
- To redeploy a commit: Actions → Deploy to Production → that run →
  **Re-run jobs**.
- To skip deploying a commit: **Reject** it on the approval prompt.

### Required one-time setting (project owner)

GitHub → Settings → Environments → `production` (created on first run if
missing) → **Required reviewers** → add the project owner → Save.

Without a required reviewer, every green push to `dev` deploys
automatically. The environment is the approval gate.

---

## Required GitHub Secrets

Go to: **GitHub → repository → Settings → Secrets and variables → Actions → New repository secret**

| Secret name | Value | Where to get it |
| --- | --- | --- |
| `DEPLOY_SSH_PRIVATE_KEY` | Content of `C:\Users\ramis\.ssh\id_ed25519` | Run `type C:\Users\ramis\.ssh\id_ed25519` in PowerShell — paste the entire output including `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----` |
| `DEPLOY_HOST` | `3.25.99.105` | EC2 instance public IP |
| `DEPLOY_USER` | `deploy` | Non-root user created during hardening |
| `SUPABASE_URL` | `https://<your-project>.supabase.co` | Supabase dashboard → Project Settings → API |
| `SUPABASE_ANON_KEY` | `eyJ...` (anon/public key only) | Supabase dashboard → Project Settings → API → `anon` key |

**Never add `SUPABASE_SERVICE_ROLE_KEY` or any payment secret here.**

---

## How to add DEPLOY_SSH_PRIVATE_KEY

The private key is at `C:\Users\ramis\.ssh\id_ed25519` on your Windows machine.

In PowerShell:
```powershell
Get-Content C:\Users\ramis\.ssh\id_ed25519 | Set-Clipboard
```

Then paste the clipboard into the GitHub Secret value field.
It will look like:
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXkAAAA...
...many lines...
-----END OPENSSH PRIVATE KEY-----
```

---

## Rollback

SSH to the server and run:

```bash
ssh ubuntu@3.25.99.105
sudo -u deploy bash /home/deploy/rollback.sh list   # see available releases
sudo -u deploy bash /home/deploy/rollback.sh         # roll back to previous
sudo -u deploy bash /home/deploy/rollback.sh 20261016-153000  # specific release
```

The server keeps the last 5 releases; older ones are pruned automatically on each deploy.

---

## First deploy checklist

- [ ] Add all 5 GitHub Secrets listed above
- [ ] Confirm `SUPABASE_URL` and `SUPABASE_ANON_KEY` are the staging values first
- [ ] Make a commit to `dev` with "deploy" in the message
- [ ] Watch the Actions tab → "Deploy to Production" workflow
- [ ] Check `https://3-25-99-105.sslip.io` loads the Flutter app
- [ ] Verify deep links work (navigate to a route, hit browser refresh)
- [ ] Verify Supabase auth redirect URL includes `https://3-25-99-105.sslip.io`

---

## Supabase Auth redirect URL

Add `https://3-25-99-105.sslip.io` to the Supabase Auth allowed redirect URLs:

Supabase dashboard → Authentication → URL Configuration →
**Site URL**: `https://3-25-99-105.sslip.io`
**Redirect URLs**: add `https://3-25-99-105.sslip.io/**`
