# Simplified deployment script

Write-Host "Starting enhanced user management deployment..." -ForegroundColor Green

# Stop and restart containers
Write-Host "Restarting Docker containers..." -ForegroundColor Yellow
docker-compose down
docker-compose up -d --build

# Wait for startup
Write-Host "Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check status
Write-Host "Checking container status..." -ForegroundColor Yellow
docker-compose ps

Write-Host ""
Write-Host "Deployment completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Cyan
Write-Host "  Main App: http://localhost:3000" -ForegroundColor White
Write-Host "  Test Page: http://localhost:3000/enhanced_agents_test.html" -ForegroundColor White
Write-Host ""
Write-Host "Login Info:" -ForegroundColor Cyan
Write-Host "  Email: gibson@localhost.com" -ForegroundColor White
Write-Host "  Password: Gibson888555!" -ForegroundColor White
