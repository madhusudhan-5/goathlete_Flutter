#!/bin/bash

# ==============================================================================
# Build GoAthlete Admin Console Web App
# ==============================================================================
# Usage:
#   ./build_admin_web.sh
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/goathlete_workspace/apps/admin_console"
OUT_DIR="$SCRIPT_DIR/dist_admin_web"

API_BASE_URL="${API_BASE_URL:-https://api.goathlete.org.in}"

echo "============================================================"
echo " Building GoAthlete Admin Console Web App"
echo " API_BASE_URL : $API_BASE_URL"
echo "============================================================"

cd "$APP_DIR"
flutter pub get
flutter build web --release \
  --dart-define=API_BASE_URL="$API_BASE_URL"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
cp -R "$APP_DIR/build/web/." "$OUT_DIR/"

echo "============================================================"
echo " Admin Web build complete!"
echo " Output folder: $OUT_DIR"
echo ""
echo " To upload to your Ubuntu server:"
echo "   rsync -avz --delete $OUT_DIR/ root@72.60.193.38:/var/www/goathlete/admin_web/"
echo "============================================================"
