#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="${DB_PATH:-$SCRIPT_DIR/data/filestorage.db}"
CONFIG_FILE="${CONFIG_FILE:-$SCRIPT_DIR/config.txt}"
PID_FILE="${PID_FILE:-$SCRIPT_DIR/mode_pids.txt}"
LOG_DIR="${LOG_DIR:-$SCRIPT_DIR/logs}"

RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'; BLUE='\033[34m'; RESET='\033[0m'

info() { printf '%b%s%b\n' "$BLUE" "$*" "$RESET"; }
ok() { printf '%b✅ %s%b\n' "$GREEN" "$*" "$RESET"; }
warn() { printf '%b⚠️  %s%b\n' "$YELLOW" "$*" "$RESET"; }
error() { printf '%b❌ %s%b\n' "$RED" "$*" "$RESET"; }
pause_menu() { printf '\nНажмите Enter для возврата в меню...'; IFS= read -r _; }

require_sqlite() {
  if ! command -v sqlite3 >/dev/null 2>&1; then error 'Требуется sqlite3. Установите его и повторите запуск.'; return 1; fi
}
sql_escape() { printf '%s' "$1" | sed "s/'/''/g"; }
validate_username() { [[ "$1" =~ ^[a-zA-Z0-9_]{3,20}$ ]]; }
validate_role() { [[ "$1" == ADMIN || "$1" == MODERATOR || "$1" == USER ]]; }
validate_quota() { [[ "$1" =~ ^[0-9]+$ ]]; }
validate_port() { [[ "$1" =~ ^[0-9]+$ && "$1" -ge 1 && "$1" -le 65535 ]]; }

config_value() { local key="$1"; [[ -f "$CONFIG_FILE" ]] || return 0; awk -F= -v key="$key" '$1 == key {sub(/^[^=]*=/, ""); print; exit}' "$CONFIG_FILE"; }
set_config_value() {
  local key="$1" value="$2" tmp; mkdir -p "$(dirname -- "$CONFIG_FILE")"; tmp="$(mktemp)" || return 1
  if [[ -f "$CONFIG_FILE" ]]; then awk -F= -v key="$key" -v value="$value" 'BEGIN{found=0}$1==key{print key "=" value;found=1;next}{print}END{if(!found)print key "=" value}' "$CONFIG_FILE" >"$tmp"; else printf '%s=%s\n' "$key" "$value" >"$tmp"; fi
  mv -- "$tmp" "$CONFIG_FILE"
}

bcrypt_hash() {
  local password="$1" hash=''
  if command -v htpasswd >/dev/null 2>&1; then hash="$(htpasswd -bnBC 12 '' "$password" 2>/dev/null | tr -d ':\r\n')"; fi
  if [[ ! "$hash" =~ ^\$2[aby]\$ ]] && command -v mkpasswd >/dev/null 2>&1; then hash="$(mkpasswd -m bcrypt "$password" 2>/dev/null || true)"; [[ "$hash" =~ ^\$2[aby]\$ ]] || hash="$(mkpasswd --method=bcrypt "$password" 2>/dev/null || true)"; fi
  if [[ ! "$hash" =~ ^\$2[aby]\$ ]] && command -v python3 >/dev/null 2>&1 && PASSWORD="$password" python3 -c 'import bcrypt' >/dev/null 2>&1; then hash="$(PASSWORD="$password" python3 -c 'import bcrypt,os;print(bcrypt.hashpw(os.environ["PASSWORD"].encode(),bcrypt.gensalt()).decode())')"; fi
  [[ "$hash" =~ ^\$2[aby]\$ ]] || { error 'Не найден рабочий BCrypt-инструмент.'; return 1; }; printf '%s' "$hash"
}

init_database() {
  local existed=0; [[ -f "$DB_PATH" ]] && existed=1; mkdir -p "$(dirname -- "$DB_PATH")"
  sqlite3 "$DB_PATH" <<'SQL'
PRAGMA foreign_keys=ON;
CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY AUTOINCREMENT,username VARCHAR(50) UNIQUE NOT NULL,password_hash VARCHAR(255) NOT NULL,role VARCHAR(50) NOT NULL,quota_mb BIGINT NOT NULL DEFAULT 0,used_space_mb BIGINT DEFAULT 0,is_blocked BOOLEAN DEFAULT 0,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS files(id INTEGER PRIMARY KEY AUTOINCREMENT,name VARCHAR(255) NOT NULL,path VARCHAR(1000) NOT NULL,is_directory BOOLEAN NOT NULL,size_bytes BIGINT DEFAULT 0,parent_id INTEGER,owner_id INTEGER NOT NULL,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,FOREIGN KEY(parent_id) REFERENCES files(id) ON DELETE CASCADE,FOREIGN KEY(owner_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE IF NOT EXISTS file_permissions(id INTEGER PRIMARY KEY AUTOINCREMENT,file_id INTEGER NOT NULL,user_id INTEGER NOT NULL,permissions TEXT NOT NULL,granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,FOREIGN KEY(file_id) REFERENCES files(id) ON DELETE CASCADE,FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,UNIQUE(file_id,user_id));
CREATE TABLE IF NOT EXISTS share_links(id INTEGER PRIMARY KEY AUTOINCREMENT,token VARCHAR(255) UNIQUE NOT NULL,file_id INTEGER NOT NULL,password_hash VARCHAR(255),permissions TEXT NOT NULL,expires_at TIMESTAMP,max_file_size_mb BIGINT DEFAULT 0,max_total_size_mb BIGINT DEFAULT 0,view_count BIGINT DEFAULT 0,download_count BIGINT DEFAULT 0,upload_count BIGINT DEFAULT 0,last_accessed_at TIMESTAMP,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,created_by INTEGER NOT NULL,FOREIGN KEY(file_id) REFERENCES files(id) ON DELETE CASCADE,FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE IF NOT EXISTS shared_folders(id INTEGER PRIMARY KEY AUTOINCREMENT,name VARCHAR(255) NOT NULL,owner_id INTEGER NOT NULL,quota_mb BIGINT NOT NULL DEFAULT 0,used_space_mb BIGINT DEFAULT 0,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,FOREIGN KEY(owner_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE IF NOT EXISTS shared_folder_members(id INTEGER PRIMARY KEY AUTOINCREMENT,folder_id INTEGER NOT NULL,user_id INTEGER NOT NULL,permissions TEXT NOT NULL,max_file_size_mb BIGINT DEFAULT 0,max_user_space_mb BIGINT DEFAULT 0,used_space_mb BIGINT DEFAULT 0,joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,FOREIGN KEY(folder_id) REFERENCES shared_folders(id) ON DELETE CASCADE,FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,UNIQUE(folder_id,user_id));
CREATE TABLE IF NOT EXISTS settings(id INTEGER PRIMARY KEY AUTOINCREMENT,key VARCHAR(100) UNIQUE NOT NULL,value TEXT NOT NULL);
INSERT OR IGNORE INTO settings(key,value) VALUES('global_quota_mb','0'),('backend_port','8080'),('frontend_port','3000'),('ssl_enabled','false'),('ssl_cert_path',''),('ssl_key_path','');
SQL
  [[ $? -eq 0 ]] || { error 'Ошибка инициализации базы данных.'; return 1; }; [[ "$existed" -eq 1 ]] && ok 'База данных найдена' || ok 'База данных создана'
}
get_user_id() { sqlite3 -noheader "$DB_PATH" "SELECT id FROM users WHERE username='$(sql_escape "$1")';"; }

create_user() {
  local username password password2 role quota confirm hash
  read -r -p 'Username: ' username; validate_username "$username" || { error 'Username: 3-20 символов: латиница, цифры и _.'; return; }; [[ -z "$(get_user_id "$username")" ]] || { error 'Такой username уже существует.'; return; }
  read -r -s -p 'Пароль (мин. 8 символов): ' password; printf '\n'; read -r -s -p 'Повторите пароль: ' password2; printf '\n'; [[ "$password" == "$password2" && ${#password} -ge 8 ]] || { error 'Пароли не совпадают или короче 8 символов.'; return; }
  read -r -p 'Роль (ADMIN/MODERATOR/USER): ' role; role="${role^^}"; validate_role "$role" || { error 'Недопустимая роль.'; return; }
  if [[ "$role" == ADMIN ]]; then read -r -p '⚠️  Вы создаёте ADMIN. Продолжить? (y/n): ' confirm; [[ "$confirm" =~ ^[YyДд]$ ]] || { warn 'Операция отменена.'; return; }; fi
  read -r -p 'Квота в МБ (0 = без лимита): ' quota; validate_quota "$quota" || { error 'Квота должна быть числом.'; return; }; hash="$(bcrypt_hash "$password")" || return
  sqlite3 "$DB_PATH" "INSERT INTO users(username,password_hash,role,quota_mb) VALUES('$(sql_escape "$username")','$(sql_escape "$hash")','$role',$quota);" && ok "Пользователь создан: $username" || error 'Ошибка SQL при создании пользователя.'
}
list_users() { printf '\n%-4s %-20s %-12s %-16s %-16s %-18s\n' ID Username Роль Квота Использовано Статус; printf '%s\n' '--------------------------------------------------------------------------------'; sqlite3 -separator '|' "$DB_PATH" 'SELECT id,username,role,quota_mb,used_space_mb,is_blocked FROM users ORDER BY id;' | while IFS='|' read -r id username role quota used blocked; do local q u s; [[ "$quota" == 0 ]]&&q='0 (∞)'||q="$quota MB"; ((used<1024))&&u="$used MB"||u="$(awk -v n="$used" 'BEGIN{printf "%.2f GB",n/1024}')"; [[ "$blocked" == 1 ]]&&s='🚫 Заблокирован'||s='✅ Активен'; printf '%-4s %-20s %-12s %-16s %-16s %-18s\n' "$id" "$username" "$role" "$q" "$u" "$s"; done; printf '\nВсего пользователей: %s\n' "$(sqlite3 -noheader "$DB_PATH" 'SELECT COUNT(*) FROM users;')"; }
remove_user() { local username confirm id storage; read -r -p 'Username: ' username; validate_username "$username" || { error 'Недопустимый username.';return; }; id="$(get_user_id "$username")"; [[ -n "$id" ]] || { error 'Пользователь не найден.';return; }; read -r -p 'Подтверждение удаления (y/n): ' confirm; [[ "$confirm" =~ ^[YyДд]$ ]] || { warn 'Операция отменена.';return; }; storage="$(config_value storage_path)"; storage="${storage:-$SCRIPT_DIR/storage}"; sqlite3 "$DB_PATH" "PRAGMA foreign_keys=ON;DELETE FROM users WHERE id=$id;"&&rm -rf -- "$storage/user_$id"&&ok 'Пользователь и его файлы удалены.'||error 'Ошибка удаления.'; }
change_role() { local username role confirm; read -r -p 'Username: ' username; validate_username "$username" || { error 'Недопустимый username.';return; }; read -r -p 'Новая роль (ADMIN/MODERATOR/USER): ' role; role="${role^^}"; validate_role "$role" || { error 'Недопустимая роль.';return; }; if [[ "$role" == ADMIN ]];then read -r -p '⚠️  Назначить ADMIN? (y/n): ' confirm;[[ "$confirm" =~ ^[YyДд]$ ]] || { warn 'Операция отменена.';return; };fi; sqlite3 "$DB_PATH" "UPDATE users SET role='$role' WHERE username='$(sql_escape "$username")';"&&ok 'Роль изменена.'||error 'Ошибка SQL.'; }
reset_password() { local username password password2 hash; read -r -p 'Username: ' username; validate_username "$username" || { error 'Недопустимый username.';return; }; [[ -n "$(get_user_id "$username")" ]] || { error 'Пользователь не найден.';return; }; read -r -s -p 'Новый пароль: ' password;printf '\n';read -r -s -p 'Повторите пароль: ' password2;printf '\n';[[ "$password" == "$password2" && ${#password} -ge 8 ]] || { error 'Неверный пароль.';return; };hash="$(bcrypt_hash "$password")"||return;sqlite3 "$DB_PATH" "UPDATE users SET password_hash='$(sql_escape "$hash")' WHERE username='$(sql_escape "$username")';"&&ok 'Пароль сброшен.'||error 'Ошибка SQL.'; }
change_quota() { local username quota; read -r -p 'Username: ' username;validate_username "$username" || { error 'Недопустимый username.'; return; };read -r -p 'Новая квота в МБ (0 = без лимита): ' quota;validate_quota "$quota" || { error 'Квота должна быть числом.'; return; };sqlite3 "$DB_PATH" "UPDATE users SET quota_mb=$quota WHERE username='$(sql_escape "$username")';"&&ok 'Квота изменена.'||error 'Ошибка SQL.'; }
toggle_block() { local username current action value; read -r -p 'Username: ' username;validate_username "$username" || { error 'Недопустимый username.'; return; };current="$(sqlite3 -noheader "$DB_PATH" "SELECT is_blocked FROM users WHERE username='$(sql_escape "$username")';")";[[ -n "$current" ]] || { error 'Пользователь не найден.';return;};read -r -p 'Действие (block/unblock): ' action;case "${action,,}" in block)value=1;;unblock)value=0;;*)error 'Введите block или unblock.';return;;esac;sqlite3 "$DB_PATH" "UPDATE users SET is_blocked=$value WHERE username='$(sql_escape "$username")';"&&ok 'Статус изменён.'||error 'Ошибка SQL.'; }
set_setting_and_config() { local key="$1" value="$2";set_config_value "$key" "$value"||return 1;sqlite3 "$DB_PATH" "INSERT INTO settings(key,value) VALUES('$(sql_escape "$key")','$(sql_escape "$value")') ON CONFLICT(key) DO UPDATE SET value=excluded.value;"; }
configure_ports() { local b f cb cf;cb="$(config_value backend_port)";cb="${cb:-8080}";cf="$(config_value frontend_port)";cf="${cf:-3000}";read -r -p "Порт backend (текущий: $cb): " b;b="${b:-$cb}";read -r -p "Порт frontend (текущий: $cf): " f;f="${f:-$cf}";validate_port "$b"&&validate_port "$f" || { error 'Порты 1-65535.';return;};set_setting_and_config backend_port "$b"&&set_setting_and_config frontend_port "$f"&&ok 'Порты сохранены.'||error 'Не удалось сохранить порты.'; }
configure_ssl() { local enabled cert key;read -r -p 'Включить SSL? (y/n): ' enabled;if [[ "$enabled" =~ ^[YyДд]$ ]];then read -r -p 'Путь к сертификату: ' cert;read -r -p 'Путь к ключу: ' key;[[ -f "$cert"&&-f "$key" ]] || { error 'Файлы сертификата или ключа не найдены.';return;};set_setting_and_config ssl_enabled true;set_setting_and_config ssl_cert_path "$cert";set_setting_and_config ssl_key_path "$key";ok 'SSL включён.';else set_setting_and_config ssl_enabled false&&ok 'SSL выключен.';fi; }
start_services() { mkdir -p "$LOG_DIR";[[ ! -f "$PID_FILE" ]] || { warn 'Сначала остановите сервисы.';return;};local b f bp fp;b="$(config_value backend_port)";b="${b:-8080}";f="$(config_value frontend_port)";f="${f:-3000}";(cd "$SCRIPT_DIR/backend"&&nohup mvn spring-boot:run -Dspring-boot.run.arguments="--server.port=$b" >"$LOG_DIR/backend.log" 2>&1 & echo $! >"$SCRIPT_DIR/.bp");bp="$(cat "$SCRIPT_DIR/.bp")";rm -f "$SCRIPT_DIR/.bp";(cd "$SCRIPT_DIR/frontend"&&nohup npm run dev -- --host 0.0.0.0 --port "$f" >"$LOG_DIR/frontend.log" 2>&1 & echo $! >"$SCRIPT_DIR/.fp");fp="$(cat "$SCRIPT_DIR/.fp")";rm -f "$SCRIPT_DIR/.fp";printf 'backend=%s\nfrontend=%s\n' "$bp" "$fp">"$PID_FILE";ok "Backend PID $bp, frontend PID $fp."; }
stop_services() { local pid;if [[ ! -f "$PID_FILE" ]];then warn 'PID-файл не найден.';return;fi;while IFS='=' read -r _ pid;do [[ "$pid" =~ ^[0-9]+$ ]]&&kill "$pid" 2>/dev/null||true;done<"$PID_FILE";rm -f "$PID_FILE";ok 'Сервисы остановлены.'; }
restart_services() { stop_services;start_services; }
statistics() { local storage total;printf '\nПользователи по ролям:\n';sqlite3 -header -column "$DB_PATH" 'SELECT role,COUNT(*) AS count FROM users GROUP BY role ORDER BY role;';storage="$(config_value storage_path)";storage="${storage:-$SCRIPT_DIR/storage}";total="$(du -sm -- "$storage" 2>/dev/null|awk '{print $1}')";total="${total:-0}";printf '\nОбщий размер хранилища: %s MB\n\nТоп-5 пользователей:\n' "$total";sqlite3 -header -column "$DB_PATH" 'SELECT username,used_space_mb AS used_mb FROM users ORDER BY used_space_mb DESC LIMIT 5;'; }
reset_database() { local confirm token;warn 'БД будет удалена, storage не затрагивается.';read -r -p 'Вы уверены? (y/n): ' confirm;[[ "$confirm" =~ ^[YyДд]$ ]] || { warn 'Отменено.';return;};read -r -p 'Повторите RESET: ' token;[[ "$token" == RESET ]] || { error 'Неверное подтверждение.';return;};rm -f -- "$DB_PATH";init_database&&ok 'База сброшена.'; }

show_menu() { printf '\n%bAviDrive - Панель управления%b\n' "$BLUE" "$RESET"; printf '%s\n' '[1] Создать пользователя' '[2] Список пользователей' '[3] Удалить пользователя' '[4] Изменить роль' '[5] Сбросить пароль' '[6] Изменить квоту' '[7] Заблокировать / Разблокировать' '[8] Настроить порты' '[9] Настроить SSL' '[10] Запустить сервисы' '[11] Остановить сервисы' '[12] Перезапустить сервисы' '[13] Статистика' '[14] Сбросить базу данных' '[0] Выход'; }
main() { require_sqlite||exit 1;init_database||exit 1;while true;do show_menu;local choice;read -r -p 'Выберите действие: ' choice||break;case "$choice" in 1)create_user;pause_menu;;2)list_users;pause_menu;;3)remove_user;pause_menu;;4)change_role;pause_menu;;5)reset_password;pause_menu;;6)change_quota;pause_menu;;7)toggle_block;pause_menu;;8)configure_ports;pause_menu;;9)configure_ssl;pause_menu;;10)start_services;pause_menu;;11)stop_services;pause_menu;;12)restart_services;pause_menu;;13)statistics;pause_menu;;14)reset_database;pause_menu;;0)ok 'Выход.';return 0;;*)error 'Неверный пункт.';pause_menu;;esac;done; }
main "$@"
