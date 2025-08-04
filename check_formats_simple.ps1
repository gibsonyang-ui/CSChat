# Check file formats and line endings

Write-Host "=== Checking File Formats and Line Endings ===" -ForegroundColor Green
Write-Host ""

# Files to check
$filesToCheck = @(
    "app/controllers/api/v1/accounts/enhanced_agents_controller.rb",
    "app/controllers/health_controller.rb",
    "app/javascript/dashboard/routes/dashboard/settings/agents/Index.vue",
    "config/routes.rb",
    "config/initializers/geocoder.rb",
    "public/enhanced_agents_test.html",
    "docker-compose.clean.yaml",
    ".env"
)

function Check-FileFormat($filePath) {
    if (Test-Path $filePath) {
        $content = Get-Content -Path $filePath -Raw
        $totalLength = $content.Length
        $crlfCount = ($content -split "`r`n").Count - 1
        $lfCount = ($content -split "`n").Count - 1
        
        Write-Host "File: $filePath" -ForegroundColor Cyan
        Write-Host "  Size: $totalLength characters" -ForegroundColor White
        Write-Host "  CRLF (Windows): $crlfCount" -ForegroundColor White
        Write-Host "  LF (Unix): $($lfCount - $crlfCount)" -ForegroundColor White
        
        # Determine file format
        if ($crlfCount -gt 0) {
            Write-Host "  Format: Windows (CRLF)" -ForegroundColor Yellow
            $needsConversion = $true
        } elseif ($lfCount -gt 0) {
            Write-Host "  Format: Unix (LF) - OK" -ForegroundColor Green
            $needsConversion = $false
        } else {
            Write-Host "  Format: Unknown or empty" -ForegroundColor Gray
            $needsConversion = $false
        }
        
        Write-Host ""
        return $needsConversion
    } else {
        Write-Host "File not found: $filePath" -ForegroundColor Red
        Write-Host ""
        return $false
    }
}

# Check all files
$needsConversion = @()
foreach ($file in $filesToCheck) {
    if (Check-FileFormat $file) {
        $needsConversion += $file
    }
}

# Summary
Write-Host "=== Summary ===" -ForegroundColor Green
Write-Host ""

if ($needsConversion.Count -eq 0) {
    Write-Host "All files use correct Unix format (LF)" -ForegroundColor Green
} else {
    Write-Host "Files that need conversion to Unix format:" -ForegroundColor Yellow
    foreach ($file in $needsConversion) {
        Write-Host "  - $file" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "PowerShell conversion method:" -ForegroundColor Cyan
    foreach ($file in $needsConversion) {
        Write-Host "  (Get-Content `"$file`" -Raw) -replace `"`r`n`", `"`n`" | Set-Content `"$file`" -NoNewline" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== Application Status Check ===" -ForegroundColor Green
Write-Host ""

# Check application status
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5 -UseBasicParsing
    Write-Host "Main application accessible (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "Main application not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# Check test page
try {
    $testResponse = Invoke-WebRequest -Uri "http://localhost:3000/enhanced_agents_test.html" -TimeoutSec 5 -UseBasicParsing
    Write-Host "Test page accessible (Status: $($testResponse.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "Test page not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# Check container status
Write-Host ""
Write-Host "Container Status:" -ForegroundColor Cyan
docker-compose -f docker-compose.clean.yaml ps

Write-Host ""
Write-Host "Login Information:" -ForegroundColor Cyan
Write-Host "  URL: http://localhost:3000" -ForegroundColor White
Write-Host "  Email: gibson@localhost.com" -ForegroundColor White
Write-Host "  Password: Gibson888555!" -ForegroundColor White
Write-Host ""
Write-Host "Check completed!" -ForegroundColor Green
