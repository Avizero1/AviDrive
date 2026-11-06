@echo off
setlocal EnableExtensions

if not exist "%~dp0backend\pom.xml" goto missing_backend
where java.exe >nul 2>&1
if errorlevel 1 goto missing_java
where mvn.cmd >nul 2>&1
if errorlevel 1 goto missing_maven

if not exist "%~dp0backend\data" mkdir "%~dp0backend\data"

pushd "%~dp0backend"
echo [INFO] Building backend...
call mvn.cmd -q -DskipTests package
if errorlevel 1 goto build_failed

if not defined BACKEND_PORT set "BACKEND_PORT=8080"
echo [INFO] Starting AviDrive backend on port %BACKEND_PORT%...
call mvn.cmd spring-boot:run "-Dspring-boot.run.arguments=--server.port=%BACKEND_PORT%"
set "EXIT_CODE=%ERRORLEVEL%"
popd
exit /b %EXIT_CODE%

:missing_backend
echo [ERROR] backend or pom.xml was not found.
exit /b 1

:missing_java
echo [ERROR] Java was not found in PATH.
exit /b 1

:missing_maven
echo [ERROR] Maven was not found in PATH.
exit /b 1

:build_failed
echo [ERROR] Backend build failed.
popd
exit /b 1
