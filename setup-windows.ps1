# PowerShell setup script for Claude Docker
# Prepares build context and creates necessary directories

param()

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Claude Docker - Windows Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
try {
    docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker is not running"
    }
} catch {
    Write-Host "ERROR: Docker is not running!" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if Claude is authenticated
$claudeAuth = "$env:USERPROFILE\.claude.json"
if (-not (Test-Path $claudeAuth)) {
    Write-Host "ERROR: Claude Code authentication not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please authenticate Claude Code first:" -ForegroundColor Yellow
    Write-Host "  1. Run: npm install -g @anthropic-ai/claude-code"
    Write-Host "  2. Run: claude"
    Write-Host "  3. Complete the authentication process"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[1/6] Copying Claude authentication to build context..." -ForegroundColor Green
try {
    Copy-Item $claudeAuth ".claude.json" -Force
    Write-Host "OK - Claude authentication copied" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to copy Claude authentication file" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Read-Host "Press Enter to exit"
    exit 1
}

# Check and create .env
Write-Host ""
Write-Host "[2/6] Checking .env file..." -ForegroundColor Green
if (-not (Test-Path ".env")) {
    if (Test-Path ".env.example") {
        Write-Host "Creating .env from .env.example..." -ForegroundColor Yellow
        Copy-Item ".env.example" ".env"
        Write-Host "OK - .env created from example" -ForegroundColor Green
        Write-Host ""
        Write-Host "IMPORTANT: Please edit .env with your configuration!" -ForegroundColor Yellow
        $editEnv = Read-Host "Open .env in notepad now? (y/n)"
        if ($editEnv -eq 'y' -or $editEnv -eq 'Y') {
            notepad .env
        }
    } else {
        Write-Host "ERROR: .env.example not found!" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
} else {
    Write-Host "OK - .env file exists" -ForegroundColor Green
}

# Create necessary directories
Write-Host ""
Write-Host "[3/6] Creating persistent directories..." -ForegroundColor Green
$directories = @(
    "$env:USERPROFILE\.claude-docker",
    "$env:USERPROFILE\.claude-docker\claude-home",
    "$env:USERPROFILE\.claude-docker\ssh",
    "$env:USERPROFILE\.claude-docker\scripts"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}
Write-Host "OK - Directories created" -ForegroundColor Green

# Copy template files
Write-Host ""
Write-Host "[4/6] Copying template files..." -ForegroundColor Green
if (Test-Path ".claude\CLAUDE.md") {
    if (-not (Test-Path "$env:USERPROFILE\.claude-docker\claude-home\CLAUDE.md")) {
        Copy-Item -Path ".claude\*" -Destination "$env:USERPROFILE\.claude-docker\claude-home\" -Recurse -Force
        Write-Host "OK - Template configuration copied" -ForegroundColor Green
    } else {
        Write-Host "OK - Template files already exist" -ForegroundColor Green
    }
}

if (Test-Path "scripts") {
    if (-not (Test-Path "$env:USERPROFILE\.claude-docker\scripts\sys_utils.py")) {
        Copy-Item -Path "scripts\*" -Destination "$env:USERPROFILE\.claude-docker\scripts\" -Recurse -Force
        Write-Host "OK - Template scripts copied" -ForegroundColor Green
    } else {
        Write-Host "OK - Scripts already exist" -ForegroundColor Green
    }
}

# Copy credentials to persistent location
Write-Host ""
Write-Host "[5/6] Setting up persistent Claude credentials..." -ForegroundColor Green
$claudeCreds = "$env:USERPROFILE\.claude\.credentials.json"
$persistentCreds = "$env:USERPROFILE\.claude-docker\claude-home\.credentials.json"
if ((Test-Path $claudeCreds) -and -not (Test-Path $persistentCreds)) {
    Copy-Item $claudeCreds $persistentCreds
    Write-Host "OK - Credentials copied to persistent location" -ForegroundColor Green
} else {
    Write-Host "OK - Credentials already in persistent location" -ForegroundColor Green
}

# Build the Docker image
Write-Host ""
Write-Host "[6/6] Building Docker image..." -ForegroundColor Green
Write-Host "This may take a few minutes on first run..." -ForegroundColor Yellow
Write-Host ""

docker-compose build
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Docker build failed!" -ForegroundColor Red
    Write-Host "Check the error messages above." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Clean up build context
Remove-Item ".claude.json" -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "You can now run Claude Docker with:" -ForegroundColor Cyan
Write-Host "  start-claude-docker.bat" -ForegroundColor Yellow
Write-Host ""
Write-Host "Or use Docker Compose directly:" -ForegroundColor Cyan
Write-Host "  docker-compose run --rm claude-docker" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to exit"
