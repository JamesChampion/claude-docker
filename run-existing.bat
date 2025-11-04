@echo off
REM Windows launcher using existing Dockerfile and scripts
echo ========================================
echo Claude Docker - Using Existing Setup
echo ========================================
echo.

REM Check Docker
docker info >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not running!
    pause
    exit /b 1
)

REM Check Claude auth
if not exist "%USERPROFILE%\.claude.json" (
    echo ERROR: Claude not authenticated on Windows!
    echo Please run: claude
    pause
    exit /b 1
)

REM Create .env if needed
if not exist ".env" (
    if exist ".env.example" (
        echo Creating .env from example...
        copy ".env.example" ".env" >nul
    ) else (
        REM Create minimal .env
        echo Creating minimal .env...
        echo # Minimal .env for Windows > .env
    )
)

REM Create directories
if not exist "%USERPROFILE%\.claude-docker\claude-home" mkdir "%USERPROFILE%\.claude-docker\claude-home"
if not exist "%USERPROFILE%\.claude-docker\ssh" mkdir "%USERPROFILE%\.claude-docker\ssh"
if not exist "%USERPROFILE%\.claude-docker\scripts" mkdir "%USERPROFILE%\.claude-docker\scripts"

REM Copy auth to build context
echo Preparing build context...
copy "%USERPROFILE%\.claude.json" ".claude.json" >nul

REM Build if needed
docker images -q claude-docker:latest >temp.txt 2>&1
set /p IMAGE_ID=<temp.txt
del temp.txt

if "%IMAGE_ID%"=="" (
    echo Building Docker image (first time)...
    docker-compose -f docker-compose-existing.yml build
    if errorlevel 1 (
        echo Build failed!
        del .claude.json
        pause
        exit /b 1
    )
)

REM Clean up build context
del .claude.json 2>nul

REM Run
echo.
echo Starting container...
echo.
docker-compose -f docker-compose-existing.yml run --rm claude-docker

echo.
echo Session ended.
pause
