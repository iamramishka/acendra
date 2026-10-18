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
DEPLOY_DIR="/var/www/acendra/.deploy"
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

echo "==> Creating deploy-only staging directory $DEPLOY_DIR ..."
# The candidate config is installed as root by sudo, so it must be staged where
# only the deploy user can write (never world-writable /tmp).
if [ -n "$(find /var/www/acendra -maxdepth 0 -perm /022 -print)" ]; then
    echo "ERROR: /var/www/acendra must not be group- or world-writable." >&2
    exit 1
fi
install -d -o "$DEPLOY_USER" -g "$DEPLOY_USER" -m 700 "$DEPLOY_DIR"

echo "==> Granting $DEPLOY_USER limited sudo for Nginx config updates ..."
SUDOERS_TMP="$(mktemp)"
cat > "$SUDOERS_TMP" <<SUDOEOF
# Allows the deploy user to update the Nginx site config (with backup and
# rollback) and reload Nginx. Written by setup-ssl.sh — do not edit by hand.
$DEPLOY_USER ALL=(root) NOPASSWD: /usr/bin/install -m 644 $NGINX_SITE $NGINX_SITE.bak
$DEPLOY_USER ALL=(root) NOPASSWD: /usr/bin/install -m 644 $DEPLOY_DIR/nginx.conf $NGINX_SITE
$DEPLOY_USER ALL=(root) NOPASSWD: /usr/bin/install -m 644 $NGINX_SITE.bak $NGINX_SITE
$DEPLOY_USER ALL=(root) NOPASSWD: /usr/sbin/nginx -t
$DEPLOY_USER ALL=(root) NOPASSWD: /bin/systemctl reload nginx
SUDOEOF
# Never install a sudoers file that fails validation.
visudo -cf "$SUDOERS_TMP"
install -m 440 -o root -g root "$SUDOERS_TMP" /etc/sudoers.d/acendra-deploy
rm -f "$SUDOERS_TMP"

echo ""
echo "Done. HTTPS is live at https://$DOMAIN"
echo "Every future deploy will refresh the Nginx config automatically."
