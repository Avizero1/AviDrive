@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

set "DB_PATH=%~dp0data\filestorage.db"
if defined DB_PATH_ARG set "DB_PATH=%DB_PATH_ARG%"
where sqlite3.exe >nul 2>&1 || (echo Error: sqlite3.exe is required in PATH.& exit /b 1)

if /I "%~1"=="init-schema" goto init_schema
if /I "%~1"=="list-users" goto list_users
if /I "%~1"=="set-password" goto set_password
if /I "%~1"=="block" goto block_user
if /I "%~1"=="unblock" goto unblock_user
if /I "%~1"=="delete-user" goto delete_user
goto usage

:validate_username
set "CHECK_USERNAME=%~1"
set "USERNAME_TO_VALIDATE=!CHECK_USERNAME!"
for /f "delims=" %%A in ('powershell -NoProfile -Command "if ($env:USERNAME_TO_VALIDATE -cmatch '^[a-zA-Z_][a-zA-Z0-9_]{2,19}$') { 'OK' } else { 'INVALID' }"') do set "VALID=%%A"
if /I not "!VALID!"=="OK" (echo Error: username must be 3-20 Latin letters, digits or underscore, and not start with a digit.& exit /b 1)
exit /b 0

:init_schema
if not exist "%~dp0data" mkdir "%~dp0data"
sqlite3 "%DB_PATH%" "PRAGMA foreign_keys=ON; CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, username VARCHAR(50) UNIQUE NOT NULL, password_hash VARCHAR(255) NOT NULL, role VARCHAR(50) NOT NULL, quota_mb BIGINT NOT NULL DEFAULT 0, used_space_mb BIGINT NOT NULL DEFAULT 0, is_blocked BOOLEAN NOT NULL DEFAULT 0, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP); CREATE TABLE IF NOT EXISTS settings (id INTEGER PRIMARY KEY AUTOINCREMENT, key VARCHAR(100) UNIQUE NOT NULL, value TEXT NOT NULL);"
exit /b %errorlevel%

:list_users
sqlite3 -header -column "%DB_PATH%" "SELECT id, username, role, quota_mb, used_space_mb, is_blocked, created_at FROM users ORDER BY username;"
exit /b %errorlevel%

:set_password
call :validate_username "%~2"
if errorlevel 1 exit /b 1
if "%~3"=="" (echo Error: BCrypt hash is required.& exit /b 1)
set "HASH=%~3"
set "HASH=!HASH:'=''!"
set "USER_SQL=%~2"
set "USER_SQL=!USER_SQL:'=''!"
sqlite3 "%DB_PATH%" "UPDATE users SET password_hash='!HASH!' WHERE username='!USER_SQL!'; SELECT changes();"
exit /b %errorlevel%

:block_user
call :validate_username "%~2"
if errorlevel 1 exit /b 1
set "USER_SQL=%~2"
set "USER_SQL=!USER_SQL:'=''!"
sqlite3 "%DB_PATH%" "UPDATE users SET is_blocked=1 WHERE username='!USER_SQL!'; SELECT changes();"
exit /b %errorlevel%

:unblock_user
call :validate_username "%~2"
if errorlevel 1 exit /b 1
set "USER_SQL=%~2"
set "USER_SQL=!USER_SQL:'=''!"
sqlite3 "%DB_PATH%" "UPDATE users SET is_blocked=0 WHERE username='!USER_SQL!'; SELECT changes();"
exit /b %errorlevel%

:delete_user
call :validate_username "%~2"
if errorlevel 1 exit /b 1
set "USER_SQL=%~2"
set "USER_SQL=!USER_SQL:'=''!"
sqlite3 "%DB_PATH%" "PRAGMA foreign_keys=ON; DELETE FROM users WHERE username='!USER_SQL!'; SELECT changes();"
exit /b %errorlevel%

:usage
echo Usage: mode.bat ^<command^> [arguments]
echo Commands: init-schema, list-users, set-password ^<username^> ^<bcrypt-hash^>, block ^<username^>, unblock ^<username^>, delete-user ^<username^>
exit /b 2
