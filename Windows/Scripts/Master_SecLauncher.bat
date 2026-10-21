@echo off
setlocal EnableExtensions EnableDelayedExpansion
title CyberPatriot Windows Security Orchestrator

:: ============================================================================
:: Check Administrator Privileges
:: ============================================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] ERROR: This script must be run as Administrator!
    echo [!] Right-click Master_SecLauncher.bat and select "Run as administrator".
    pause
    exit /b 1
)

:: Ensure current working directory is the script folder
cd /d "%~dp0"

:: Ensure PowerShell execution policy allows running scripts in this session
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Engine.ps1"

exit /b %errorlevel%
