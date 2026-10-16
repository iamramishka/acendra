# CSA-260: GitHub Actions Deploy Pipeline

Date: 2026-10-16. Author: CLAUDE. Status: READY — pending GitHub Secrets setup.

Workflow file: `.github/workflows/deploy-production.yml`

---

## How it works

Push to `dev` with the word **"deploy"** anywhere in the commit message →
GitHub Actions automatically:

1. Checks out the code
2. Runs `flutter analyze` + `flutter test`
3. Builds `flutter build web --release` with Supabase URL/anon key
4. Scans the build output for service-role keys (fails the pipeline if found)
5. Rsyncs `build/web/` to a timestamped release dir on the server
6. Atomically switches the `current` symlink
7. Reloads Nginx
8. Runs a smoke test (HTTP 200 on `https://3-25-99-105.sslip.io`)

**Commits without "deploy" in the message are ignored** — CI runs (analyze + test)
still fire via `flutter-ci.yml`, but nothing is deployed.

### Example commits that trigger deploy

```
feat(marketplace): add course grid deploy
fix(checkout): fix price display deploy
chore: update deps deploy
```

### Example commits that do NOT deploy

```
feat(marketplace): add course grid
fix(checkout): fix price display
```

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
