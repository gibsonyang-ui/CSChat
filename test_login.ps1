# Test login functionality

Write-Host "=== Testing Login Functionality ===" -ForegroundColor Green
Write-Host ""

# Test basic connectivity
Write-Host "1. Testing basic connectivity..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 10 -UseBasicParsing
    Write-Host "   Main application accessible (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "   Main application not accessible: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test login page
Write-Host ""
Write-Host "2. Testing login page..." -ForegroundColor Cyan
try {
    $loginResponse = Invoke-WebRequest -Uri "http://localhost:3000/app/login" -TimeoutSec 10 -UseBasicParsing
    Write-Host "   Login page accessible (Status: $($loginResponse.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "   Login page not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# Test API endpoints
Write-Host ""
Write-Host "3. Testing API endpoints..." -ForegroundColor Cyan

# Test health endpoint
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:3000/health" -TimeoutSec 10
    Write-Host "   Health endpoint: $($healthResponse.status)" -ForegroundColor Green
    Write-Host "   Database: $($healthResponse.database)" -ForegroundColor White
    Write-Host "   Redis: $($healthResponse.redis)" -ForegroundColor White
} catch {
    Write-Host "   Health endpoint not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# Test enhanced agents API
try {
    $apiResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/accounts/1/enhanced_agents/status" -TimeoutSec 10
    Write-Host "   Enhanced API: $($apiResponse.message)" -ForegroundColor Green
} catch {
    Write-Host "   Enhanced API not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# Check user exists
Write-Host ""
Write-Host "4. Checking admin user..." -ForegroundColor Cyan
try {
    $userCheck = docker-compose -f docker-compose.clean.yaml exec -T chatwoot bundle exec rails runner "
      user = User.find_by(email: 'gibson@localhost.com')
      if user
        puts 'User exists: ' + user.email
        puts 'Confirmed: ' + user.confirmed?.to_s
        account_user = user.account_users.first
        puts 'Role: ' + (account_user&.role || 'none')
        puts 'Account: ' + (account_user&.account&.name || 'none')
      else
        puts 'User not found'
      end
    " 2>$null
    
    if ($userCheck -match "gibson@localhost.com") {
        Write-Host "   Admin user exists and configured" -ForegroundColor Green
        Write-Host "   Details: $userCheck" -ForegroundColor White
    } else {
        Write-Host "   Admin user not found or not configured" -ForegroundColor Red
    }
} catch {
    Write-Host "   Admin user check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test login attempt (simulate)
Write-Host ""
Write-Host "5. Testing login simulation..." -ForegroundColor Cyan
try {
    # Get CSRF token first
    $loginPageResponse = Invoke-WebRequest -Uri "http://localhost:3000/app/login" -SessionVariable session -TimeoutSec 10
    
    if ($loginPageResponse.Content -match 'csrf-token.*?content="([^"]+)"') {
        $csrfToken = $matches[1]
        Write-Host "   CSRF token obtained: $($csrfToken.Substring(0,20))..." -ForegroundColor Green
        
        # Prepare login data
        $loginData = @{
            'user[email]' = 'gibson@localhost.com'
            'user[password]' = 'Gibson888555!'
            'authenticity_token' = $csrfToken
        }
        
        # Attempt login
        $loginAttempt = Invoke-WebRequest -Uri "http://localhost:3000/auth/sign_in" -Method POST -Body $loginData -WebSession $session -TimeoutSec 10
        
        if ($loginAttempt.StatusCode -eq 200 -or $loginAttempt.StatusCode -eq 302) {
            Write-Host "   Login attempt successful (Status: $($loginAttempt.StatusCode))" -ForegroundColor Green
        } else {
            Write-Host "   Login attempt failed (Status: $($loginAttempt.StatusCode))" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   Could not extract CSRF token" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   Login simulation failed: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "   This is normal - manual login testing required" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Green
Write-Host ""
Write-Host "Application Status:" -ForegroundColor Cyan
Write-Host "  URL: http://localhost:3000" -ForegroundColor White
Write-Host "  Login URL: http://localhost:3000/app/login" -ForegroundColor White
Write-Host ""
Write-Host "Login Credentials:" -ForegroundColor Cyan
Write-Host "  Email: gibson@localhost.com" -ForegroundColor White
Write-Host "  Password: Gibson888555!" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Open browser to http://localhost:3000" -ForegroundColor White
Write-Host "  2. Click 'Login' or navigate to /app/login" -ForegroundColor White
Write-Host "  3. Enter the credentials above" -ForegroundColor White
Write-Host "  4. Navigate to Settings > Team > Agents to see enhanced features" -ForegroundColor White
Write-Host ""
Write-Host "Test completed!" -ForegroundColor Green
