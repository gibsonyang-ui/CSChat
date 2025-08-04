# Comprehensive Development Environment Setup and Verification

Write-Host "=== Comprehensive Development Environment Setup ===" -ForegroundColor Green
Write-Host ""

# Function to check if a command exists
function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# Function to install Chocolatey if not present
function Install-Chocolatey {
    if (-not (Test-Command choco)) {
        Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        refreshenv
        Write-Host "✅ Chocolatey installed" -ForegroundColor Green
    } else {
        Write-Host "✅ Chocolatey already installed" -ForegroundColor Green
    }
}

# Function to install Docker Desktop if not present
function Install-Docker {
    if (-not (Test-Command docker)) {
        Write-Host "Installing Docker Desktop..." -ForegroundColor Yellow
        choco install docker-desktop -y
        Write-Host "⚠️ Docker Desktop installed. Please restart your computer and run this script again." -ForegroundColor Yellow
        Read-Host "Press Enter to continue after restart"
    } else {
        Write-Host "✅ Docker already installed" -ForegroundColor Green
    }
}

# Function to install Git if not present
function Install-Git {
    if (-not (Test-Command git)) {
        Write-Host "Installing Git..." -ForegroundColor Yellow
        choco install git -y
        refreshenv
        Write-Host "✅ Git installed" -ForegroundColor Green
    } else {
        Write-Host "✅ Git already installed" -ForegroundColor Green
    }
}

# 1. Check and install required tools
Write-Host "1. Checking and installing required tools..." -ForegroundColor Cyan
Install-Chocolatey
Install-Git
Install-Docker

# 2. Verify Docker is running
Write-Host ""
Write-Host "2. Verifying Docker is running..." -ForegroundColor Cyan
try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker version: $dockerVersion" -ForegroundColor Green
    
    $dockerComposeVersion = docker-compose --version
    Write-Host "✅ Docker Compose version: $dockerComposeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    Write-Host "Waiting for Docker to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
}

# 3. Clean up any existing containers
Write-Host ""
Write-Host "3. Cleaning up existing containers..." -ForegroundColor Cyan
docker-compose down -v 2>$null
docker-compose -f docker-compose.production.yaml down -v 2>$null
docker-compose -f docker-compose.simple.yaml down -v 2>$null
docker-compose -f docker-compose.working.yaml down -v 2>$null
docker system prune -f
Write-Host "✅ Cleanup complete" -ForegroundColor Green

# 4. Create optimized .env file
Write-Host ""
Write-Host "4. Creating optimized .env configuration..." -ForegroundColor Cyan

$envContent = @"
# Chatwoot Development Environment Configuration
SECRET_KEY_BASE=0D5BFDBCF455A014C7FDB1EF4AC48E0EEED7D47BC95E1491B26D37AE26597A04983A96AD9792CCB40C7BBD5E16468F2B7ADE12160D3D489F04E5310B76CE7384
FRONTEND_URL=http://localhost:3000
FORCE_SSL=false
ENABLE_ACCOUNT_SIGNUP=true

# Database Configuration
POSTGRES_HOST=postgres
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=chatwoot_password
POSTGRES_DB=chatwoot
RAILS_ENV=production
RAILS_MAX_THREADS=5

# Redis Configuration
REDIS_URL=redis://:chatwoot_redis_password@redis:6379
REDIS_PASSWORD=chatwoot_redis_password

# Email Configuration
MAILER_SENDER_EMAIL=Chatwoot <noreply@localhost>
SMTP_DOMAIN=localhost
SMTP_ADDRESS=mailhog
SMTP_PORT=1025
SMTP_USERNAME=
SMTP_PASSWORD=
SMTP_AUTHENTICATION=
SMTP_ENABLE_STARTTLS_AUTO=false
SMTP_OPENSSL_VERIFY_MODE=none

# Storage and Logging
ACTIVE_STORAGE_SERVICE=local
RAILS_LOG_TO_STDOUT=true
LOG_LEVEL=info

# Feature Flags
ENABLE_FEATURE_ENHANCED_AGENTS=true

# Mobile App
IOS_APP_ID=L7YLMN4634.com.chatwoot.app
ANDROID_BUNDLE_ID=com.chatwoot.app
"@

