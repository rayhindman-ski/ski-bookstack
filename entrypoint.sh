#!/bin/bash
# Write BookStack .env before LinuxServer init runs.
# LinuxServer only writes /config/www/.env if it does not already exist,
# so pre-creating it here with correct values prevents it from ever using defaults.
mkdir -p /config/www
cat > /config/www/.env << EOF
APP_KEY=${APP_KEY}
APP_URL=${APP_URL}

DB_HOST=bookstack_db
DB_PORT=3306
DB_DATABASE=${DB_DATABASE}
DB_USERNAME=${DB_USER}
DB_PASSWORD=${DB_PASS}

MAIL_DRIVER=smtp
MAIL_HOST=${SMTP_HOST}
MAIL_PORT=${SMTP_PORT}
MAIL_USERNAME=${SMTP_USER}
MAIL_PASSWORD=${SMTP_PASS}
MAIL_ENCRYPTION=${TLS_ENCRYPTION}
MAIL_FROM_ADDRESS=${SMTP_FROM_ADDR}
MAIL_FROM_NAME=BookStack
EOF

exec /init
