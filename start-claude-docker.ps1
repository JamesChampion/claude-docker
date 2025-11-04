# PowerShell script to start Claude Docker using Docker Compose
# Usage: .\start-claude-docker.ps1 [-ProjectDir <path>]

param(
    [string]$ProjectDir = $PWD.Path
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Claude Docker - Windows Launcher" -ForegroundColor Cyan
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

# Define paths
$claudeDockerHome = "$env:USERPROFILE\.claude-docker"
$claudeHome = "$claudeDockerHome\claude-home"
$sshDir = "$claudeDockerHome\ssh"
$scriptsDir = "$claudeDockerHome\scripts"

# Create necessary directories
@($claudeHome, $sshDir, $scriptsDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        Write-Host "Creating directory: $_" -ForegroundColor Green
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
}

# Copy Claude authentication if it exists
$claudeCredentials = "$env:USERPROFILE\.claude\.credentials.json"
$targetCredentials = "$claudeHome\.credentials.json"
if ((Test-Path $claudeCredentials) -and -not (Test-Path $targetCredentials)) {
    Write-Host "Copying Claude credentials..." -ForegroundColor Green
    Copy-Item $claudeCredentials $targetCredentials
}

# Copy template files on first run
if (-not (Test-Path "$claudeHome\CLAUDE.md")) {
    if (Test-Path ".claude\CLAUDE.md") {
        Write-Host "Copying template configuration..." -ForegroundColor Green
        Copy-Item -Path ".claude\*" -Destination $claudeHome -Recurse -Force
    }
}

if (-not (Test-Path "$scriptsDir\sys_utils.py")) {
    if (Test-Path "scripts") {
        Write-Host "Copying template scripts..." -ForegroundColor Green
        Copy-Item -Path "scripts\*" -Destination $scriptsDir -Recurse -Force
    }
}

# Check if .env exists
if (-not (Test-Path ".env")) {
    if (Test-Path ".env.example") {
        Write-Host ""
        Write-Host "WARNING: No .env file found!" -ForegroundColor Yellow
        Write-Host "Creating .env from .env.example..." -ForegroundColor Yellow
        Copy-Item ".env.example" ".env"
        Write-Host ""
        Write-Host "Please edit .env file with your configuration." -ForegroundColor Cyan

        $response = Read-Host "Open .env in notepad now? (y/n)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            notepad .env
        }
    }
}

Write-Host ""
Write-Host "Project directory: $ProjectDir" -ForegroundColor Cyan
Write-Host "Claude home: $claudeHome" -ForegroundColor Cyan
Write-Host ""

# Set environment variables for Docker Compose
$env:PROJECT_DIR = $ProjectDir
$env:HOME = $env:USERPROFILE

# Load .env file if it exists
if (Test-Path ".env") {
    Write-Host "Loading configuration from .env..." -ForegroundColor Green
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]*?)\s*=\s*(.+?)\s*$') {
            $name = $matches[1]
            $value = $matches[2]
            Set-Item -Path "env:$name" -Value $value
        }
    }
}

Write-Host ""
Write-Host "Starting Claude Docker container..." -ForegroundColor Green
Write-Host ""
Write-Host "TIP: Once inside the container, run:" -ForegroundColor Yellow
Write-Host "  - 'claude' to start Claude Code" -ForegroundColor Yellow
Write-Host "  - 'exit' to leave the container" -ForegroundColor Yellow
Write-Host ""

# Start the container with docker-compose
docker-compose run --rm claude-docker

Write-Host ""
Write-Host "Claude Docker session ended." -ForegroundColor Cyan
Read-Host "Press Enter to exit"