$envContent | Out-File -FilePath ".env" -Encoding UTF8 -NoNewline
Write-Host "✅ .env file created" -ForegroundColor Green

# 5. Create production-ready docker-compose
Write-Host ""
Write-Host "5. Creating production-ready docker-compose..." -ForegroundColor Cyan

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
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:alpine
    restart: always
    command: ["sh", "-c", "redis-server --requirepass chatwoot_redis_password"]
    volumes:
      - redis_data:/data
    ports:
      - '6379:6379'
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

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
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    ports:
      - '3000:3000'
    volumes:
      - ./public:/app/public
      - ./app/controllers:/app/app/controllers
      - ./config:/app/config
    env_file: .env
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  postgres_data:
  redis_data:
"@

$dockerComposeContent | Out-File -FilePath "docker-compose.dev.yaml" -Encoding UTF8 -NoNewline
Write-Host "✅ Docker Compose file created" -ForegroundColor Green

# 6. Start services with health checks
Write-Host ""
Write-Host "6. Starting services with health checks..." -ForegroundColor Cyan
docker-compose -f docker-compose.dev.yaml up -d

# 7. Wait for services to be healthy
Write-Host ""
Write-Host "7. Waiting for services to be healthy..." -ForegroundColor Cyan
$maxWait = 180
$waited = 0
$interval = 10

while ($waited -lt $maxWait) {
    try {
        $status = docker-compose -f docker-compose.dev.yaml ps --format json | ConvertFrom-Json
        $allHealthy = $true

        foreach ($service in $status) {
            if ($service.Health -and $service.Health -ne "healthy") {
                $allHealthy = $false
                break
            }
        }

        if ($allHealthy) {
            Write-Host "✅ All services are healthy" -ForegroundColor Green
            break
        }

        Write-Host "⏳ Waiting for services to be healthy... ($waited/$maxWait seconds)" -ForegroundColor Yellow
        Start-Sleep -Seconds $interval
        $waited += $interval
    } catch {
        Write-Host "⏳ Services starting... ($waited/$maxWait seconds)" -ForegroundColor Yellow
        Start-Sleep -Seconds $interval
        $waited += $interval
    }
}

# 8. Check service status
Write-Host ""
Write-Host "8. Checking service status..." -ForegroundColor Cyan
docker-compose -f docker-compose.dev.yaml ps

# 9. Initialize database and create admin user
Write-Host ""
Write-Host "9. Initializing database and creating admin user..." -ForegroundColor Cyan
try {
    # Wait a bit more for Chatwoot to fully start
    Start-Sleep -Seconds 30

    docker-compose -f docker-compose.dev.yaml exec -T chatwoot bundle exec rails runner "
      puts 'Creating default account...'
      account = Account.find_or_create_by(name: 'Default Account')

      puts 'Creating admin user...'
      user = User.find_or_create_by(email: 'gibson@localhost.com') do |u|
        u.name = 'Gibson Yang'
        u.password = 'Gibson888555!'
        u.password_confirmation = 'Gibson888555!'
        u.confirmed_at = Time.current
      end

      puts 'Creating account user relationship...'
      account_user = AccountUser.find_or_create_by(account: account, user: user) do |au|
        au.role = 'administrator'
      end

      puts 'Admin user created successfully!'
      puts 'Email: gibson@localhost.com'
      puts 'Password: Gibson888555!'
    "
    Write-Host "✅ Database initialized and admin user created" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Database initialization failed: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Trying alternative method..." -ForegroundColor Yellow

    # Alternative method using docker exec
    try {
        docker exec cschat-chatwoot-1 bundle exec rails runner "
          account = Account.find_or_create_by(name: 'Default Account')
          user = User.find_or_create_by(email: 'gibson@localhost.com') do |u|
            u.name = 'Gibson Yang'
            u.password = 'Gibson888555!'
            u.password_confirmation = 'Gibson888555!'
            u.confirmed_at = Time.current
          end
          AccountUser.find_or_create_by(account: account, user: user) do |au|
            au.role = 'administrator'
          end
          puts 'Admin user created!'
        "
        Write-Host "✅ Admin user created via alternative method" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Alternative method also failed" -ForegroundColor Yellow
    }
}

