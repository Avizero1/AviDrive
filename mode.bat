@echo off
chcp 65001 >nul
setlocal
set ROOT=%~dp0
if "%DB_PATH%"=="" set DB_PATH=%ROOT%data\filestorage.db
:menu
echo 1 Start 2 Stop 3 Frontend 4 Stop frontend 5 Status 6 Reset 7 Quota 8 Backup 9 Backups 10 Restore 11 Hash 12 Verify 13 SQL 14 Init 15 Exit
set /p N=^> 
if "%N%"=="1" start "AviDrive Backend" cmd /k "cd /d %ROOT% ^&^& mvn spring-boot:run"
if "%N%"=="3" start "AviDrive Frontend" cmd /k "cd /d %ROOT%frontend ^&^& npm run dev"
if "%N%"=="6" call :reset
if "%N%"=="8" if not exist "%ROOT%backups" mkdir "%ROOT%backups" & copy /y "%DB_PATH%" "%ROOT%backups\filestorage-backup.db"
if "%N%"=="9" dir /b "%ROOT%backups"
if "%N%"=="15" exit /b 0
goto menu
:reset
set /p C=Type RESET to confirm: 
if not "%C%"=="RESET" exit /b
set /p C=Type RESET DATABASE to confirm: 
if not "%C%"=="RESET DATABASE" exit /b
del /q "%DB_PATH%" 2>nul
if exist "%ROOT%storage" rmdir /s /q "%ROOT%storage"
exit /b
