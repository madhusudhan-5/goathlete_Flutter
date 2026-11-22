#!/bin/bash

# ==============================================================================
# Build GoAthlete Customer Mobile/Tablet Web App (PWA)
# ==============================================================================
# Usage:
#   ./build_customer_web.sh
#   API_BASE_URL=https://api.goathelet.org.in WEB_APP_URL=https://app.goathelet.org.in ./build_customer_web.sh
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/goathlete_workspace/apps/customer_app"
OUT_DIR="$SCRIPT_DIR/dist_customer_web"

API_BASE_URL="${API_BASE_URL:-https://api.goathelet.org.in}"
WEB_APP_URL="${WEB_APP_URL:-https://app.goathelet.org.in}"
GOOGLE_WEB_CLIENT_ID="${GOOGLE_WEB_CLIENT_ID:-740629489616-c6j07tvj7gg7a6ulfpsu8tmptf151adu.apps.googleusercontent.com}"

echo "============================================================"
echo " Building GoAthlete Customer Web App (Phones & Tablets PWA)"
echo " API_BASE_URL : $API_BASE_URL"
echo " WEB_APP_URL  : $WEB_APP_URL"
echo "============================================================"

cd "$APP_DIR"
flutter pub get
flutter build web --release \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=WEB_APP_URL="$WEB_APP_URL" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="$GOOGLE_WEB_CLIENT_ID"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
cp -R "$APP_DIR/build/web/." "$OUT_DIR/"

echo "============================================================"
echo " Web build complete!"
echo " Output folder: $OUT_DIR"
echo ""
echo " To upload to your Ubuntu server:"
echo "   rsync -avz --delete $OUT_DIR/ ubuntu@72.60.193.38:/var/www/goathlete/customer_web/"
echo "============================================================"
