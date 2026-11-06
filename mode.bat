@echo off
setlocal EnableExtensions
chcp 65001 >nul
color 0B
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0mode.ps1"
exit /b %errorlevel%
