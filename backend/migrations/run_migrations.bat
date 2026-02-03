@echo off
REM timingle Backend Migrations 실행 스크립트 (Windows)
REM WSL을 통해 bash 스크립트를 실행합니다.

echo ======================================
echo   timingle Backend Migrations
echo ======================================
echo.

REM WSL 배포판 이름
set WSL_DISTRO=AlmaLinux-Kitten-10

REM 스크립트 경로 (WSL 경로)
set SCRIPT_PATH=/mnt/d/projects/timingle2/backend/migrations/run_migrations.sh

echo Running migrations via WSL...
echo.

REM WSL을 통해 bash 스크립트 실행
wsl -d %WSL_DISTRO% bash %SCRIPT_PATH%

echo.
echo Press any key to exit...
pause >nul
