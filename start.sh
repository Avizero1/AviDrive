#!/usr/bin/env bash
set -Eeuo pipefail

# AviDrive Ubuntu/Debian installer. Run as root: ./start.sh [--dry-run]
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_USER="${AVIDRIVE_USER:-avidrive}"
BACKEND_PORT="${BACKEND_PORT:-8080}"
FRONTEND_PORT="${FRONTEND_PORT:-3000}"
DOMAIN="${AVIDRIVE_DOMAIN:-_}"
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

log(){ printf '\033[1;36m[AviDrive]\033[0m %s\n' "$*"; }
run(){ if ((DRY_RUN)); then printf '+ %q' "$@"; printf '\n'; else "$@"; fi; }
die(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need_root(){ [[ "$(id -u)" == 0 ]] || die "run as root; sudo is intentionally not used"; }
check_os(){ [[ -r /etc/os-release ]] || die "Ubuntu/Debian required"; . /etc/os-release; [[ "$ID" == ubuntu || "$ID_LIKE" == *debian* ]] || die "Ubuntu/Debian required"; }
check_port(){ local p="$1"; if command -v ss >/dev/null && ss -ltnH "sport = :$p" | grep -q .; then die "port $p is already in use"; fi; }

install_packages(){
  log "Installing required packages (sqlite3 is intentionally excluded)"
  run apt-get update
  run env DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-17-jdk maven nodejs npm nginx certbot python3-certbot-nginx curl ca-certificates ufw
}
prepare_user(){
  id "$APP_USER" >/dev/null 2>&1 || run useradd --system --home /var/lib/avidrive --create-home --shell /usr/sbin/nologin "$APP_USER"
  run install -d -o "$APP_USER" -g "$APP_USER" "$ROOT/storage" "$ROOT/data"
}
build_app(){
  log "Building backend and frontend"
  run mvn -q -DskipTests package
  (cd "$ROOT/frontend" && run npm install && run npm run build)
  run chown -R "$APP_USER:$APP_USER" "$ROOT/storage" "$ROOT/data" "$ROOT/target"
}
write_nginx(){
  run install -d /etc/nginx/sites-available /etc/nginx/sites-enabled
  if ((DRY_RUN)); then log "would write /etc/nginx/sites-available/avidrive"; return; fi
  cat >/etc/nginx/sites-available/avidrive <<EOF
server {
  listen 80;
  server_name $DOMAIN;
  client_max_body_size 0;
  root $ROOT/frontend/dist;
  location /api/ { proxy_pass http://127.0.0.1:$BACKEND_PORT; proxy_set_header Host \$host; proxy_set_header X-Real-IP \$remote_addr; }
  location / { try_files \$uri \$uri/ /index.html; }
}
EOF
  run ln -sfn /etc/nginx/sites-available/avidrive /etc/nginx/sites-enabled/avidrive
  run rm -f /etc/nginx/sites-enabled/default
  run nginx -t
  run systemctl reload nginx || run systemctl restart nginx
}
write_service(){
  if ((DRY_RUN)); then log "would write avidrive-backend.service"; return; fi
  cat >/etc/systemd/system/avidrive-backend.service <<EOF
[Unit]
Description=AviDrive backend
After=network.target
[Service]
User=$APP_USER
WorkingDirectory=$ROOT
Environment=DB_PATH=$ROOT/data/filestorage.db
Environment=BACKEND_PORT=$BACKEND_PORT
ExecStart=/usr/bin/java -jar $ROOT/target/avidrive-0.1.0-SNAPSHOT.jar
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
  run systemctl daemon-reload; run systemctl enable --now avidrive-backend.service
}
ssl(){
  [[ "$DOMAIN" != "_" ]] || { log "SSL skipped: set AVIDRIVE_DOMAIN=example.com to enable certbot"; return; }
  read -r -p "Email for Let's Encrypt (empty skips SSL): " email
  [[ -n "$email" ]] && run certbot --nginx --non-interactive --agree-tos -m "$email" -d "$DOMAIN" || true
}
show_banner(){ cat <<EOF
AviDrive is installed.
Backend: http://127.0.0.1:$BACKEND_PORT
Frontend: http://$DOMAIN
Storage: $ROOT/storage
UFW was not enabled automatically. Review rules, then run: ufw enable
EOF
}
main(){
  need_root; check_os; check_port "$BACKEND_PORT"; check_port 80
  install_packages; prepare_user; build_app; write_nginx; write_service; ssl
  log "Installation is idempotent; run this script again to reconcile configuration."; show_banner
}
main "$@"
