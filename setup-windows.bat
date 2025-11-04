@echo off
REM Windows setup script for Claude Docker
REM Prepares build context and creates necessary directories

echo ========================================
echo Claude Docker - Windows Setup
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

REM Check if Claude is authenticated
if not exist "%USERPROFILE%\.claude.json" (
    echo ERROR: Claude Code authentication not found!
    echo.
    echo Please authenticate Claude Code first:
    echo   1. Run: npm install -g @anthropic-ai/claude-code
    echo   2. Run: claude
    echo   3. Complete the authentication process
    echo.
    pause
    exit /b 1
)

echo [1/6] Copying Claude authentication to build context...
copy "%USERPROFILE%\.claude.json" ".claude.json" >nul
if errorlevel 1 (
    echo ERROR: Failed to copy Claude authentication file
    pause
    exit /b 1
)
echo OK - Claude authentication copied

REM Check and create .env
echo.
echo [2/6] Checking .env file...
if not exist ".env" (
    if exist ".env.example" (
        echo Creating .env from .env.example...
        copy ".env.example" ".env" >nul
        echo OK - .env created from example
        echo.
        echo IMPORTANT: Please edit .env with your configuration!
        set /p EDIT_ENV="Open .env in notepad now? (y/n): "
        if /i "%EDIT_ENV%"=="y" notepad .env
    ) else (
        echo ERROR: .env.example not found!
        pause
        exit /b 1
    )
) else (
    echo OK - .env file exists
)

REM Create necessary directories
echo.
echo [3/6] Creating persistent directories...
if not exist "%USERPROFILE%\.claude-docker" mkdir "%USERPROFILE%\.claude-docker"
if not exist "%USERPROFILE%\.claude-docker\claude-home" mkdir "%USERPROFILE%\.claude-docker\claude-home"
if not exist "%USERPROFILE%\.claude-docker\ssh" mkdir "%USERPROFILE%\.claude-docker\ssh"
if not exist "%USERPROFILE%\.claude-docker\scripts" mkdir "%USERPROFILE%\.claude-docker\scripts"
echo OK - Directories created

REM Copy template files
echo.
echo [4/6] Copying template files...
if exist ".claude\CLAUDE.md" (
    if not exist "%USERPROFILE%\.claude-docker\claude-home\CLAUDE.md" (
        xcopy /E /I /Y ".claude\*" "%USERPROFILE%\.claude-docker\claude-home\" >nul 2>&1
        echo OK - Template configuration copied
    ) else (
        echo OK - Template files already exist
    )
)

if exist "scripts" (
    if not exist "%USERPROFILE%\.claude-docker\scripts\sys_utils.py" (
        xcopy /E /I /Y "scripts\*" "%USERPROFILE%\.claude-docker\scripts\" >nul 2>&1
        echo OK - Template scripts copied
    ) else (
        echo OK - Scripts already exist
    )
)

REM Copy credentials to persistent location
echo.
echo [5/6] Setting up persistent Claude credentials...
if exist "%USERPROFILE%\.claude\.credentials.json" (
    if not exist "%USERPROFILE%\.claude-docker\claude-home\.credentials.json" (
        copy "%USERPROFILE%\.claude\.credentials.json" "%USERPROFILE%\.claude-docker\claude-home\.credentials.json" >nul
        echo OK - Credentials copied to persistent location
    ) else (
        echo OK - Credentials already in persistent location
    )
)

REM Build the Docker image
echo.
echo [6/6] Building Docker image...
echo This may take a few minutes on first run...
echo.

docker-compose build
if errorlevel 1 (
    echo.
    echo ERROR: Docker build failed!
    echo Check the error messages above.
    pause
    exit /b 1
)

REM Clean up build context
del ".claude.json" >nul 2>&1

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo You can now run Claude Docker with:
echo   start-claude-docker.bat
echo.
echo Or use Docker Compose directly:
echo   docker-compose run --rm claude-docker
echo.
pause
