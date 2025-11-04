@echo off
REM Windows batch file to start Claude Docker using Docker Compose
REM Usage: start-claude-docker.bat [path-to-project]

echo ========================================
echo Claude Docker - Windows Launcher
echo ========================================
echo.

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not running!
    echo Please start Docker Desktop and try again.
    pause
    exit /b 1
)

REM Create necessary directories
if not exist "%USERPROFILE%\.claude-docker\claude-home" (
    echo Creating Claude home directory...
    mkdir "%USERPROFILE%\.claude-docker\claude-home"
)

if not exist "%USERPROFILE%\.claude-docker\ssh" (
    echo Creating SSH directory...
    mkdir "%USERPROFILE%\.claude-docker\ssh"
)

if not exist "%USERPROFILE%\.claude-docker\scripts" (
    echo Creating scripts directory...
    mkdir "%USERPROFILE%\.claude-docker\scripts"
)

REM Copy Claude authentication if it exists
if exist "%USERPROFILE%\.claude\.credentials.json" (
    if not exist "%USERPROFILE%\.claude-docker\claude-home\.credentials.json" (
        echo Copying Claude credentials...
        copy "%USERPROFILE%\.claude\.credentials.json" "%USERPROFILE%\.claude-docker\claude-home\.credentials.json" >nul
    )
)

REM Copy template files on first run
if not exist "%USERPROFILE%\.claude-docker\claude-home\CLAUDE.md" (
    if exist ".claude\CLAUDE.md" (
        echo Copying template configuration...
        xcopy /E /I /Y ".claude\*" "%USERPROFILE%\.claude-docker\claude-home\" >nul
    )
)

if not exist "%USERPROFILE%\.claude-docker\scripts\sys_utils.py" (
    if exist "scripts\*" (
        echo Copying template scripts...
        xcopy /E /I /Y "scripts\*" "%USERPROFILE%\.claude-docker\scripts\" >nul
    )
)

REM Check if .env exists
if not exist ".env" (
    if exist ".env.example" (
        echo.
        echo WARNING: No .env file found!
        echo Creating .env from .env.example...
        copy ".env.example" ".env" >nul
        echo.
        echo Please edit .env file with your configuration before continuing.
        echo Press any key to open .env in notepad...
        pause >nul
        notepad .env
    )
)

REM Set project directory (use argument if provided, otherwise current directory)
if "%~1"=="" (
    set "PROJECT_DIR=%CD%"
) else (
    set "PROJECT_DIR=%~1"
)

echo.
echo Project directory: %PROJECT_DIR%
echo Claude home: %USERPROFILE%\.claude-docker\claude-home
echo.

REM Load environment variables from .env file
if exist ".env" (
    echo Loading configuration from .env...
    for /f "usebackq tokens=1,* delims==" %%a in (".env") do (
        set "%%a=%%b"
    )
)

REM Export necessary environment variables for Docker Compose
set "PROJECT_DIR=%PROJECT_DIR%"
set "HOME=%USERPROFILE%"

echo.
echo Starting Claude Docker container...
echo.
echo TIP: Once inside the container, run:
echo   - 'claude' to start Claude Code
echo   - 'exit' to leave the container
echo.

REM Start the container with docker-compose
docker-compose run --rm claude-docker

echo.
echo Claude Docker session ended.
pause
