# Test if features are visible in the UI

Write-Host "=== Testing Features in Chatwoot UI ===" -ForegroundColor Green
Write-Host ""

# 1. Check if application is accessible
Write-Host "1. Checking application accessibility..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 10 -UseBasicParsing
    Write-Host "   Application accessible: Status $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "   Application not accessible: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Please ensure the application is running first." -ForegroundColor Yellow
    exit 1
}

# 2. Check login page
Write-Host ""
Write-Host "2. Checking login page..." -ForegroundColor Cyan
try {
    $loginResponse = Invoke-WebRequest -Uri "http://localhost:3000/app/login" -TimeoutSec 10 -UseBasicParsing
    Write-Host "   Login page accessible: Status $($loginResponse.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "   Login page not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Check if we can access the dashboard (after login simulation)
Write-Host ""
Write-Host "3. Testing dashboard access..." -ForegroundColor Cyan
try {
    # Try to access dashboard directly (will redirect to login if not authenticated)
    $dashboardResponse = Invoke-WebRequest -Uri "http://localhost:3000/app/accounts/1/dashboard" -TimeoutSec 10 -UseBasicParsing -MaximumRedirection 0 -ErrorAction SilentlyContinue
    
    if ($dashboardResponse.StatusCode -eq 302) {
        Write-Host "   Dashboard requires authentication (redirecting to login) - Normal" -ForegroundColor Green
    } elseif ($dashboardResponse.StatusCode -eq 200) {
        Write-Host "   Dashboard accessible directly - Unexpected" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   Dashboard access test: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 4. Check specific feature endpoints
Write-Host ""
Write-Host "4. Testing feature endpoints..." -ForegroundColor Cyan

$endpoints = @(
    @{Name="Health Check"; URL="http://localhost:3000/health"},
    @{Name="Enhanced Agents API"; URL="http://localhost:3000/api/v1/accounts/1/enhanced_agents/status"},
    @{Name="Test Page"; URL="http://localhost:3000/enhanced_agents_test.html"}
)

foreach ($endpoint in $endpoints) {
    try {
        $endpointResponse = Invoke-WebRequest -Uri $endpoint.URL -TimeoutSec 5 -UseBasicParsing
        Write-Host "   $($endpoint.Name): OK (Status: $($endpointResponse.StatusCode))" -ForegroundColor Green
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 401) {
            Write-Host "   $($endpoint.Name): Requires authentication (401) - Normal for API" -ForegroundColor Yellow
        } elseif ($statusCode -eq 404) {
            Write-Host "   $($endpoint.Name): Not found (404) - Feature may not be mounted" -ForegroundColor Red
        } else {
            Write-Host "   $($endpoint.Name): Error ($statusCode)" -ForegroundColor Red
        }
    }
}

# 5. Check if features are enabled via environment variables
Write-Host ""
Write-Host "5. Checking feature environment variables..." -ForegroundColor Cyan
try {
    $envCheck = docker-compose -f docker-compose.working.yaml exec chatwoot env | Select-String "ENABLE_FEATURE" | Measure-Object
    Write-Host "   Feature flags found: $($envCheck.Count)" -ForegroundColor White
    
    if ($envCheck.Count -gt 0) {
        Write-Host "   Features are configured via environment variables" -ForegroundColor Green
    } else {
        Write-Host "   No feature flags found in environment" -ForegroundColor Red
    }
} catch {
    Write-Host "   Could not check environment variables: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. Check container status
Write-Host ""
Write-Host "6. Container status check..." -ForegroundColor Cyan
$containers = docker-compose -f docker-compose.working.yaml ps --format json | ConvertFrom-Json
foreach ($container in $containers) {
    $status = if ($container.State -eq "running") { "✅ Running" } else { "❌ $($container.State)" }
    $color = if ($container.State -eq "running") { "Green" } else { "Red" }
    Write-Host "   $($container.Service): $status" -ForegroundColor $color
}

Write-Host ""
Write-Host "=== Feature Testing Instructions ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "To test if features are visible in the UI:" -ForegroundColor Cyan
Write-Host "1. Open browser to: http://localhost:3000" -ForegroundColor White
Write-Host "2. Login with: gibson@localhost.com / Gibson888555!" -ForegroundColor White
Write-Host "3. Navigate to: Settings > Team > Agents" -ForegroundColor White
Write-Host "4. Look for enhanced buttons:" -ForegroundColor White
Write-Host "   - Authentication toggle buttons (✅/❌)" -ForegroundColor Gray
Write-Host "   - Password reset buttons (🔑)" -ForegroundColor Gray
Write-Host "5. Check other menus for new features:" -ForegroundColor White
Write-Host "   - Reports menu" -ForegroundColor Gray
Write-Host "   - Campaigns menu" -ForegroundColor Gray
Write-Host "   - Integrations menu" -ForegroundColor Gray
Write-Host "   - Help Center menu" -ForegroundColor Gray
Write-Host ""
Write-Host "If features are not visible:" -ForegroundColor Yellow
Write-Host "- Check if all containers are running" -ForegroundColor Gray
Write-Host "- Verify environment variables are set" -ForegroundColor Gray
Write-Host "- Check browser console for JavaScript errors" -ForegroundColor Gray
Write-Host "- Try refreshing the page or clearing browser cache" -ForegroundColor Gray
Write-Host ""
Write-Host "Test completed!" -ForegroundColor Green
