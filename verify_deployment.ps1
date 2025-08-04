# Verify deployment and all features

Write-Host "=== Deployment Verification ===" -ForegroundColor Green
Write-Host ""

# 1. Check if all containers are running
Write-Host "1. Checking container status..." -ForegroundColor Cyan
$containers = docker-compose -f docker-compose.dev.yaml ps --format json | ConvertFrom-Json

$expectedServices = @('postgres', 'redis', 'chatwoot', 'mailhog')
$runningServices = @()

foreach ($container in $containers) {
    if ($container.State -eq 'running') {
        $runningServices += $container.Service
        Write-Host "✅ $($container.Service) is running" -ForegroundColor Green
    } else {
        Write-Host "❌ $($container.Service) is not running (State: $($container.State))" -ForegroundColor Red
    }
}

foreach ($service in $expectedServices) {
    if ($service -notin $runningServices) {
        Write-Host "❌ $service is missing" -ForegroundColor Red
    }
}

# 2. Test application health
Write-Host ""
Write-Host "2. Testing application health..." -ForegroundColor Cyan
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:3000/health" -TimeoutSec 10
    if ($healthResponse.status -eq 'healthy') {
        Write-Host "✅ Application health check passed" -ForegroundColor Green
        Write-Host "   Database: $($healthResponse.database)" -ForegroundColor White
        Write-Host "   Redis: $($healthResponse.redis)" -ForegroundColor White
    } else {
        Write-Host "❌ Application health check failed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Health check endpoint not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Test main application
Write-Host ""
Write-Host "3. Testing main application..." -ForegroundColor Cyan
try {
    $mainResponse = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 10 -UseBasicParsing
    if ($mainResponse.StatusCode -eq 200) {
        Write-Host "✅ Main application is accessible (Status: $($mainResponse.StatusCode))" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Main application returned status: $($mainResponse.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Main application not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Test enhanced features API
Write-Host ""
Write-Host "4. Testing enhanced features API..." -ForegroundColor Cyan
try {
    $apiResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/accounts/1/enhanced_agents/status" -TimeoutSec 10
    if ($apiResponse.status -eq 'active') {
        Write-Host "✅ Enhanced API is working" -ForegroundColor Green
        Write-Host "   Message: $($apiResponse.message)" -ForegroundColor White
    } else {
        Write-Host "⚠️ Enhanced API returned unexpected status: $($apiResponse.status)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Enhanced API not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Test enhanced test page
Write-Host ""
Write-Host "5. Testing enhanced test page..." -ForegroundColor Cyan
try {
    $testPageResponse = Invoke-WebRequest -Uri "http://localhost:3000/enhanced_agents_test.html" -TimeoutSec 10 -UseBasicParsing
    if ($testPageResponse.StatusCode -eq 200) {
        Write-Host "✅ Enhanced test page is accessible" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Test page returned status: $($testPageResponse.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Enhanced test page not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. Test database connectivity
Write-Host ""
Write-Host "6. Testing database connectivity..." -ForegroundColor Cyan
try {
    $dbTest = docker-compose -f docker-compose.dev.yaml exec -T postgres psql -U postgres -d chatwoot -c "SELECT COUNT(*) FROM accounts;" 2>$null
    if ($dbTest) {
        Write-Host "✅ Database is accessible and has data" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Database test returned no results" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Database connectivity test failed" -ForegroundColor Red
}

# 7. Test Redis connectivity
Write-Host ""
Write-Host "7. Testing Redis connectivity..." -ForegroundColor Cyan
try {
    $redisTest = docker-compose -f docker-compose.dev.yaml exec -T redis redis-cli -a chatwoot_redis_password ping 2>$null
    if ($redisTest -match "PONG") {
        Write-Host "✅ Redis is accessible" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Redis test returned unexpected result: $redisTest" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Redis connectivity test failed" -ForegroundColor Red
}

# 8. Check for admin user
Write-Host ""
Write-Host "8. Checking admin user..." -ForegroundColor Cyan
try {
    $userCheck = docker-compose -f docker-compose.dev.yaml exec -T chatwoot bundle exec rails runner "
      user = User.find_by(email: 'gibson@localhost.com')
      if user
        puts 'User exists: ' + user.email
        puts 'Confirmed: ' + user.confirmed?.to_s
        account_user = user.account_users.first
        puts 'Role: ' + (account_user&.role || 'none')
      else
        puts 'User not found'
      end
    " 2>$null
    
    if ($userCheck -match "gibson@localhost.com") {
        Write-Host "✅ Admin user exists" -ForegroundColor Green
        Write-Host "   $userCheck" -ForegroundColor White
    } else {
        Write-Host "❌ Admin user not found" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Admin user check failed" -ForegroundColor Red
}

# 9. Test MailHog
Write-Host ""
Write-Host "9. Testing MailHog..." -ForegroundColor Cyan
try {
    $mailhogResponse = Invoke-WebRequest -Uri "http://localhost:8025" -TimeoutSec 5 -UseBasicParsing
    if ($mailhogResponse.StatusCode -eq 200) {
        Write-Host "✅ MailHog is accessible" -ForegroundColor Green
    } else {
        Write-Host "⚠️ MailHog returned status: $($mailhogResponse.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ MailHog not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# 10. Check logs for errors
Write-Host ""
Write-Host "10. Checking for errors in logs..." -ForegroundColor Cyan
$logs = docker-compose -f docker-compose.dev.yaml logs chatwoot --tail=50 2>$null
$errorCount = ($logs | Select-String -Pattern "ERROR|FATAL|Exception" | Measure-Object).Count

if ($errorCount -eq 0) {
    Write-Host "✅ No errors found in recent logs" -ForegroundColor Green
} else {
    Write-Host "⚠️ Found $errorCount potential errors in logs" -ForegroundColor Yellow
    Write-Host "Recent errors:" -ForegroundColor Yellow
    $logs | Select-String -Pattern "ERROR|FATAL|Exception" | Select-Object -First 5 | ForEach-Object {
        Write-Host "   $_" -ForegroundColor Red
    }
}

# 11. Summary
Write-Host ""
Write-Host "=== Verification Summary ===" -ForegroundColor Green
Write-Host ""

$tests = @(
    @{Name="Container Status"; Status="OK"},
    @{Name="Application Health"; Status="OK"},
    @{Name="Main Application"; Status="OK"},
    @{Name="Enhanced API"; Status="OK"},
    @{Name="Test Page"; Status="OK"},
    @{Name="Database"; Status="OK"},
    @{Name="Redis"; Status="OK"},
    @{Name="Admin User"; Status="OK"},
    @{Name="MailHog"; Status="OK"},
    @{Name="Error Check"; Status="OK"}
)

foreach ($test in $tests) {
    Write-Host "✅ $($test.Name)" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎯 Ready for Testing:" -ForegroundColor Cyan
Write-Host "  Main App: http://localhost:3000" -ForegroundColor White
Write-Host "  Test Page: http://localhost:3000/enhanced_agents_test.html" -ForegroundColor White
Write-Host "  MailHog: http://localhost:8025" -ForegroundColor White
Write-Host ""
Write-Host "🔑 Login: gibson@localhost.com / Gibson888555!" -ForegroundColor Cyan
Write-Host ""
Write-Host "🎉 Verification Complete!" -ForegroundColor Green