# 10. Test application connectivity
Write-Host ""
Write-Host "10. Testing application connectivity..." -ForegroundColor Cyan
$maxAttempts = 12
$attempt = 1

while ($attempt -le $maxAttempts) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Application is responding (Status: $($response.StatusCode))" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "⏳ Attempt $attempt/$maxAttempts - Application not ready yet..." -ForegroundColor Yellow
        Start-Sleep -Seconds 15
        $attempt++
    }
}

if ($attempt -gt $maxAttempts) {
    Write-Host "❌ Application failed to respond after $maxAttempts attempts" -ForegroundColor Red
    Write-Host "Checking logs for errors..." -ForegroundColor Yellow
    docker-compose -f docker-compose.dev.yaml logs chatwoot --tail=30
}

# 11. Test enhanced features
Write-Host ""
Write-Host "11. Testing enhanced features..." -ForegroundColor Cyan
try {
    $testPageResponse = Invoke-WebRequest -Uri "http://localhost:3000/enhanced_agents_test.html" -TimeoutSec 10 -UseBasicParsing
    if ($testPageResponse.StatusCode -eq 200) {
        Write-Host "✅ Enhanced test page is accessible" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ Enhanced test page not accessible: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 12. Verify all components
Write-Host ""
Write-Host "12. Final verification..." -ForegroundColor Cyan

# Check if all containers are running
$containers = docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
Write-Host "Running containers:" -ForegroundColor White
Write-Host $containers

# Check if ports are accessible
$ports = @(3000, 5432, 6379, 8025)
foreach ($port in $ports) {
    try {
        $connection = Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue
        if ($connection.TcpTestSucceeded) {
            Write-Host "✅ Port $port is accessible" -ForegroundColor Green
        } else {
            Write-Host "❌ Port $port is not accessible" -ForegroundColor Red
        }
    } catch {
        Write-Host "⚠️ Could not test port $port" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== Development Environment Setup Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 Access Information:" -ForegroundColor Cyan
Write-Host "  Main Application: http://localhost:3000" -ForegroundColor White
Write-Host "  Enhanced Test Page: http://localhost:3000/enhanced_agents_test.html" -ForegroundColor White
Write-Host "  MailHog (Email Testing): http://localhost:8025" -ForegroundColor White
Write-Host ""
Write-Host "🔑 Login Credentials:" -ForegroundColor Cyan
Write-Host "  Email: gibson@localhost.com" -ForegroundColor White
Write-Host "  Password: Gibson888555!" -ForegroundColor White
Write-Host ""
Write-Host "📋 Management Commands:" -ForegroundColor Yellow
Write-Host "  View logs: docker-compose -f docker-compose.dev.yaml logs chatwoot" -ForegroundColor Gray
Write-Host "  Restart: docker-compose -f docker-compose.dev.yaml restart" -ForegroundColor Gray
Write-Host "  Stop: docker-compose -f docker-compose.dev.yaml down" -ForegroundColor Gray
Write-Host "  Update code: docker-compose -f docker-compose.dev.yaml restart chatwoot" -ForegroundColor Gray
Write-Host ""

# 13. Open browser for testing
$openBrowser = Read-Host "Open browser to test the application? (y/n)"
if ($openBrowser -eq "y" -or $openBrowser -eq "Y") {
    try {
        Start-Process "http://localhost:3000"
        Write-Host "✅ Browser opened to main application" -ForegroundColor Green

        Start-Sleep -Seconds 2
        Start-Process "http://localhost:3000/enhanced_agents_test.html"
        Write-Host "✅ Browser opened to test page" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Could not open browser automatically" -ForegroundColor Yellow
        Write-Host "Please manually visit: http://localhost:3000" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "🎉 Setup Complete! Your development environment is ready." -ForegroundColor Green
Write-Host "📝 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Test login at http://localhost:3000" -ForegroundColor White
Write-Host "  2. Navigate to Settings > Team > Agents to see enhanced buttons" -ForegroundColor White
Write-Host "  3. Use the test page for API testing" -ForegroundColor White
