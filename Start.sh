#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'; BLUE='\033[34m'; RESET='\033[0m'
ok(){ printf '%b✅ %s%b\n' "$GREEN" "$*" "$RESET"; }
warn(){ printf '%b⚠️  %s%b\n' "$YELLOW" "$*" "$RESET"; }
error(){ printf '%b❌ %s%b\n' "$RED" "$*" "$RESET"; }

[[ "$(id -u)" -eq 0 ]] || { error 'Start.sh должен запускаться от root.'; exit 1; }
[[ -r /etc/os-release ]] || { error 'Не удалось определить ОС.'; exit 1; }
# shellcheck disable=SC1091
source /etc/os-release
case "${ID:-}" in ubuntu|debian) ;; *) error 'Поддерживаются только Ubuntu и Debian.'; exit 1;; esac

BACKEND_PORT=8080
FRONTEND_PORT=3000
DOMAIN=''
SSL_ENABLED=false
STORAGE_PATH='/var/lib/avidrive/storage'
DB_PATH='/var/lib/avidrive/data/filestorage.db'
ADMIN_USERNAME=''
ADMIN_PASSWORD=''
ADMIN_QUOTA=0
PACKAGES=(openjdk-17-jdk maven nodejs npm sqlite3 curl git nginx certbot python3-certbot-nginx ufw unzip)

ask(){ local prompt="$1" default="$2" value; read -r -p "$prompt [$default]: " value; printf '%s' "${value:-$default}"; }
valid_port(){ [[ "$1" =~ ^[0-9]+$ && "$1" -ge 1 && "$1" -le 65535 ]]; }
valid_user(){ [[ "$1" =~ ^[a-zA-Z0-9_]{3,20}$ ]]; }
valid_quota(){ [[ "$1" =~ ^[0-9]+$ ]]; }
port_free(){ ! ss -H -ltn "sport = :$1" 2>/dev/null | grep -q .; }

