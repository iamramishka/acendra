#!/usr/bin/env bash
# rollback.sh — switch /var/www/acendra/current to a previous release
# Run on the server as the deploy user:
#   bash rollback.sh          → rolls back to the previous release
#   bash rollback.sh list     → lists available releases
#   bash rollback.sh <dir>    → switches to a specific release directory name

set -euo pipefail

RELEASES_DIR="/var/www/acendra/releases"
CURRENT_LINK="/var/www/acendra/current"

list_releases() {
  echo "Available releases (newest first):"
  ls -dt "${RELEASES_DIR}"/*/  | while read -r dir; do
    name=$(basename "$dir")
    if [ "$(readlink -f "${CURRENT_LINK}")" = "$(realpath "$dir")" ]; then
      echo "  ${name}  ← current"
    else
      echo "  ${name}"
    fi
  done
}

if [ "${1:-}" = "list" ]; then
  list_releases
  exit 0
fi

if [ -n "${1:-}" ]; then
  TARGET="${RELEASES_DIR}/${1}"
else
  # Default: the release before the current one
  CURRENT=$(readlink -f "${CURRENT_LINK}")
  TARGET=$(ls -dt "${RELEASES_DIR}"/*/ | grep -v "^${CURRENT}/$" | head -1)
  TARGET="${TARGET%/}"
fi

if [ ! -d "${TARGET}" ]; then
  echo "ERROR: Release directory not found: ${TARGET}"
  list_releases
  exit 1
fi

echo "Rolling back to: $(basename "${TARGET}")"
ln -s "${TARGET}" "${CURRENT_LINK}.next"
mv -T "${CURRENT_LINK}.next" "${CURRENT_LINK}"
sudo systemctl reload nginx
echo "Done. Live: $(basename "$(readlink -f "${CURRENT_LINK}")")"
