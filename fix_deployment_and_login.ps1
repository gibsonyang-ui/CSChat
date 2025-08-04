# Fix deployment and login issues

Write-Host "=== Fixing Chatwoot Deployment and Login Issues ===" -ForegroundColor Green
Write-Host ""

# 1. Stop all containers
Write-Host "1. Stopping all containers..." -ForegroundColor Yellow
docker-compose down -v
docker system prune -f

# 2. Fix .env file for development
Write-Host ""
Write-Host "2. Fixing .env configuration..." -ForegroundColor Yellow

$envContent = @"
# Chatwoot Development Environment Configuration

# Used to verify the integrity of signed cookies
SECRET_KEY_BASE=0D5BFDBCF455A014C7FDB1EF4AC48E0EEED7D47BC95E1491B26D37AE26597A04983A96AD9792CCB40C7BBD5E16468F2B7ADE12160D3D489F04E5310B76CE7384

# Replace with the URL you are planning to use for your app
FRONTEND_URL=http://localhost:3000

# Force all access to the app over SSL, default is set to false
FORCE_SSL=false

# This lets you control new sign ups on your chatwoot installation
ENABLE_ACCOUNT_SIGNUP=true

# Redis config
REDIS_URL=redis://redis:6379
REDIS_PASSWORD=chatwoot_redis_password

# Postgres Database config variables
POSTGRES_HOST=postgres
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=
POSTGRES_DB=chatwoot
RAILS_ENV=development
RAILS_MAX_THREADS=5

# The email from which all outgoing emails are sent
MAILER_SENDER_EMAIL=Chatwoot <noreply@localhost>

# SMTP configuration for development (using mailhog)
SMTP_DOMAIN=localhost
SMTP_ADDRESS=mailhog
SMTP_PORT=1025
SMTP_USERNAME=
SMTP_PASSWORD=
SMTP_AUTHENTICATION=
SMTP_ENABLE_STARTTLS_AUTO=false
SMTP_OPENSSL_VERIFY_MODE=none

# Storage
ACTIVE_STORAGE_SERVICE=local

# Log settings
RAILS_LOG_TO_STDOUT=true
LOG_LEVEL=debug

# Development settings
NODE_ENV=development
VITE_DEV_SERVER_HOST=vite

# Mobile app env variables
IOS_APP_ID=L7YLMN4634.com.chatwoot.app
ANDROID_BUNDLE_ID=com.chatwoot.app

# Feature flags
ENABLE_ACCOUNT_SIGNUP=true
ENABLE_FEATURE_ENHANCED_AGENTS=true
"@

$envContent | Out-File -FilePath ".env" -Encoding UTF8
Write-Host "✅ .env file updated for development" -ForegroundColor Green

# 3. Create a simple docker-compose for development
Write-Host ""
Write-Host "3. Creating simplified docker-compose..." -ForegroundColor Yellow

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
      - POSTGRES_PASSWORD=
      - POSTGRES_HOST_AUTH_METHOD=trust

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
      - ./app/controllers:/app/app/controllers
      - ./app/javascript:/app/app/javascript
      - ./public:/app/public
      - ./config:/app/config
    environment:
      - RAILS_ENV=development
      - SECRET_KEY_BASE=0D5BFDBCF455A014C7FDB1EF4AC48E0EEED7D47BC95E1491B26D37AE26597A04983A96AD9792CCB40C7BBD5E16468F2B7ADE12160D3D489F04E5310B76CE7384
      - FRONTEND_URL=http://localhost:3000
      - POSTGRES_HOST=postgres
      - POSTGRES_USERNAME=postgres
      - POSTGRES_PASSWORD=
      - POSTGRES_DB=chatwoot
      - REDIS_URL=redis://:chatwoot_redis_password@redis:6379
      - ENABLE_ACCOUNT_SIGNUP=true
      - RAILS_LOG_TO_STDOUT=true
      - LOG_LEVEL=debug
    command: >
      sh -c "
        echo 'Waiting for PostgreSQL...'
        while ! nc -z postgres 5432; do sleep 1; done
        echo 'PostgreSQL is ready!'
        
        echo 'Running database setup...'
        bundle exec rails db:create db:migrate db:seed
        
        echo 'Creating admin user...'
        bundle exec rails runner \"
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
        \"
        
        echo 'Starting Chatwoot...'
        bundle exec rails server -b 0.0.0.0 -p 3000
      "

volumes:
  postgres_data:
  redis_data:
"@

$dockerComposeContent | Out-File -FilePath "docker-compose.simple.yaml" -Encoding UTF8
Write-Host "✅ Simple docker-compose created" -ForegroundColor Green

# 4. Start services
Write-Host ""
Write-Host "4. Starting services..." -ForegroundColor Yellow
docker-compose -f docker-compose.simple.yaml up -d

# 5. Wait for services to start
Write-Host ""
Write-Host "5. Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# 6. Check service status
Write-Host ""
Write-Host "6. Checking service status..." -ForegroundColor Yellow
docker-compose -f docker-compose.simple.yaml ps

# 7. Check logs
Write-Host ""
Write-Host "7. Checking Chatwoot logs..." -ForegroundColor Yellow
docker-compose -f docker-compose.simple.yaml logs chatwoot --tail=20

# 8. Test database connection
Write-Host ""
Write-Host "8. Testing database connection..." -ForegroundColor Yellow
try {
    docker-compose -f docker-compose.simple.yaml exec -T postgres psql -U postgres -d chatwoot -c "SELECT COUNT(*) FROM users;"
    Write-Host "✅ Database connection successful" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ Database connection test failed" -ForegroundColor Yellow
}

# 9. Test application
Write-Host ""
Write-Host "9. Testing application..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Application is responding" -ForegroundColor Green
    }
}
catch {
    Write-Host "⚠️ Application test failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Deployment Fix Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Access Information:" -ForegroundColor Cyan
Write-Host "  Main App: http://localhost:3000" -ForegroundColor White
Write-Host "  Test Page: http://localhost:3000/enhanced_agents_test.html" -ForegroundColor White
Write-Host ""
Write-Host "Login Credentials:" -ForegroundColor Cyan
Write-Host "  Email: gibson@localhost.com" -ForegroundColor White
Write-Host "  Password: Gibson888555!" -ForegroundColor White
Write-Host ""
Write-Host "If login still fails, check logs with:" -ForegroundColor Yellow
Write-Host "  docker-compose -f docker-compose.simple.yaml logs chatwoot" -ForegroundColor Gray
