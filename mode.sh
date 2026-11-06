#!/usr/bin/env bash
set -euo pipefail

DB_PATH="${DB_PATH:-./data/filestorage.db}"

usage() {
  cat <<'EOF'
Использование: ./mode.sh <команда> [аргументы]
Команды: init-schema, list-users, set-password <username> <bcrypt-hash>, block <username>, unblock <username>, delete-user <username>
EOF
}

require_sqlite() {
  command -v sqlite3 >/dev/null 2>&1 || { echo "Ошибка: требуется sqlite3" >&2; exit 1; }
}

validate_username() {
  [[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]{2,19}$ ]] || { echo "Ошибка: username: латиница/цифры/_, 3-20 символов, не начинается с цифры" >&2; exit 1; }
}

sql_escape() { printf "%s" "$1" | sed "s/'/''/g"; }

require_sqlite
mkdir -p "$(dirname "$DB_PATH")"
command="${1:-}"

case "$command" in
  init-schema)
    sqlite3 "$DB_PATH" <<'SQL'
PRAGMA foreign_keys = ON;
CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, username VARCHAR(50) UNIQUE NOT NULL, password_hash VARCHAR(255) NOT NULL, role VARCHAR(50) NOT NULL, quota_mb BIGINT NOT NULL DEFAULT 0, used_space_mb BIGINT NOT NULL DEFAULT 0, is_blocked BOOLEAN NOT NULL DEFAULT 0, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS files (id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(255) NOT NULL, path VARCHAR(1000) NOT NULL, is_directory BOOLEAN NOT NULL DEFAULT 0, size_bytes BIGINT NOT NULL DEFAULT 0, parent_id BIGINT, owner_id BIGINT NOT NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY(parent_id) REFERENCES files(id) ON DELETE CASCADE, FOREIGN KEY(owner_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE IF NOT EXISTS file_permissions (id INTEGER PRIMARY KEY AUTOINCREMENT, file_id BIGINT NOT NULL, user_id BIGINT NOT NULL, permissions TEXT NOT NULL, granted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, UNIQUE(file_id,user_id), FOREIGN KEY(file_id) REFERENCES files(id) ON DELETE CASCADE, FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE IF NOT EXISTS share_links (id INTEGER PRIMARY KEY AUTOINCREMENT, token VARCHAR(255) UNIQUE NOT NULL, file_id BIGINT NOT NULL, password_hash VARCHAR(255), permissions TEXT NOT NULL, expires_at TIMESTAMP, max_file_size_mb BIGINT NOT NULL DEFAULT 0, max_total_size_mb BIGINT NOT NULL DEFAULT 0, view_count BIGINT NOT NULL DEFAULT 0, download_count BIGINT NOT NULL DEFAULT 0, upload_count BIGINT NOT NULL DEFAULT 0, last_accessed_at TIMESTAMP, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, created_by BIGINT NOT NULL, FOREIGN KEY(file_id) REFERENCES files(id) ON DELETE CASCADE, FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE IF NOT EXISTS shared_folders (id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(255) NOT NULL, owner_id BIGINT NOT NULL, quota_mb BIGINT NOT NULL DEFAULT 0, used_space_mb BIGINT NOT NULL DEFAULT 0, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY(owner_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE IF NOT EXISTS shared_folder_members (id INTEGER PRIMARY KEY AUTOINCREMENT, folder_id BIGINT NOT NULL, user_id BIGINT NOT NULL, permissions TEXT NOT NULL, max_file_size_mb BIGINT NOT NULL DEFAULT 0, max_user_space_mb BIGINT NOT NULL DEFAULT 0, used_space_mb BIGINT NOT NULL DEFAULT 0, joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, UNIQUE(folder_id,user_id), FOREIGN KEY(folder_id) REFERENCES shared_folders(id) ON DELETE CASCADE, FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE IF NOT EXISTS settings (id INTEGER PRIMARY KEY AUTOINCREMENT, key VARCHAR(100) UNIQUE NOT NULL, value TEXT NOT NULL);
SQL
    ;;
  list-users)
    sqlite3 -header -column "$DB_PATH" "SELECT id, username, role, quota_mb, used_space_mb, is_blocked, created_at FROM users ORDER BY username;"
    ;;
  set-password|block|unblock|delete-user)
    username="${2:-}"; validate_username "$username"
    escaped_username=$(sql_escape "$username")
    case "$command" in
      set-password)
        hash="${3:-}"; [[ -n "$hash" ]] || { echo "Ошибка: передайте BCrypt-хеш пароля" >&2; exit 1; }
        escaped_hash=$(sql_escape "$hash")
        sqlite3 "$DB_PATH" "UPDATE users SET password_hash='$escaped_hash' WHERE username='$escaped_username'; SELECT changes();"
        ;;
      block) sqlite3 "$DB_PATH" "UPDATE users SET is_blocked=1 WHERE username='$escaped_username'; SELECT changes();" ;;
      unblock) sqlite3 "$DB_PATH" "UPDATE users SET is_blocked=0 WHERE username='$escaped_username'; SELECT changes();" ;;
      delete-user) sqlite3 "$DB_PATH" "PRAGMA foreign_keys=ON; DELETE FROM users WHERE username='$escaped_username'; SELECT changes();" ;;
    esac
    ;;
  *) usage; exit 2 ;;
esac
