@echo off
echo Starting Claude Docker (simple version)...
echo.

REM Check Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not running!
    pause
    exit /b 1
)

REM Start the container
docker-compose -f docker-compose.simple.yml run --rm claude

echo.
echo Session ended.
pause
