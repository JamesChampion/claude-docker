@echo off
REM Simple Windows launcher for Claude Docker
REM Just builds minimal image and runs container

echo ========================================
echo Claude Docker - Simple Windows Setup
echo ========================================
echo.

REM Check Docker
docker info >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker Desktop is not running!
    echo Please start Docker Desktop and try again.
    pause
    exit /b 1
)

REM Check Claude authentication
if not exist "%USERPROFILE%\.claude\.credentials.json" (
    echo ERROR: Claude not authenticated!
    echo.
    echo Please authenticate Claude first:
    echo   1. npm install -g @anthropic-ai/claude-code
    echo   2. claude
    echo.
    pause
    exit /b 1
)

REM Create directories
echo Creating directories...
if not exist "%USERPROFILE%\.claude-docker" mkdir "%USERPROFILE%\.claude-docker"
if not exist "%USERPROFILE%\.claude-docker\claude-home" mkdir "%USERPROFILE%\.claude-docker\claude-home"
if not exist "%USERPROFILE%\.claude-docker\ssh" mkdir "%USERPROFILE%\.claude-docker\ssh"
if not exist "%USERPROFILE%\.claude-docker\scripts" mkdir "%USERPROFILE%\.claude-docker\scripts"

REM Check if image exists
docker images -q claude-docker-windows:latest >temp.txt 2>&1
set /p IMAGE_ID=<temp.txt
del temp.txt

if "%IMAGE_ID%"=="" (
    echo.
    echo Building Docker image (first time only)...
    echo.

    docker build -f Dockerfile.windows -t claude-docker-windows:latest .

    if errorlevel 1 (
        echo.
        echo ERROR: Docker build failed!
        pause
        exit /b 1
    )
)

echo.
echo Starting container...
echo Project: %CD%
echo.
echo Once inside, just run: claude
echo.

REM Set environment and start container
set "PROJECT_DIR=%CD%"
docker-compose -f docker-compose.windows.yml run --rm claude-docker

echo.
echo Session ended.
pause
