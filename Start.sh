#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${PWD}/setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

[[ "$(id -u)" -eq 0 ]] || { echo "ERROR: Start.sh должен запускаться от root."; exit 1; }
command -v apt-get >/dev/null 2>&1 || { echo "ERROR: поддерживается Debian/Ubuntu с apt-get."; exit 1; }

BACKEND_PORT=8080
FRONTEND_PORT=3000
DOMAIN=""
STORAGE_PATH="/var/lib/avidrive/storage"
DB_PATH="/var/lib/avidrive/data/filestorage.db"
SSL_ENABLED=false

ask() { local prompt="$1" default="$2" value; read -r -p "$prompt [$default]: " value; printf '%s' "${value:-$default}"; }
create_directories() { install -d -m 0750 "$STORAGE_PATH" "$(dirname "$DB_PATH")"; }
initialize_database() { install -d -m 0750 "$(dirname "$DB_PATH")"; DB_PATH="$DB_PATH" "$PWD/mode.sh" init-schema; }
validate_configuration() { [[ "$BACKEND_PORT" =~ ^[0-9]+$ && "$BACKEND_PORT" -ge 1 && "$BACKEND_PORT" -le 65535 ]] || { echo "ERROR: invalid backend port"; exit 1; }; [[ "$FRONTEND_PORT" =~ ^[0-9]+$ && "$FRONTEND_PORT" -ge 1 && "$FRONTEND_PORT" -le 65535 ]] || { echo "ERROR: invalid frontend port"; exit 1; }; }
ensure_apt_package() { apt-cache show "$1" >/dev/null 2>&1 || { echo "ERROR: package unavailable: $1"; exit 1; }; }
check_dependencies() { local packages=(openjdk-17-jdk maven nodejs npm sqlite3 curl git nginx certbot python3-certbot-nginx ufw unzip); apt-get update; for package in "${packages[@]}"; do ensure_apt_package "$package"; done; apt-get install -y "${packages[@]}"; }
create_config() { cat > /etc/avidrive.conf <<EOF
BACKEND_PORT=$BACKEND_PORT
FRONTEND_PORT=$FRONTEND_PORT
STORAGE_PATH=$STORAGE_PATH
DB_PATH=$DB_PATH
DOMAIN=$DOMAIN
SSL_ENABLED=$SSL_ENABLED
EOF
}
create_services() {
  cat > /etc/systemd/system/avidrive-backend.service <<EOF
[Unit]
Description=AviDrive backend
After=network.target
[Service]
WorkingDirectory=$PWD/backend
ExecStart=/usr/bin/mvn spring-boot:run -Dspring-boot.run.arguments=--server.port=$BACKEND_PORT
Restart=on-failure
User=root
[Install]
WantedBy=multi-user.target
EOF
  cat > /etc/systemd/system/avidrive-frontend.service <<EOF
[Unit]
Description=AviDrive frontend
After=network.target
[Service]
WorkingDirectory=$PWD/frontend
ExecStart=/usr/bin/npm run dev -- --host 0.0.0.0 --port $FRONTEND_PORT
Restart=on-failure
User=root
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload; systemctl enable avidrive-backend.service avidrive-frontend.service
}
configure_firewall() { ufw allow ssh; ufw allow 80/tcp; ufw allow 443/tcp; ufw allow "$BACKEND_PORT/tcp"; ufw allow "$FRONTEND_PORT/tcp"; echo "UFW rules added; firewall is NOT enabled automatically."; }
configure_ssl() { [[ -n "$DOMAIN" && "$SSL_ENABLED" == true ]] || return 0; certbot --nginx --non-interactive --agree-tos --register-unsafely-without-email -d "$DOMAIN"; }

if [[ -f /etc/avidrive.conf ]]; then source /etc/avidrive.conf; fi
printf 'AviDrive deployment wizard\n'
BACKEND_PORT="$(ask 'Backend port' "$BACKEND_PORT")"
FRONTEND_PORT="$(ask 'Frontend port' "$FRONTEND_PORT")"
DOMAIN="$(ask 'Domain (empty for HTTP)' "$DOMAIN")"
SSL_CHOICE="$(ask 'Enable SSL with certbot? (true/false)' "$SSL_ENABLED")"; SSL_ENABLED="$SSL_CHOICE"
STORAGE_PATH="$(ask 'Storage path' "$STORAGE_PATH")"

validate_configuration
check_dependencies
create_directories
create_config
( cd backend && mvn clean package -DskipTests )
initialize_database
( cd backend && mvn clean package -DskipTests )
( cd frontend && npm install && npm run build )
configure_ssl
create_services
configure_firewall
systemctl restart avidrive-backend.service avidrive-frontend.service
curl --fail --silent "http://127.0.0.1:$BACKEND_PORT/actuator/health" >/dev/null 2>&1 || echo "WARNING: backend health endpoint is not configured; verify service manually."
[[ -d "$STORAGE_PATH" && -f "$DB_PATH" || true ]]
echo "AviDrive installation completed. UFW remains disabled until manually enabled with: ufw enable"
