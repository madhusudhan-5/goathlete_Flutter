#!/bin/bash

# ==============================================================================
# GoAthlete Backend - Ubuntu Production Deployment & Update Script
# ==============================================================================
# Usage:
#   chmod +x deploy_ubuntu.sh
#   sudo ./deploy_ubuntu.sh
# ==============================================================================

set -e

# --- Configuration Variables ---
GIT_REPO="https://github.com/madhusudhan-5/goathlete_Flutter.git"
BRANCH="main"
APP_ROOT="/var/www/goathlete"
BACKEND_DIR="$APP_ROOT/goathlete_backend"
VENV_DIR="$APP_ROOT/venv"
DOMAIN="api.goathlete.com"
SERVER_IP="72.60.193.38"
SERVICE_NAME="goathlete"
APP_USER="${SUDO_USER:-ubuntu}"

echo "============================================================"
echo " Starting GoAthlete Backend Deployment on Ubuntu..."
echo " Server IP: $SERVER_IP | Domain: $DOMAIN"
echo " Target Directory: $APP_ROOT"
echo "============================================================"

# 1. Install System Dependencies
echo "[1/7] Installing system packages (Python, Nginx, Git, Certbot)..."
apt-get update -y
apt-get install -y python3 python3-pip python3-venv python3-dev \
    build-essential libjpeg-dev zlib1g-dev \
    git nginx curl certbot python3-certbot-nginx

# 2. Clone or Update Git Repository
echo "[2/7] Fetching code from Git ($GIT_REPO)..."
if [ ! -d "$APP_ROOT/.git" ]; then
    mkdir -p "$APP_ROOT"
    git clone -b "$BRANCH" "$GIT_REPO" "$APP_ROOT"
else
    cd "$APP_ROOT"
    git fetch origin "$BRANCH"
    git reset --hard "origin/$BRANCH"
fi

# 3. Setup Python Virtual Environment & Dependencies
echo "[3/7] Setting up Python virtual environment & installing requirements..."
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install -r "$BACKEND_DIR/requirements.txt"

# 4. Write or Update Production .env File
echo "[4/7] Configuring production environment (.env)..."
if [ ! -f "$BACKEND_DIR/.env" ]; then
    SECRET_KEY_GEN=$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')
    cat > "$BACKEND_DIR/.env" <<EOF
SECRET_KEY=${SECRET_KEY_GEN}
DEBUG=False
ALLOWED_HOSTS=${SERVER_IP},${DOMAIN},localhost,127.0.0.1
TWILIO_ACCOUNT_SID=${TWILIO_ACCOUNT_SID:-your_twilio_sid}
TWILIO_AUTH_TOKEN=${TWILIO_AUTH_TOKEN:-your_twilio_auth_token}
TWILIO_MESSAGING_SERVICE_SID=${TWILIO_MESSAGING_SERVICE_SID:-your_twilio_messaging_sid}
GOOGLE_OAUTH_CLIENT_ID=${GOOGLE_OAUTH_CLIENT_ID:-your_google_web_client_id}
GOOGLE_ANDROID_CLIENT_ID=${GOOGLE_ANDROID_CLIENT_ID:-your_google_android_client_id}
GOOGLE_OAUTH_SECRET=${GOOGLE_OAUTH_SECRET:-your_google_client_secret}
MAPS_API_KEY=${MAPS_API_KEY:-your_maps_api_key}
EOF
    echo "Created .env at $BACKEND_DIR/.env"
