@echo off
setlocal EnableExtensions
chcp 65001 >nul
cd /d "%~dp0frontend"
where node >nul 2>&1 || (echo [ERROR] Node.js не найден в PATH.& exit /b 1)
where npm >nul 2>&1 || (echo [ERROR] npm не найден в PATH.& exit /b 1)
if not exist node_modules (
  echo [INFO] Установка frontend-зависимостей...
  npm install --no-audit --no-fund || (echo [ERROR] npm install завершился ошибкой.& exit /b 1)
)
echo [INFO] Запуск AviDrive frontend на порту 3000...
npm run dev -- --host 0.0.0.0
