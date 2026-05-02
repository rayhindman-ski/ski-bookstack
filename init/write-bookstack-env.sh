#!/bin/bash
# Runs on every container start (before the app boots) via /custom-cont-init.d/
# Overwrites /config/www/.env with values from Docker environment variables.
# This ensures the correct config is always used regardless of any cached values.

cat > /config/www/.env << EOF
APP_KEY=${APP_KEY}
APP_URL=${APP_URL}

DB_HOST=bookstack_db
DB_PORT=3306
DB_DATABASE=${DB_DATABASE}
DB_USERNAME=${DB_USER}
DB_PASSWORD=${DB_PASS}
EOF

echo "[init] BookStack .env written from environment variables."
