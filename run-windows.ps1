# Simple Windows launcher for Claude Docker
# Just builds minimal image and runs container

param(
    [string]$ProjectDir = $PWD.Path
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Claude Docker - Simple Windows Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Docker
try {
    docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Docker not running" }
} catch {
    Write-Host "ERROR: Docker Desktop is not running!" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check Claude authentication
if (-not (Test-Path "$env:USERPROFILE\.claude\.credentials.json")) {
    Write-Host "ERROR: Claude not authenticated!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please authenticate Claude first:" -ForegroundColor Yellow
    Write-Host "  1. npm install -g @anthropic-ai/claude-code" -ForegroundColor Cyan
    Write-Host "  2. claude" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Create directories
Write-Host "Creating directories..." -ForegroundColor Green
$dirs = @(
    "$env:USERPROFILE\.claude-docker",
    "$env:USERPROFILE\.claude-docker\claude-home",
    "$env:USERPROFILE\.claude-docker\ssh",
    "$env:USERPROFILE\.claude-docker\scripts"
)
foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# Build image if needed
$imageExists = docker images -q claude-docker-windows:latest 2>$null
if (-not $imageExists) {
    Write-Host ""
    Write-Host "Building Docker image (first time only)..." -ForegroundColor Yellow
    Write-Host ""

    docker build -f Dockerfile.windows -t claude-docker-windows:latest .

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "ERROR: Docker build failed!" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Set environment variables for docker-compose
$env:PROJECT_DIR = $ProjectDir
$env:USERPROFILE = $env:USERPROFILE

Write-Host ""
Write-Host "Starting container..." -ForegroundColor Green
Write-Host "Project: $ProjectDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Once inside, just run: claude" -ForegroundColor Yellow
Write-Host ""

# Start container
docker-compose -f docker-compose.windows.yml run --rm claude-docker

Write-Host ""
Write-Host "Session ended." -ForegroundColor Cyan
