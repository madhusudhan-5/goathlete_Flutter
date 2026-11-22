#!/bin/bash

# ==============================================================================
# Deploy GoAthlete Customer Mobile/Tablet Web App on Ubuntu (Nginx)
# ==============================================================================
# Usage on Ubuntu server:
#   chmod +x deploy_customer_web.sh
#   sudo WEB_DOMAIN=app.goathelet.org.in ./deploy_customer_web.sh
# ==============================================================================

set -euo pipefail

WEB_DOMAIN="${WEB_DOMAIN:-app.goathelet.org.in}"
WEB_ROOT="${WEB_ROOT:-/var/www/goathlete/customer_web}"
SITE_NAME="goathlete-customer-web"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_USER="${SUDO_USER:-ubuntu}"

echo "============================================================"
echo " Configuring Nginx for GoAthlete Customer Web App"
echo " Domain   : $WEB_DOMAIN"
echo " Web Root : $WEB_ROOT"
echo "============================================================"

mkdir -p "$WEB_ROOT"

# If a prebuilt dist_customer_web folder is present in the repo, sync it
if [ -d "$SCRIPT_DIR/dist_customer_web" ] && [ -f "$SCRIPT_DIR/dist_customer_web/index.html" ]; then
    echo "Copying dist_customer_web -> $WEB_ROOT ..."
    rm -rf "${WEB_ROOT:?}/"*
    cp -R "$SCRIPT_DIR/dist_customer_web/." "$WEB_ROOT/"
fi

chown -R "$APP_USER":www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"

sed "s|server_name app.goathelet.org.in;|server_name ${WEB_DOMAIN};|g; s|root /var/www/goathlete/customer_web;|root ${WEB_ROOT};|g" \
    "$SCRIPT_DIR/nginx/goathlete_customer_web.conf" > "/etc/nginx/sites-available/${SITE_NAME}"

ln -sf "/etc/nginx/sites-available/${SITE_NAME}" "/etc/nginx/sites-enabled/${SITE_NAME}"

nginx -t
systemctl reload nginx

echo "============================================================"
echo " Nginx configured for https://${WEB_DOMAIN}!"
echo ""
echo " IMPORTANT — Enable HTTPS (required for iOS PWA, GPS & QR camera):"
echo "   sudo certbot --nginx -d ${WEB_DOMAIN}"
echo ""
echo " Also add https://${WEB_DOMAIN} to Authorized JavaScript Origins"
echo " in Google Cloud Console for Google Sign-In on Web."
echo "============================================================"
