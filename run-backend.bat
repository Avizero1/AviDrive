@echo off
setlocal EnableExtensions
chcp 65001 >nul
cd /d "%~dp0backend"
where java >nul 2>&1 || (echo [ERROR] Java не найден в PATH.& exit /b 1)
where mvn >nul 2>&1 || (echo [ERROR] Maven не найден в PATH.& exit /b 1)
echo [INFO] Сборка backend...
mvn -q -DskipTests package || (echo [ERROR] Сборка backend завершилась ошибкой.& exit /b 1)
echo [INFO] Запуск AviDrive backend на порту 8080...
mvn spring-boot:run
