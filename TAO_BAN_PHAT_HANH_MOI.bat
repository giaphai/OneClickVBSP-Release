@echo off
setlocal EnableExtensions
title OneClickVBSP - TAO BAN PHAT HANH GITHUB TU DONG

cd /d "%~dp0"
set "ROOT_DIR=%~dp0"
if "%ROOT_DIR:~-1%"=="\" set "ROOT_DIR=%ROOT_DIR:~0,-1%"
set "DEV_DIR=%ROOT_DIR%\dev"

echo ============================================================
echo  ONECLICK VBSP 2026 - PHAT HANH GITHUB RELEASES TU DONG
echo ============================================================
echo Repo: giaphai/OneClickVBSP-Release
echo Root: %ROOT_DIR%
echo Dev : %DEV_DIR%
echo.

:: 1. Kiem tra GitHub CLI
set "GH="
for /f "delims=" %%I in ('where gh.exe 2^>nul') do if not defined GH set "GH=%%I"
if not defined GH if exist "%ProgramFiles%\GitHub CLI\gh.exe" set "GH=%ProgramFiles%\GitHub CLI\gh.exe"

if not defined GH (
    echo [LOI] Khong tim thay GitHub CLI gh.exe.
    echo Vui long cai dat GitHub CLI de su dung tinh nang phat hanh tu dong.
    pause
    exit /b 1
)

"%GH%" auth status >nul 2>&1
if errorlevel 1 (
    echo [LOI] GitHub CLI chua dang nhap. Vui long chay 'gh auth login'.
    pause
    exit /b 1
)

:: 2. Tu dong tinh toan phien ban moi (vYYYY.MM.DD.build tang dan trong ngay)
if not "%~1"=="" (
    set "TARGET_VER=%~1"
) else (
    for /f "delims=" %%I in ('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%DEV_DIR%\get_next_version.ps1"') do set "TARGET_VER=%%I"
)

if defined TARGET_VER set "TARGET_VER=%TARGET_VER: =%"
if not defined TARGET_VER set "TARGET_VER=v2026.10.29.1"
if not "%TARGET_VER:~0,1%"=="v" set "TARGET_VER=v%TARGET_VER%"

echo Phien ban tu dong tao: %TARGET_VER%

echo.
echo ============================================================
echo [1/5] CAP NHAT VERSION VA DONG GOI REPACK
echo ============================================================
echo Phien ban: %TARGET_VER%

:: Cap nhat $toolVersion trong dev/decompressed_source.ps1 va version.txt
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%DEV_DIR%\update_version.ps1" -TargetVersion "%TARGET_VER%"

:: Chay repack de ma hoa AES-256 va tao payload moi
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%DEV_DIR%\repack.ps1"
if errorlevel 1 (
    echo [LOI] Repack that bai.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo [2/5] CHAY KIEM THU TOAN DIEN
echo ============================================================
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%DEV_DIR%\verify_all_features.ps1"
if errorlevel 1 (
    echo [CANH BAO] Co loi khi kiem thu. Ban co chac muon tiep tuc phat hanh?
    set /p "CONT=Tiep tuc phat hanh? (y/n): "
    if /I not "%CONT%"=="y" exit /b 1
)

echo.
echo ============================================================
echo [3/5] GIT COMMIT VA PUSH
echo ============================================================
cd /d "%ROOT_DIR%"
git add OneClickVBSP.bat OneClickVBSP_2026.ps1 version.txt README.md TAO_BAN_PHAT_HANH_MOI.bat
git commit -m "Release %TARGET_VER%: Cap nhat tinh nang va bo tien ich OneClickVBSP"
git push origin main
if errorlevel 1 (
    echo [CANH BAO] Git push gap loi hoac khong co thay doi moi.
)

echo.
echo ============================================================
echo [4/5] TAO GITHUB RELEASE + UPLOAD ASSETS
echo ============================================================

set "BAT_FILE=%ROOT_DIR%\OneClickVBSP.bat"
set "PS1_FILE=%ROOT_DIR%\OneClickVBSP_2026.ps1"
set "VER_FILE=%ROOT_DIR%\version.txt"

"%GH%" release view "%TARGET_VER%" --repo giaphai/OneClickVBSP-Release >nul 2>&1
if not errorlevel 1 (
    echo GitHub Release %TARGET_VER% da ton tai. Dang cap nhat upload de file moi...
    "%GH%" release upload "%TARGET_VER%" "%BAT_FILE%" "%PS1_FILE%" "%VER_FILE%" --repo giaphai/OneClickVBSP-Release --clobber
) else (
    echo Dang tao GitHub Release moi %TARGET_VER%...
    "%GH%" release create "%TARGET_VER%" "%BAT_FILE%" "%PS1_FILE%" "%VER_FILE%" --repo giaphai/OneClickVBSP-Release --title "OneClickVBSP %TARGET_VER%" --notes "Ban phat hanh tu dong OneClickVBSP %TARGET_VER%" --latest
)

if errorlevel 1 (
    echo [LOI] Phat hanh GitHub Release that bai.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo [5/5] HOAN TAT PHAT HANH
echo ============================================================
echo Da phat hanh thanh cong ban %TARGET_VER% len GitHub Releases!
echo Link: https://github.com/giaphai/OneClickVBSP-Release/releases/latest
echo.
pause
