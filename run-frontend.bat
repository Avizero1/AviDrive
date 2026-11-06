@echo off
setlocal EnableExtensions

if not exist "%~dp0frontend\package.json" goto missing_frontend
where node.exe >nul 2>&1
if errorlevel 1 goto missing_node
where npm.cmd >nul 2>&1
if errorlevel 1 goto missing_npm

pushd "%~dp0frontend"
if not exist node_modules (
  echo [INFO] Installing frontend dependencies...
  call npm.cmd install --no-audit --no-fund
  if errorlevel 1 goto install_failed
)

if not defined FRONTEND_PORT set "FRONTEND_PORT=3000"
echo [INFO] Starting AviDrive frontend on port %FRONTEND_PORT%...
call npm.cmd run dev -- --host 0.0.0.0 --port %FRONTEND_PORT%
set "EXIT_CODE=%ERRORLEVEL%"
popd
exit /b %EXIT_CODE%

:missing_frontend
echo [ERROR] frontend or package.json was not found.
exit /b 1

:missing_node
echo [ERROR] Node.js was not found in PATH.
exit /b 1

:missing_npm
echo [ERROR] npm was not found in PATH.
exit /b 1

:install_failed
echo [ERROR] npm install failed.
popd
exit /b 1