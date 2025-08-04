# Quick verification of deployment

Write-Host "=== Quick Deployment Verification ===" -ForegroundColor Green
Write-Host ""

# 1. Check containers
Write-Host "1. Checking containers..." -ForegroundColor Cyan
docker-compose -f docker-compose.stable.yaml ps

# 2. Test main application
Write-Host ""
Write-Host "2. Testing main application..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 10 -UseBasicParsing
    Write-Host "✅ Main application: Status $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "❌ Main application: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Test health endpoint
Write-Host ""
Write-Host "3. Testing health endpoint..." -ForegroundColor Cyan
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:3000/health" -TimeoutSec 10
    Write-Host "✅ Health check: $($healthResponse.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ Health check: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Test enhanced API
Write-Host ""
Write-Host "4. Testing enhanced API..." -ForegroundColor Cyan
try {
    $apiResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/accounts/1/enhanced_agents/status" -TimeoutSec 10
    Write-Host "✅ Enhanced API: $($apiResponse.message)" -ForegroundColor Green
} catch {
    Write-Host "❌ Enhanced API: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Test test page
Write-Host ""
Write-Host "5. Testing enhanced test page..." -ForegroundColor Cyan
try {
    $testResponse = Invoke-WebRequest -Uri "http://localhost:3000/enhanced_agents_test.html" -TimeoutSec 10 -UseBasicParsing
    Write-Host "✅ Test page: Status $($testResponse.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "❌ Test page: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. Check admin user
Write-Host ""
Write-Host "6. Checking admin user..." -ForegroundColor Cyan
try {
    $userCheck = docker-compose -f docker-compose.stable.yaml exec -T chatwoot bundle exec rails runner "
      user = User.find_by(email: 'gibson@localhost.com')
      puts user ? 'User exists' : 'User not found'
    " 2>$null
    
    if ($userCheck -match "User exists") {
        Write-Host "✅ Admin user exists" -ForegroundColor Green
    } else {
        Write-Host "❌ Admin user not found" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Admin user check failed" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Verification Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 Access URLs:" -ForegroundColor Cyan
Write-Host "  Main App: http://localhost:3000" -ForegroundColor White
Write-Host "  Test Page: http://localhost:3000/enhanced_agents_test.html" -ForegroundColor White
Write-Host "  MailHog: http://localhost:8025" -ForegroundColor White
Write-Host ""
Write-Host "🔑 Login: gibson@localhost.com / Gibson888555!" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 If login fails, wait a few more minutes for full startup" -ForegroundColor Yellow
