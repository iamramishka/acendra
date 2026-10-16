# CSA-256: VM Setup & Hardening — AWS EC2 acendra-prod-web

Date: 2026-10-16. Author: CLAUDE. Status: IN_PROGRESS.
Depends on: [PHASE-10-ORACLE-ARM-PLAN.md](PHASE-10-ORACLE-ARM-PLAN.md)

---

## Instance details

| Field | Value |
| --- | --- |
| Instance name | acendra-prod-web |
| Instance ID | i-01d881474132dd4ca |
| Provider | AWS EC2 |
| Region | ap-southeast-2 (Sydney) |
| Type | t3.micro (2 vCPU, 1 GB RAM) |
| AMI | Canonical Ubuntu 26.04 LTS amd64 (ami-06259b63260eddc13) |
| **Public IPv4** | **3.25.99.105** |
| sslip.io hostname | 3-25-99-105.sslip.io |
| Account | Whimsical Whiteboard (091199627656) |
| Console URL | https://091199627656-hifxvwze.ap-southeast-2.console.aws.amazon.com/ec2/home?region=ap-southeast-2#InstanceDetails:instanceId=i-01d881474132dd4ca |

## SSH access

Default OS user: `ubuntu` (Canonical Ubuntu default).
SSH key injected at launch via cloud-init User Data:

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPbMfRpF/A6erkZpFhUR/Ms3+J4CYHn1dyb3Lg0WEywX ramishkam@sunketa.com
```

Private key location (local): `C:\Users\ramis\.ssh\id_ed25519`

**Connect:**
```bash
ssh ubuntu@3.25.99.105
```

SSH verified working: 2026-10-16.

---

## Security group (launch-wizard-1)

| Port | Protocol | Source | Purpose |
| --- | --- | --- | --- |
| 22 | TCP | 0.0.0.0/0 | SSH (restrict to your IP after hardening) |
| 80 | TCP | 0.0.0.0/0 | HTTP → redirects to HTTPS |
| 443 | TCP | 0.0.0.0/0 | HTTPS |

---

## Hardening steps (CSA-256)

### Step 1 — System update + unattended-upgrades

```bash
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

Status: ✅ complete (2026-10-16)

### Step 2 — ufw firewall

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
sudo ufw status verbose
```

Status: ✅ complete (2026-10-16)

### Step 3 — fail2ban

```bash
sudo apt-get install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
sudo fail2ban-client status sshd
```

Status: ✅ complete (2026-10-16)

### Step 4 — Non-root deploy user

```bash
sudo useradd -m -s /bin/bash deploy
sudo mkdir -p /home/deploy/.ssh
sudo cp /home/ubuntu/.ssh/authorized_keys /home/deploy/.ssh/authorized_keys
sudo chown -R deploy:deploy /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh
sudo chmod 600 /home/deploy/.ssh/authorized_keys
# Allow deploy to reload nginx without password
echo 'deploy ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload nginx, /usr/bin/systemctl reload-or-restart nginx' | sudo tee /etc/sudoers.d/deploy-nginx
sudo chmod 440 /etc/sudoers.d/deploy-nginx
```

Deploy user has SSH access with the same key as ubuntu.
Web root: `/var/www/acendra/current` (symlink — see CSA-260).

Status: ✅ complete (2026-10-16)

---

## Nginx setup (CSA-257)

### Install Nginx

```bash
sudo apt-get install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
```

### Web root structure

```
/var/www/acendra/
  releases/          # versioned release dirs (YYYYMMDD-HHMMSS)
  current -> releases/YYYYMMDD-HHMMSS   # atomic symlink
```

```bash
sudo mkdir -p /var/www/acendra/releases
sudo chown -R deploy:deploy /var/www/acendra
```

### Nginx site config

Created at `/etc/nginx/sites-available/acendra`:

```nginx
server {
    listen 80;
    server_name 3-25-99-105.sslip.io 3.25.99.105;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name 3-25-99-105.sslip.io;

    root /var/www/acendra/current;
    index index.html;

    ssl_certificate     /etc/letsencrypt/live/3-25-99-105.sslip.io/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/3-25-99-105.sslip.io/privkey.pem;
    include             /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;

    # SPA fallback — deep links work on refresh
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache Flutter build hashes forever, index.html never
    location ~* \.(js|css|wasm|png|jpg|svg|ico|woff2|ttf)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    location = /index.html {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    # Security headers
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;

    # Gzip
    gzip on;
    gzip_types text/plain text/css application/javascript application/json image/svg+xml;
    gzip_min_length 1024;
}
```

Status: ✅ complete (2026-10-16)

---

## TLS — Let's Encrypt via Certbot (CSA-258)

```bash
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d 3-25-99-105.sslip.io --non-interactive --agree-tos -m ramishka.madhushan@zettab.io
# Verify auto-renew timer
sudo systemctl status certbot.timer
sudo certbot renew --dry-run
```

Status: ✅ complete (2026-10-16)

---

## Elastic IP (recommended)

AWS EC2 public IPs change on stop/start. Allocate an Elastic IP to keep 3.25.99.105 stable:

1. EC2 Console → Elastic IPs → Allocate Elastic IP address
2. Associate with instance i-01d881474132dd4ca
3. Update sslip.io reference and Let's Encrypt cert if IP changes.

Status: PENDING — owner action required (optional but recommended).

---

## Post-hardening SSH restriction (optional but recommended)

After Elastic IP is stable, restrict port 22 in the security group to your home/office IP:

EC2 Console → Security Groups → launch-wizard-1 → Edit inbound rules →
SSH rule source: `<your-public-ip>/32`

---

## Next tasks

- CSA-260: GitHub Actions deploy pipeline
- CSA-261: Rollback mechanism (keep last 5 releases, `deploy-rollback.sh`)
- CSA-263: Staging smoke tests
- CSA-264: Production go-live checklist