else
    # Ensure DEBUG=False and ALLOWED_HOSTS includes SERVER_IP
    sed -i "s/^DEBUG=.*/DEBUG=False/" "$BACKEND_DIR/.env" || true
    if ! grep -q "^ALLOWED_HOSTS=" "$BACKEND_DIR/.env"; then
        echo "ALLOWED_HOSTS=${SERVER_IP},${DOMAIN},localhost,127.0.0.1" >> "$BACKEND_DIR/.env"
    fi
    if ! grep -q "^SECRET_KEY=" "$BACKEND_DIR/.env"; then
        SECRET_KEY_GEN=$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')
        echo "SECRET_KEY=${SECRET_KEY_GEN}" >> "$BACKEND_DIR/.env"
    fi
    [ -n "$TWILIO_ACCOUNT_SID" ] && sed -i "s|^TWILIO_ACCOUNT_SID=.*|TWILIO_ACCOUNT_SID=${TWILIO_ACCOUNT_SID}|" "$BACKEND_DIR/.env"
    [ -n "$TWILIO_AUTH_TOKEN" ] && sed -i "s|^TWILIO_AUTH_TOKEN=.*|TWILIO_AUTH_TOKEN=${TWILIO_AUTH_TOKEN}|" "$BACKEND_DIR/.env"
    [ -n "$TWILIO_MESSAGING_SERVICE_SID" ] && sed -i "s|^TWILIO_MESSAGING_SERVICE_SID=.*|TWILIO_MESSAGING_SERVICE_SID=${TWILIO_MESSAGING_SERVICE_SID}|" "$BACKEND_DIR/.env"
    [ -n "$GOOGLE_OAUTH_CLIENT_ID" ] && sed -i "s|^GOOGLE_OAUTH_CLIENT_ID=.*|GOOGLE_OAUTH_CLIENT_ID=${GOOGLE_OAUTH_CLIENT_ID}|" "$BACKEND_DIR/.env"
    [ -n "$GOOGLE_ANDROID_CLIENT_ID" ] && sed -i "s|^GOOGLE_ANDROID_CLIENT_ID=.*|GOOGLE_ANDROID_CLIENT_ID=${GOOGLE_ANDROID_CLIENT_ID}|" "$BACKEND_DIR/.env"
    [ -n "$GOOGLE_OAUTH_SECRET" ] && sed -i "s|^GOOGLE_OAUTH_SECRET=.*|GOOGLE_OAUTH_SECRET=${GOOGLE_OAUTH_SECRET}|" "$BACKEND_DIR/.env"
    echo "Updated existing .env at $BACKEND_DIR/.env"
fi

# 5. Run Django Migrations, Collect Static & Seed Sport Configs
echo "[5/7] Running database migrations and collecting static files..."
cd "$BACKEND_DIR"
python manage.py makemigrations --noinput
python manage.py migrate --noinput
python manage.py collectstatic --noinput

# Optional: Seed initial sport templates if needed
if [ -f "seed_sport_configs.py" ]; then
    python seed_sport_configs.py || true
fi

# Set appropriate permissions for SQLite and media uploads
chown -R "$APP_USER":www-data "$APP_ROOT"
chmod -R 775 "$BACKEND_DIR"
if [ -f "$BACKEND_DIR/db.sqlite3" ]; then
    chmod 664 "$BACKEND_DIR/db.sqlite3"
fi
mkdir -p "$BACKEND_DIR/media"
chmod -R 775 "$BACKEND_DIR/media"

# 6. Configure Systemd Service for Gunicorn
echo "[6/7] Configuring Gunicorn systemd service ($SERVICE_NAME.service)..."
cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=Gunicorn daemon for GoAthlete Django Backend
After=network.target

[Service]
User=${APP_USER}
Group=www-data
WorkingDirectory=${BACKEND_DIR}
Environment="PATH=${VENV_DIR}/bin"
ExecStart=${VENV_DIR}/bin/gunicorn \\
    --access-logfile - \\
    --workers 3 \\
    --bind unix:${BACKEND_DIR}/${SERVICE_NAME}.sock \\
    goathlete_backend.wsgi:application
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

# 7. Configure Nginx Reverse Proxy
echo "[7/7] Configuring Nginx reverse proxy for $SERVER_IP & $DOMAIN..."
cat > "/etc/nginx/sites-available/${SERVICE_NAME}" <<EOF
server {
    listen 80;
    server_name ${SERVER_IP} ${DOMAIN} _;

    client_max_body_size 25M;

    location = /favicon.ico { access_log off; log_not_found off; }

    location /static/ {
        alias ${BACKEND_DIR}/staticfiles/;
    }

    location /media/ {
        alias ${BACKEND_DIR}/media/;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:${BACKEND_DIR}/${SERVICE_NAME}.sock;
    }
}
EOF

ln -sf "/etc/nginx/sites-available/${SERVICE_NAME}" "/etc/nginx/sites-enabled/"
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx

echo "============================================================"
echo " Deployment Complete!"
echo "------------------------------------------------------------"
echo " Gunicorn Status : $(systemctl is-active $SERVICE_NAME)"
echo " Nginx Status    : $(systemctl is-active nginx)"
echo ""
echo " Next Step for HTTPS (SSL):"
echo " Once your DNS A-record for $DOMAIN points to this server IP, run:"
echo "   sudo certbot --nginx -d $DOMAIN"
echo "============================================================"
