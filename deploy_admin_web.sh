#!/bin/bash

# ==============================================================================
# Deploy GoAthlete Admin Console Web App on Ubuntu (Nginx)
# ==============================================================================
# Usage on Ubuntu server:
#   chmod +x deploy_admin_web.sh
#   sudo WEB_DOMAIN=admin.goathlete.org.in ./deploy_admin_web.sh
# ==============================================================================

set -euo pipefail

WEB_DOMAIN="${WEB_DOMAIN:-admin.goathlete.org.in}"
WEB_ROOT="${WEB_ROOT:-/var/www/goathlete/admin_web}"
SITE_NAME="goathlete-admin-web"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================================"
echo " Configuring Nginx for GoAthlete Admin Console"
echo " Domain   : $WEB_DOMAIN"
echo " Web Root : $WEB_ROOT"
echo "============================================================"

mkdir -p "$WEB_ROOT"

if [ -d "$SCRIPT_DIR/dist_admin_web" ] && [ -f "$SCRIPT_DIR/dist_admin_web/index.html" ]; then
    echo "Copying dist_admin_web -> $WEB_ROOT ..."
    rm -rf "${WEB_ROOT:?}/"*
    cp -R "$SCRIPT_DIR/dist_admin_web/." "$WEB_ROOT/"
fi

chown -R root:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"

sed "s|server_name admin.goathlete.org.in;|server_name ${WEB_DOMAIN};|g; s|root /var/www/goathlete/admin_web;|root ${WEB_ROOT};|g" \
    "$SCRIPT_DIR/nginx/goathlete_admin_web.conf" > "/etc/nginx/sites-available/${SITE_NAME}"

ln -sf "/etc/nginx/sites-available/${SITE_NAME}" "/etc/nginx/sites-enabled/${SITE_NAME}"

nginx -t
systemctl reload nginx

echo "============================================================"
echo " Nginx configured for https://${WEB_DOMAIN}!"
echo " Enable HTTPS with:"
echo "   sudo certbot --nginx -d ${WEB_DOMAIN}"
echo "============================================================"
