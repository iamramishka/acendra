#!/usr/bin/env bash
# Acendra — one-time SSL and Nginx setup
# Run as root (or with sudo) on the production server ONCE before the first deploy.
# After this script succeeds, every deploy automatically reloads the Nginx config.
#
# Usage:
#   sudo bash setup-ssl.sh
#
# Prerequisites: Ubuntu 22.04/24.04, Nginx already installed, port 80 reachable.
set -euo pipefail

DOMAIN="3-25-99-105.sslip.io"
EMAIL="ramishka.madhushan@zettab.io"
DEPLOY_USER="deploy"
NGINX_SITE="/etc/nginx/sites-available/acendra"
NGINX_ENABLED="/etc/nginx/sites-enabled/acendra"
CERTBOT_WEBROOT="/var/www/certbot"

echo "==> Installing certbot ..."
apt-get update -q
apt-get install -y certbot

echo "==> Creating ACME challenge directory ..."
mkdir -p "$CERTBOT_WEBROOT"
chown -R www-data:www-data "$CERTBOT_WEBROOT"

echo "==> Installing temporary HTTP-only Nginx config for ACME challenge ..."
cat > "$NGINX_SITE" <<NGINXEOF
server_tokens off;
server {
    listen 80;
    server_name $DOMAIN;
    location /.well-known/acme-challenge/ { root $CERTBOT_WEBROOT; }
    location / { return 503; }
}
NGINXEOF
ln -sf "$NGINX_SITE" "$NGINX_ENABLED"
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

echo "==> Obtaining Let's Encrypt certificate for $DOMAIN ..."
certbot certonly \
    --webroot \
    --webroot-path "$CERTBOT_WEBROOT" \
    --domain "$DOMAIN" \
    --email "$EMAIL" \
    --agree-tos \
    --non-interactive

echo "==> Installing production Nginx config (HTTPS + security headers) ..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
install -m 644 "$SCRIPT_DIR/nginx.conf" "$NGINX_SITE"
nginx -t
systemctl reload nginx

echo "==> Configuring automatic certificate renewal ..."
cat > /etc/cron.d/certbot-acendra <<CRONEOF
0 3 * * * root certbot renew --quiet --deploy-hook "systemctl reload nginx"
CRONEOF

echo "==> Granting $DEPLOY_USER limited sudo for Nginx config updates ..."
cat > /etc/sudoers.d/acendra-deploy <<SUDOEOF
# Allows the deploy user to update the Nginx site config and reload Nginx.
# Written by setup-ssl.sh — do not edit by hand.
$DEPLOY_USER ALL=(root) NOPASSWD: /usr/bin/install -m 644 /tmp/acendra-nginx.conf $NGINX_SITE
$DEPLOY_USER ALL=(root) NOPASSWD: /usr/sbin/nginx -t
$DEPLOY_USER ALL=(root) NOPASSWD: /bin/systemctl reload nginx
SUDOEOF
chmod 440 /etc/sudoers.d/acendra-deploy

echo ""
echo "Done. HTTPS is live at https://$DOMAIN"
echo "Every future deploy will refresh the Nginx config automatically."
