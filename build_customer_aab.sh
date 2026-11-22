#!/bin/bash

# ==============================================================================
# Build Signed GoAthlete Customer Android App Bundle (.aab) for Play Console
# ==============================================================================
# Usage:
#   ./build_customer_aab.sh
#   API_BASE_URL=https://api.goathlete.org.in ./build_customer_aab.sh
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/goathlete_workspace/apps/customer_app"

API_BASE_URL="${API_BASE_URL:-https://api.goathlete.org.in}"
WEB_APP_URL="${WEB_APP_URL:-https://app.goathlete.org.in}"
GOOGLE_WEB_CLIENT_ID="${GOOGLE_WEB_CLIENT_ID:-740629489616-c6j07tvj7gg7a6ulfpsu8tmptf151adu.apps.googleusercontent.com}"

VERSION_NAME=$(grep -E '^version:' "$APP_DIR/pubspec.yaml" | awk '{print $2}' | cut -d'+' -f1)
OUT_FILE="$SCRIPT_DIR/GoAthlete_v${VERSION_NAME}_release.aab"

echo "============================================================"
echo " Building GoAthlete Customer Release AAB"
echo " Version      : $VERSION_NAME"
echo " API_BASE_URL : $API_BASE_URL"
echo " Output       : $OUT_FILE"
echo "============================================================"

cd "$APP_DIR"
flutter pub get
flutter build appbundle --release \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=WEB_APP_URL="$WEB_APP_URL" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="$GOOGLE_WEB_CLIENT_ID"

cp "$APP_DIR/build/app/outputs/bundle/release/app-release.aab" "$OUT_FILE"

echo "============================================================"
echo " AAB build complete!"
echo " File: $OUT_FILE"
ls -lh "$OUT_FILE"
echo "============================================================"