step1(){ printf '\n[1/9] Определяю систему...\n'; ok "Обнаружена: ${PRETTY_NAME:-$ID} ($(uname -m))"; }
step2(){
  printf '\n[2/9] Проверяю зависимости...\n'; local missing=() p
  for p in "${PACKAGES[@]}"; do if command -v "$p" >/dev/null 2>&1 || { [[ "$p" == openjdk-17-jdk ]] && command -v java >/dev/null 2>&1; } || { [[ "$p" == python3-certbot-nginx ]] && command -v certbot >/dev/null 2>&1; }; then ok "$p установлен"; else warn "$p не найден"; missing+=("$p"); fi; done
  if ((${#missing[@]})); then local answer; answer="$(ask 'Установить недостающие пакеты? (Y/n)' Y)"; [[ "$answer" =~ ^[YyДд]$ ]] || { error 'Без зависимостей установка невозможна.'; exit 1; }; apt-get update; apt-get install -y "${missing[@]}"; ok 'Установка завершена'; fi
}
step3(){
  printf '\n[3/9] Настройка портов...\n'
  while true; do BACKEND_PORT="$(ask 'Порт для backend' "$BACKEND_PORT")"; valid_port "$BACKEND_PORT" && port_free "$BACKEND_PORT" && break; warn "Порт $BACKEND_PORT занят или некорректен."; done
  while true; do FRONTEND_PORT="$(ask 'Порт для frontend' "$FRONTEND_PORT")"; valid_port "$FRONTEND_PORT" && [[ "$FRONTEND_PORT" != "$BACKEND_PORT" ]] && port_free "$FRONTEND_PORT" && break; warn "Порт $FRONTEND_PORT занят, совпадает или некорректен."; done
  ok "Backend: $BACKEND_PORT; frontend: $FRONTEND_PORT"
}
step4(){
  printf '\n[4/9] Настройка домена и SSL...\n'; local answer ip resolved
  answer="$(ask 'У вас есть домен для AviDrive? (y/n)' n)"
  if [[ "$answer" =~ ^[YyДд]$ ]]; then
    DOMAIN="$(ask 'Введите домен' '')"; [[ "$DOMAIN" =~ ^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]] || { error 'Некорректный домен.'; exit 1; }
    resolved="$(getent ahostsv4 "$DOMAIN" | awk 'NR==1{print $1}')"; ip="$(hostname -I | awk '{print $1}')"; [[ -n "$resolved" ]] || { error 'DNS домена не разрешается.'; exit 1; }
    [[ "$resolved" == "$ip" ]] || warn "DNS: $resolved; IP сервера: $ip. Продолжаю после подтверждения."
    SSL_ENABLED=true
  else warn 'Работаем по HTTP (небезопасно для продакшена).'; SSL_ENABLED=false; fi
}
step5(){
  printf '\n[5/9] Настройка firewall (UFW)...\n'; local answer; answer="$(ask 'Продолжить настройку правил? (Y/n)' Y)"; [[ "$answer" =~ ^[YyДд]$ ]] || { warn 'UFW пропущен.'; return; }
  ufw allow ssh; ufw allow 80/tcp; ufw allow 443/tcp; ufw allow "$BACKEND_PORT/tcp"; ufw allow "$FRONTEND_PORT/tcp"; ok 'Правила UFW добавлены; UFW НЕ включён автоматически.'
}
step6(){ printf '\n[6/9] Расположение хранилища...\n'; STORAGE_PATH="$(ask 'Где хранить файлы' "$STORAGE_PATH")"; install -d -m 0750 "$STORAGE_PATH" "$(dirname "$DB_PATH")"; ok "Хранилище готово: $STORAGE_PATH"; }

initialize_database(){
  install -d -m 0750 "$(dirname "$DB_PATH")"
  sqlite3 "$DB_PATH" <<'SQL'
PRAGMA foreign_keys=ON;
CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY AUTOINCREMENT,username VARCHAR(50) UNIQUE NOT NULL,password_hash VARCHAR(255) NOT NULL,role VARCHAR(50) NOT NULL,quota_mb BIGINT NOT NULL DEFAULT 0,used_space_mb BIGINT DEFAULT 0,is_blocked BOOLEAN DEFAULT 0,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS files(id INTEGER PRIMARY KEY AUTOINCREMENT,name VARCHAR(255) NOT NULL,path VARCHAR(1000) NOT NULL,is_directory BOOLEAN NOT NULL,size_bytes BIGINT DEFAULT 0,parent_id INTEGER,owner_id INTEGER NOT NULL,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,FOREIGN KEY(parent_id) REFERENCES files(id) ON DELETE CASCADE,FOREIGN KEY(owner_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE IF NOT EXISTS settings(id INTEGER PRIMARY KEY AUTOINCREMENT,key VARCHAR(100) UNIQUE NOT NULL,value TEXT NOT NULL);
INSERT OR IGNORE INTO settings(key,value) VALUES('global_quota_mb','0'),('backend_port','8080'),('frontend_port','3000'),('ssl_enabled','false');
SQL
}
password_hash(){ if command -v htpasswd >/dev/null 2>&1; then htpasswd -bnBC 12 '' "$1" 2>/dev/null | tr -d ':\r\n'; elif command -v python3 >/dev/null 2>&1 && PASSWORD="$1" python3 -c 'import bcrypt' >/dev/null 2>&1; then PASSWORD="$1" python3 -c 'import bcrypt,os;print(bcrypt.hashpw(os.environ["PASSWORD"].encode(),bcrypt.gensalt()).decode())'; else error 'Нужен htpasswd с поддержкой BCrypt или Python bcrypt.'; return 1; fi; }
step7(){
  printf '\n[7/9] Создание администратора...\n'; initialize_database
  ADMIN_USERNAME="$(ask 'Username (латиница, 3-20 символов)' '')"; valid_user "$ADMIN_USERNAME" || { error 'Некорректный username.'; exit 1; }
  read -r -s -p 'Пароль (мин. 8 символов): ' ADMIN_PASSWORD; printf '\n'; [[ ${#ADMIN_PASSWORD} -ge 8 ]] || { error 'Пароль короче 8 символов.'; exit 1; }
  ADMIN_QUOTA="$(ask 'Квота в МБ (0 = без лимита)' 0)"; valid_quota "$ADMIN_QUOTA" || { error 'Некорректная квота.'; exit 1; }
  local hash; hash="$(password_hash "$ADMIN_PASSWORD")"; sqlite3 "$DB_PATH" "INSERT INTO users(username,password_hash,role,quota_mb) VALUES('$ADMIN_USERNAME','$hash','ADMIN',$ADMIN_QUOTA) ON CONFLICT(username) DO UPDATE SET password_hash=excluded.password_hash,role='ADMIN',quota_mb=excluded.quota_mb;"; ok "Администратор создан: $ADMIN_USERNAME"
}
step8(){ printf '\n[8/9] Сборка проекта...\n'; (cd "$SCRIPT_DIR/backend" && mvn clean package -DskipTests); ok 'Backend собран'; (cd "$SCRIPT_DIR/frontend" && npm install --no-audit --no-fund && npm run build); ok 'Frontend собран'; }
write_nginx(){ local scheme='http'; [[ "$SSL_ENABLED" == true ]] && scheme='https'; cat > /etc/nginx/sites-available/avidrive <<EOF
server {
    listen 80;
    server_name ${DOMAIN:-_};
    location / { proxy_pass http://127.0.0.1:$FRONTEND_PORT; proxy_set_header Host \$host; proxy_set_header X-Real-IP \$remote_addr; }
    location /api/ { proxy_pass http://127.0.0.1:$BACKEND_PORT/api/; proxy_set_header Host \$host; proxy_set_header X-Real-IP \$remote_addr; }
}
EOF
  ln -sfn /etc/nginx/sites-available/avidrive /etc/nginx/sites-enabled/avidrive; rm -f /etc/nginx/sites-enabled/default; nginx -t; systemctl reload nginx || systemctl restart nginx; if [[ "$SSL_ENABLED" == true ]]; then certbot --nginx --non-interactive --agree-tos --register-unsafely-without-email -d "$DOMAIN"; (crontab -l 2>/dev/null | grep -v 'certbot renew'; echo '17 3 * * * certbot renew --quiet') | crontab -; fi; }
step9(){
  printf '\n[9/9] Создание systemd сервисов...\n'; local jar; jar="$(find "$SCRIPT_DIR/backend/target" -maxdepth 1 -name '*.jar' ! -name '*original*' | head -n 1)"; [[ -n "$jar" ]] || { error 'JAR backend не найден.'; exit 1; }
  cat > /etc/systemd/system/avidrive-backend.service <<EOF
[Unit]
Description=AviDrive Backend
After=network.target
[Service]
Type=simple
User=root
WorkingDirectory=$SCRIPT_DIR/backend
ExecStart=/usr/bin/java -jar $jar --server.port=$BACKEND_PORT
Restart=on-failure
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF
  cat > /etc/systemd/system/avidrive-frontend.service <<EOF
[Unit]
Description=AviDrive Frontend
After=network.target
[Service]
Type=simple
User=root
WorkingDirectory=$SCRIPT_DIR/frontend
ExecStart=/usr/bin/npm run dev -- --host 0.0.0.0 --port $FRONTEND_PORT
Restart=on-failure
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF
  write_nginx; systemctl daemon-reload; systemctl enable --now avidrive-backend.service avidrive-frontend.service; ok 'Сервисы запущены и добавлены в автозагрузку'; }

step1; step2; step3; step4; step5; step6; step7; step8; step9
printf '\n========================================\n'; ok 'Установка завершена!'; printf 'Backend:  %s://%s:%s\nFrontend: %s://%s:%s\nAdmin:    %s / %s\nХранилище: %s\nЛоги:     journalctl -u avidrive-backend -f\nУправление: ./mode.sh\n========================================\n' "$([[ "$SSL_ENABLED" == true ]] && echo https || echo http)" "${DOMAIN:-$(hostname -I | awk '{print $1}')}" "$BACKEND_PORT" "$([[ "$SSL_ENABLED" == true ]] && echo https || echo http)" "${DOMAIN:-$(hostname -I | awk '{print $1}')}" "$FRONTEND_PORT" "$ADMIN_USERNAME" "$ADMIN_PASSWORD" "$STORAGE_PATH"
warn 'НЕ ЗАБУДЬТЕ включить UFW вручную: ufw enable'
