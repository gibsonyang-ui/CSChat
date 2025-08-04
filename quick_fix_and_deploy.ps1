# Quick fix and deploy solution

Write-Host "=== Quick Fix and Deploy ===" -ForegroundColor Green
Write-Host ""

# 1. Stop current containers
Write-Host "1. Stopping current containers..." -ForegroundColor Yellow
docker-compose -f docker-compose.production.yaml down 2>$null
docker-compose down 2>$null

# 2. Use the original working setup
Write-Host ""
Write-Host "2. Using original working setup..." -ForegroundColor Yellow

# Create a minimal working docker-compose
$workingCompose = @"
version: '3.8'

services:
  postgres:
    image: postgres:15
    restart: always
    ports:
      - '5432:5432'
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=chatwoot
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=chatwoot_password

  redis:
    image: redis:alpine
    restart: always
    command: ["sh", "-c", "redis-server --requirepass chatwoot_redis_password"]
    volumes:
      - redis_data:/data
    ports:
      - '6379:6379'

  chatwoot:
    image: chatwoot/chatwoot:v3.12.0
    restart: always
    depends_on:
      - postgres
      - redis
    ports:
      - '3000:3000'
    volumes:
      - ./public:/app/public
    environment:
      - RAILS_ENV=production
      - SECRET_KEY_BASE=0D5BFDBCF455A014C7FDB1EF4AC48E0EEED7D47BC95E1491B26D37AE26597A04983A96AD9792CCB40C7BBD5E16468F2B7ADE12160D3D489F04E5310B76CE7384
      - FRONTEND_URL=http://localhost:3000
      - POSTGRES_HOST=postgres
      - POSTGRES_USERNAME=postgres
      - POSTGRES_PASSWORD=chatwoot_password
      - POSTGRES_DB=chatwoot
      - REDIS_URL=redis://:chatwoot_redis_password@redis:6379
      - ENABLE_ACCOUNT_SIGNUP=true
      - RAILS_LOG_TO_STDOUT=true

volumes:
  postgres_data:
  redis_data:
"@

$workingCompose | Out-File -FilePath "docker-compose.working.yaml" -Encoding UTF8
Write-Host "✅ Working docker-compose created" -ForegroundColor Green

# 3. Start services
Write-Host ""
Write-Host "3. Starting services..." -ForegroundColor Yellow
docker-compose -f docker-compose.working.yaml up -d

# 4. Wait for startup
Write-Host ""
Write-Host "4. Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 45

# 5. Check status
Write-Host ""
Write-Host "5. Checking service status..." -ForegroundColor Yellow
docker-compose -f docker-compose.working.yaml ps

# 6. Test application
Write-Host ""
Write-Host "6. Testing application..." -ForegroundColor Yellow
$maxAttempts = 10
$attempt = 1

while ($attempt -le $maxAttempts) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Application is responding (attempt $attempt)" -ForegroundColor Green
            break
        }
    }
    catch {
        Write-Host "⏳ Attempt $attempt failed, retrying..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        $attempt++
    }
}

if ($attempt -gt $maxAttempts) {
    Write-Host "❌ Application failed to start after $maxAttempts attempts" -ForegroundColor Red
    Write-Host "Checking logs..." -ForegroundColor Yellow
    docker-compose -f docker-compose.working.yaml logs chatwoot --tail=20
} else {
    Write-Host "✅ Application started successfully!" -ForegroundColor Green
}

# 7. Create admin user
Write-Host ""
Write-Host "7. Creating admin user..." -ForegroundColor Yellow
try {
    docker-compose -f docker-compose.working.yaml exec -T chatwoot bundle exec rails runner "
      account = Account.find_or_create_by(name: 'Default Account')
      user = User.find_or_create_by(email: 'gibson@localhost.com') do |u|
        u.name = 'Gibson Yang'
        u.password = 'Gibson888555!'
        u.password_confirmation = 'Gibson888555!'
        u.confirmed_at = Time.current
      end
      
      account_user = AccountUser.find_or_create_by(account: account, user: user) do |au|
        au.role = 'administrator'
      end
      
      puts 'Admin user created: gibson@localhost.com / Gibson888555!'
    "
    Write-Host "✅ Admin user created" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ Admin user creation failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 8. Test enhanced API
Write-Host ""
Write-Host "8. Testing enhanced API..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:3000/enhanced_agents_test.html" -TimeoutSec 10
    Write-Host "✅ Test page is accessible" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ Test page not accessible: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Quick Fix Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 Access Information:" -ForegroundColor Cyan
Write-Host "  Main App: http://localhost:3000" -ForegroundColor White
Write-Host "  Test Page: http://localhost:3000/enhanced_agents_test.html" -ForegroundColor White
Write-Host ""
Write-Host "🔑 Login Credentials:" -ForegroundColor Cyan
Write-Host "  Email: gibson@localhost.com" -ForegroundColor White
Write-Host "  Password: Gibson888555!" -ForegroundColor White
Write-Host ""
Write-Host "📋 Management Commands:" -ForegroundColor Yellow
Write-Host "  Check logs: docker-compose -f docker-compose.working.yaml logs chatwoot" -ForegroundColor Gray
Write-Host "  Restart: docker-compose -f docker-compose.working.yaml restart chatwoot" -ForegroundColor Gray
Write-Host "  Stop: docker-compose -f docker-compose.working.yaml down" -ForegroundColor Gray
Write-Host ""

# 9. Open browser
$openBrowser = Read-Host "Open browser to test login? (y/n)"
if ($openBrowser -eq "y" -or $openBrowser -eq "Y") {
    try {
        Start-Process "http://localhost:3000"
        Write-Host "✅ Browser opened" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ Could not open browser" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🎉 Deployment complete! Try logging in now." -ForegroundColor Green
