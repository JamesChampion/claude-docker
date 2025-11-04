Write-Host "Starting Claude Docker (simple version)..." -ForegroundColor Cyan
Write-Host ""

# Check Docker
try {
    docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Docker not running" }
} catch {
    Write-Host "ERROR: Docker is not running!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Start container
docker-compose -f docker-compose.simple.yml run --rm claude

Write-Host ""
Write-Host "Session ended." -ForegroundColor Cyan
