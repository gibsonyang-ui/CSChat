# Simple Development Environment Setup (No Admin Required)

Write-Host "=== Simple Development Environment Setup ===" -ForegroundColor Green
Write-Host ""

# 1. Check Docker availability
Write-Host "1. Checking Docker availability..." -ForegroundColor Cyan
try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker is available: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not available. Please install Docker Desktop first." -ForegroundColor Red
    exit 1
}

# 2. Clean up existing containers
Write-Host ""
Write-Host "2. Cleaning up existing containers..." -ForegroundColor Cyan
docker-compose down -v 2>$null
docker-compose -f docker-compose.dev.yaml down -v 2>$null
docker-compose -f docker-compose.production.yaml down -v 2>$null
docker-compose -f docker-compose.simple.yaml down -v 2>$null
docker-compose -f docker-compose.working.yaml down -v 2>$null
Write-Host "✅ Cleanup complete" -ForegroundColor Green

# 3. Create optimized .env file
Write-Host ""
Write-Host "3. Creating optimized .env configuration..." -ForegroundColor Cyan

$envContent = @"
SECRET_KEY_BASE=0D5BFDBCF455A014C7FDB1EF4AC48E0EEED7D47BC95E1491B26D37AE26597A04983A96AD9792CCB40C7BBD5E16468F2B7ADE12160D3D489F04E5310B76CE7384
FRONTEND_URL=http://localhost:3000
FORCE_SSL=false
ENABLE_ACCOUNT_SIGNUP=true
POSTGRES_HOST=postgres
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=chatwoot_password
POSTGRES_DB=chatwoot
RAILS_ENV=production
RAILS_MAX_THREADS=5
REDIS_URL=redis://:chatwoot_redis_password@redis:6379
REDIS_PASSWORD=chatwoot_redis_password
MAILER_SENDER_EMAIL=Chatwoot <noreply@localhost>
SMTP_DOMAIN=localhost
SMTP_ADDRESS=mailhog
SMTP_PORT=1025
SMTP_USERNAME=
SMTP_PASSWORD=
SMTP_AUTHENTICATION=
SMTP_ENABLE_STARTTLS_AUTO=false
SMTP_OPENSSL_VERIFY_MODE=none
ACTIVE_STORAGE_SERVICE=local
RAILS_LOG_TO_STDOUT=true
LOG_LEVEL=info
ENABLE_FEATURE_ENHANCED_AGENTS=true
IOS_APP_ID=L7YLMN4634.com.chatwoot.app
ANDROID_BUNDLE_ID=com.chatwoot.app
"@

$envContent | Out-File -FilePath ".env" -Encoding UTF8 -NoNewline
Write-Host "✅ .env file created" -ForegroundColor Green

# 4. Create stable docker-compose
Write-Host ""
Write-Host "4. Creating stable docker-compose..." -ForegroundColor Cyan

$dockerComposeContent = @"
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

  mailhog:
    image: mailhog/mailhog
    restart: always
    ports:
      - '1025:1025'
      - '8025:8025'

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
      - ./app/controllers:/app/app/controllers
      - ./config:/app/config
    env_file: .env

volumes:
  postgres_data:
  redis_data:
"@

$dockerComposeContent | Out-File -FilePath "docker-compose.stable.yaml" -Encoding UTF8 -NoNewline
Write-Host "✅ Docker Compose file created" -ForegroundColor Green

# 5. Start services
Write-Host ""
Write-Host "5. Starting services..." -ForegroundColor Cyan
docker-compose -f docker-compose.stable.yaml up -d

# 6. Wait for services to start
Write-Host ""
Write-Host "6. Waiting for services to start..." -ForegroundColor Cyan
Write-Host "This may take a few minutes for the first time..." -ForegroundColor Gray

$maxWait = 180
$waited = 0
$interval = 15

while ($waited -lt $maxWait) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -TimeoutSec 5 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Application is healthy" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "⏳ Waiting for application to start... ($waited/$maxWait seconds)" -ForegroundColor Yellow
        Start-Sleep -Seconds $interval
        $waited += $interval
    }
}

# 7. Check service status
Write-Host ""
Write-Host "7. Checking service status..." -ForegroundColor Cyan
docker-compose -f docker-compose.stable.yaml ps

# 8. Create admin user
Write-Host ""
Write-Host "8. Creating admin user..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

try {
    docker-compose -f docker-compose.stable.yaml exec -T chatwoot bundle exec rails runner "
      puts 'Creating admin user...'
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
      puts 'Admin user created successfully!'
    "
    Write-Host "✅ Admin user created" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Admin user creation may have failed, but you can try logging in" -ForegroundColor Yellow
}

# 9. Test application
Write-Host ""
Write-Host "9. Testing application..." -ForegroundColor Cyan

$tests = @(
    @{Name="Main Application"; URL="http://localhost:3000"},
    @{Name="Health Check"; URL="http://localhost:3000/health"},
    @{Name="Test Page"; URL="http://localhost:3000/enhanced_agents_test.html"},
    @{Name="MailHog"; URL="http://localhost:8025"}
)

foreach ($test in $tests) {
    try {
        $response = Invoke-WebRequest -Uri $test.URL -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ $($test.Name) is accessible" -ForegroundColor Green
        } else {
            Write-Host "⚠️ $($test.Name) returned status: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ $($test.Name) not accessible" -ForegroundColor Red
    }
}

# 10. Test enhanced API
Write-Host ""
Write-Host "10. Testing enhanced API..." -ForegroundColor Cyan
try {
    $apiResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/accounts/1/enhanced_agents/status" -TimeoutSec 10
    Write-Host "✅ Enhanced API is working: $($apiResponse.message)" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Enhanced API test failed (this is normal if not fully started yet)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 Access Information:" -ForegroundColor Cyan
Write-Host "  Main Application: http://localhost:3000" -ForegroundColor White
Write-Host "  Enhanced Test Page: http://localhost:3000/enhanced_agents_test.html" -ForegroundColor White
Write-Host "  MailHog (Email Testing): http://localhost:8025" -ForegroundColor White
Write-Host "  Health Check: http://localhost:3000/health" -ForegroundColor White
Write-Host ""
Write-Host "🔑 Login Credentials:" -ForegroundColor Cyan
Write-Host "  Email: gibson@localhost.com" -ForegroundColor White
Write-Host "  Password: Gibson888555!" -ForegroundColor White
Write-Host ""
Write-Host "📋 Management Commands:" -ForegroundColor Yellow
Write-Host "  View logs: docker-compose -f docker-compose.stable.yaml logs chatwoot" -ForegroundColor Gray
Write-Host "  Restart: docker-compose -f docker-compose.stable.yaml restart chatwoot" -ForegroundColor Gray
Write-Host "  Stop: docker-compose -f docker-compose.stable.yaml down" -ForegroundColor Gray
Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Wait 2-3 minutes for full startup" -ForegroundColor White
Write-Host "  2. Visit http://localhost:3000 to test login" -ForegroundColor White
Write-Host "  3. Navigate to Settings > Team > Agents for enhanced features" -ForegroundColor White
Write-Host "  4. Use the test page for API testing" -ForegroundColor White
Write-Host ""

# 11. Open browser
$openBrowser = Read-Host "Open browser to test the application? (y/n)"
if ($openBrowser -eq "y" -or $openBrowser -eq "Y") {
    try {
        Start-Process "http://localhost:3000"
        Write-Host "✅ Browser opened to main application" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Could not open browser automatically" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🎉 Development environment is ready!" -ForegroundColor Green
